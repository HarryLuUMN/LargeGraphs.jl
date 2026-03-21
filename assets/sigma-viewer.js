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
      image.style.cssText = "display:block;width:100%;height:100%;object-fit:contain;filter:saturate(0.96) contrast(1.02);transform:scale(1.01);";
      stage.appendChild(image);
    }

    const veil = document.createElement("div");
    veil.style.cssText = "position:absolute;inset:0;background:linear-gradient(180deg, rgba(248,250,252,0.10) 0%, rgba(248,250,252,0.18) 34%, rgba(255,255,255,0.78) 100%);backdrop-filter:blur(3px);";
    stage.appendChild(veil);

    const panel = document.createElement("div");
    panel.style.cssText = "position:absolute;left:20px;right:20px;bottom:20px;display:flex;align-items:flex-end;justify-content:space-between;gap:16px;padding:16px 18px;border:1px solid rgba(148,163,184,0.28);border-radius:18px;background:rgba(255,255,255,0.82);box-shadow:0 18px 48px rgba(15,23,42,0.14);backdrop-filter:blur(18px);";

    const copy = document.createElement("div");
    copy.style.cssText = "display:flex;flex-direction:column;gap:8px;min-width:0;";

    const badge = document.createElement("div");
    badge.textContent = "Paused Preview";
    badge.style.cssText = "align-self:flex-start;padding:5px 10px;border-radius:999px;background:rgba(15,23,42,0.08);font:600 11px/1.2 ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;letter-spacing:0.08em;text-transform:uppercase;color:#334155;";
    copy.appendChild(badge);

    const title = document.createElement("div");
    title.textContent = "Interactive graph paused";
    title.style.cssText = "font:600 18px/1.2 ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;color:#0f172a;";
    copy.appendChild(title);

    const body = document.createElement("div");
    body.textContent = message || "This graph was parked as a static preview to keep the notebook smooth. Reactivate it whenever you want to explore again.";
    body.style.cssText = "max-width:560px;font:500 13px/1.5 ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;color:#475569;";
    copy.appendChild(body);

    const button = document.createElement("button");
    button.type = "button";
    button.textContent = "Reactivate graph";
    button.style.cssText = "flex:none;padding:11px 16px;border:0;border-radius:999px;background:linear-gradient(135deg, #0f172a 0%, #334155 100%);box-shadow:0 10px 24px rgba(15,23,42,0.22);font:600 13px/1 ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;color:#f8fafc;cursor:pointer;white-space:nowrap;";
    button.addEventListener("click", function () {
      void render(root.id);
    });

    panel.appendChild(copy);
    panel.appendChild(button);
    stage.appendChild(panel);
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
