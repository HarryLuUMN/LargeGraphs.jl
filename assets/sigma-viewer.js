(function () {
  if (window.LargeGraphsJL) {
    return;
  }

  const sigmaUrl = "https://cdn.jsdelivr.net/npm/sigma@3.0.0-beta.24/+esm";
  const graphologyUrl = "https://cdn.jsdelivr.net/npm/graphology@0.25.4/+esm";
  let loader;

  function cleanup(root) {
    if (!root) {
      return;
    }

    if (root.__largeGraphsJlCleanupObserver) {
      root.__largeGraphsJlCleanupObserver.disconnect();
      root.__largeGraphsJlCleanupObserver = null;
    }

    if (root.__largeGraphsJlSigma) {
      try {
        root.__largeGraphsJlSigma.kill();
      } catch (_error) {
      }
      root.__largeGraphsJlSigma = null;
    }
  }

  function installCleanup(root) {
    if (!root || root.__largeGraphsJlCleanupObserver || !document.body || typeof MutationObserver === "undefined") {
      return;
    }

    const observer = new MutationObserver(() => {
      if (!root.isConnected) {
        cleanup(root);
      }
    });
    observer.observe(document.body, { childList: true, subtree: true });
    root.__largeGraphsJlCleanupObserver = observer;
  }

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

  async function render(rootId) {
    const root = document.getElementById(rootId);
    const payloadNode = document.getElementById(rootId + "-payload");
    if (!root || !payloadNode) {
      return null;
    }

    const stage = root.querySelector(".large-graphs-jl-stage");
    if (!stage) {
      return null;
    }

    root.__largeGraphsJlRenderToken = (root.__largeGraphsJlRenderToken || 0) + 1;
    const renderToken = root.__largeGraphsJlRenderToken;
    cleanup(root);
    installCleanup(root);

    stage.innerHTML = "";
    stage.style.position = "relative";

    const status = document.createElement("div");
    status.textContent = "Loading Sigma.js…";
    status.style.cssText = "position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font:14px sans-serif;color:#4b5563;";
    stage.appendChild(status);

    try {
      const payload = JSON.parse(payloadNode.textContent || "{}");
      const { graphology, Sigma } = await loadModules();
      if (!root.isConnected || root.__largeGraphsJlRenderToken !== renderToken) {
        return null;
      }
      const Graph = graphology.Graph || graphology.default?.Graph;
      const graph = new Graph({ multi: true, allowSelfLoops: true });

      for (const node of payload.nodes || []) {
        graph.addNode(node.id, node);
      }

      for (const edge of payload.edges || []) {
        const edgeKey = edge.key || `${edge.source}->${edge.target}`;
        const attrs = Object.assign({}, edge);
        delete attrs.key;
        graph.addEdgeWithKey(edgeKey, edge.source, edge.target, attrs);
      }

      status.remove();
      const settings = {
        allowInvalidContainer: true,
        hideEdgesOnMove: payload.config?.hideEdgesOnMove ?? false,
        labelDensity: payload.config?.labelDensity ?? 1,
        labelGridCellSize: payload.config?.labelGridCellSize ?? 80,
        maxCameraRatio: (payload.config?.cameraRatio ?? 1) * 12,
        minCameraRatio: 0.02,
        renderEdgeLabels: payload.config?.renderEdgeLabels ?? false,
        maxNodeSize: payload.config?.maxNodeSize ?? 16,
        minNodeSize: payload.config?.minNodeSize ?? 2,
      };

      const sigma = new Sigma(graph, stage, settings);
      root.__largeGraphsJlSigma = sigma;
      installCleanup(root);
      return sigma;
    } catch (error) {
      status.textContent = "Sigma.js failed to load";
      const details = document.createElement("pre");
      details.textContent = String(error);
      details.style.cssText = "position:absolute;left:12px;right:12px;bottom:12px;max-height:40%;overflow:auto;margin:0;padding:12px;background:#fff;border:1px solid #d1d5db;font:12px monospace;color:#991b1b;";
      stage.appendChild(details);
      return null;
    }
  }

  window.LargeGraphsJL = { render };
})();
