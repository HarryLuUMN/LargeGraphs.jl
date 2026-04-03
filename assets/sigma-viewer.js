(function () {
  if (window.LargeGraphs) {
    return;
  }

  const core = window.LargeGraphsRuntimeCore;
  const sigmaUrl = "https://cdn.jsdelivr.net/npm/sigma@3.0.0-beta.24/+esm";
  const graphologyUrl = "https://cdn.jsdelivr.net/npm/graphology@0.25.4/+esm";
  let loader;

  async function loadModules() {
    if (!loader) {
      loader = Promise.all([import(graphologyUrl), import(sigmaUrl)]).then(([graphologyModule, sigmaModule]) => {
        const graphology = graphologyModule.default || graphologyModule;
        const Sigma = sigmaModule.default || sigmaModule.Sigma || sigmaModule;
        return { graphology, Sigma };
      });
    }
    return loader;
  }

  async function fitView(root, sigma) {
    if (!sigma) {
      return null;
    }

    const graph = sigma.getGraph();
    if (!graph || graph.order === 0) {
      return null;
    }

    sigma.resize();

    const bbox = sigma.getBBox();
    if (!bbox || !Array.isArray(bbox.x) || !Array.isArray(bbox.y)) {
      return null;
    }

    const minX = bbox.x[0];
    const maxX = bbox.x[1];
    const minY = bbox.y[0];
    const maxY = bbox.y[1];
    const spanX = Math.max(Math.abs(maxX - minX), 1.0e-6);
    const spanY = Math.max(Math.abs(maxY - minY), 1.0e-6);
    const padRatio = 0.16;
    const padX = spanX * padRatio;
    const padY = spanY * padRatio;
    const expanded = {
      x: [minX - padX, maxX + padX],
      y: [minY - padY, maxY + padY],
    };

    sigma.setCustomBBox(expanded);
    sigma.scheduleRefresh();

    const camera = sigma.getCamera();
    const current = camera.getState();
    if (Math.abs(current.x - 0.5) < 1.0e-6 && Math.abs(current.y - 0.5) < 1.0e-6 && Math.abs(current.ratio - 1) < 1.0e-6) {
      return null;
    }

    await camera.animate({ x: 0.5, y: 0.5, ratio: 1, angle: current.angle || 0 }, { duration: 420 });
    sigma.scheduleRender();
    return null;
  }

  function updateHighlight(root, sigma, nodeId) {
    if (!sigma) {
      return;
    }

    if (!nodeId || !core.interactionEnabled(root, "highlightNeighbors", true)) {
      sigma.setSetting("nodeReducer", null);
      sigma.setSetting("edgeReducer", null);
      sigma.refresh();
      return;
    }

    const selectedNeighbors = root.__largeGraphsJlSelectedNeighbors;
    sigma.setSetting("nodeReducer", function (id, attrs) {
      const nodeIdString = String(id);
      if (nodeIdString === nodeId) {
        return Object.assign({}, attrs, { highlighted: true, forceLabel: true, zIndex: 1_000 });
      }
      if (selectedNeighbors.has(nodeIdString)) {
        return Object.assign({}, attrs, { highlighted: true, zIndex: 900 });
      }
      return Object.assign({}, attrs, {
        color: core.dimmedNodeColor(attrs),
        label: null,
        zIndex: 1,
      });
    });
    sigma.setSetting("edgeReducer", function (_edgeKey, attrs) {
      const source = String(attrs.source);
      const target = String(attrs.target);
      const isIncident = source === nodeId || target === nodeId;
      return isIncident ? Object.assign({}, attrs, { zIndex: 800, size: Math.max(1.2, Number(attrs.size) || 1) }) : Object.assign({}, attrs, { color: core.dimmedEdgeColor(attrs), hidden: true });
    });
    sigma.refresh();
  }

  function installInteractionHandlers(root, sigma) {
    sigma.on("enterNode", function (event) {
      core.hoverNode(root, event.node, event.event);
    });

    sigma.on("leaveNode", function (event) {
      core.leaveNode(root, event.node);
    });

    sigma.on("clickNode", function (event) {
      core.toggleSelection(root, event.node, event.event);
    });

    sigma.on("clickStage", function () {
      core.clearSelection(root);
    });
  }

  async function render(rootId) {
    const context = core.prepareRoot(rootId, "Loading Sigma.js…");
    if (!context) {
      return null;
    }

    try {
      const { graphology, Sigma } = await loadModules();
      if (core.isContextStale(context)) {
        return null;
      }

      const Graph = graphology.Graph || graphology.default?.Graph;
      const graph = new Graph({ multi: true, allowSelfLoops: true });

      for (const node of context.payload.nodes || []) {
        graph.addNode(node.id, node);
      }

      for (const edge of context.payload.edges || []) {
        const edgeKey = edge.key || `${edge.source}->${edge.target}`;
        const attrs = Object.assign({}, edge);
        delete attrs.key;
        graph.addEdgeWithKey(edgeKey, edge.source, edge.target, attrs);
      }

      context.status.remove();
      const settings = {
        allowInvalidContainer: true,
        hideEdgesOnMove: context.payload.config?.hideEdgesOnMove ?? false,
        labelDensity: context.payload.config?.labelDensity ?? 1,
        labelGridCellSize: context.payload.config?.labelGridCellSize ?? 80,
        maxCameraRatio: (context.payload.config?.cameraRatio ?? 1) * 12,
        minCameraRatio: 0.02,
        renderEdgeLabels: context.payload.config?.renderEdgeLabels ?? false,
        maxNodeSize: context.payload.config?.maxNodeSize ?? 16,
        minNodeSize: context.payload.config?.minNodeSize ?? 2,
      };

      const sigma = new Sigma(graph, context.stage, settings);
      context.root.__largeGraphsJlSigma = sigma;

      installInteractionHandlers(context.root, sigma);

      core.finalizeRender(context, {
        destroy(root) {
          try {
            sigma.kill();
          } catch (_error) {
          }
          root.__largeGraphsJlSigma = null;
        },
        isReady() {
          return true;
        },
        hasContent() {
          return graph.order > 0;
        },
        fitView(root) {
          return fitView(root, sigma);
        },
        updateHighlight(root, nodeId) {
          updateHighlight(root, sigma, nodeId);
        },
        reactivate() {
          return render(rootId);
        },
      });

      return sigma;
    } catch (error) {
      return core.failRender(context, "Sigma.js failed to load", error);
    }
  }

  window.LargeGraphs = { render };
})();
