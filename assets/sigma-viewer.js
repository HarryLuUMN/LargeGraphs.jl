(function () {
  if (window.LargeGraphsJL) {
    return;
  }

  const sigmaUrl = "https://cdn.jsdelivr.net/npm/sigma@3.0.0-beta.24/+esm";
  const graphologyUrl = "https://cdn.jsdelivr.net/npm/graphology@0.25.4/+esm";
  const defaultMaxActiveViews = 4;
  let loader;
  const activeRoots = [];

  function maxActiveViews() {
    const configured = Number(window.LargeGraphsJLMaxActiveViews);
    if (Number.isFinite(configured) && configured >= 1) {
      return Math.floor(configured);
    }
    return defaultMaxActiveViews;
  }

  function removeActiveRoot(root) {
    const index = activeRoots.indexOf(root);
    if (index >= 0) {
      activeRoots.splice(index, 1);
    }
  }

  function rememberActiveRoot(root) {
    removeActiveRoot(root);
    activeRoots.push(root);
  }

  function cleanup(root) {
    if (!root) {
      return;
    }

    removeActiveRoot(root);

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

  function snapshotStage(stage) {
    if (!stage) {
      return null;
    }

    const width = Math.max(1, Math.round(stage.clientWidth || stage.getBoundingClientRect().width || 0));
    const height = Math.max(1, Math.round(stage.clientHeight || stage.getBoundingClientRect().height || 0));
    const frame = document.createElement("canvas");
    frame.width = width;
    frame.height = height;
    const context = frame.getContext("2d");
    if (!context) {
      return null;
    }

    context.fillStyle = stage.style.background || "#ffffff";
    context.fillRect(0, 0, width, height);

    for (const layer of stage.querySelectorAll("canvas")) {
      if (layer.width === 0 || layer.height === 0) {
        continue;
      }
      context.drawImage(layer, 0, 0, width, height);
    }

    return frame.toDataURL("image/png");
  }

  function showPausedPreview(root, message) {
    const stage = root && root.querySelector(".large-graphs-jl-stage");
    if (!stage) {
      return;
    }

    const preview = root.__largeGraphsJlPreview || snapshotStage(stage);
    stage.innerHTML = "";
    stage.style.position = "relative";

    if (preview) {
      const image = document.createElement("img");
      image.src = preview;
      image.alt = "Paused graph preview";
      image.style.cssText = "display:block;width:100%;height:100%;object-fit:contain;";
      stage.appendChild(image);
    }

    const button = document.createElement("button");
    button.type = "button";
    button.textContent = message || "Graph paused to stay under browser WebGL limits. Click to reactivate.";
    button.style.cssText = "position:absolute;left:12px;right:12px;bottom:12px;padding:10px 12px;border:1px solid #d1d5db;border-radius:8px;background:rgba(255,255,255,0.92);font:13px sans-serif;color:#111827;text-align:left;cursor:pointer;";
    button.addEventListener("click", function () {
      void render(root.id);
    });
    stage.appendChild(button);
  }

  function pauseRoot(root, message) {
    if (!root) {
      return;
    }

    const stage = root.querySelector(".large-graphs-jl-stage");
    if (stage) {
      root.__largeGraphsJlPreview = snapshotStage(stage);
    }

    cleanup(root);
    root.__largeGraphsJlPaused = true;
    showPausedPreview(root, message);
  }

  function enforceActiveLimit(currentRoot) {
    const limit = maxActiveViews();
    while (activeRoots.length > limit) {
      const root = activeRoots[0];
      if (!root || root === currentRoot) {
        break;
      }
      pauseRoot(root, "Graph paused to keep the notebook responsive. Click to reactivate.");
    }
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
    root.__largeGraphsJlPaused = false;
    root.__largeGraphsJlPreview = null;

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
      rememberActiveRoot(root);
      enforceActiveLimit(root);
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
