(function () {
  if (window.LargeGraphs) {
    return;
  }

  const sigmaUrl = "https://cdn.jsdelivr.net/npm/sigma@3.0.0-beta.24/+esm";
  const graphologyUrl = "https://cdn.jsdelivr.net/npm/graphology@0.25.4/+esm";
  const defaultMaxActiveViews = 4;
  let loader;
  const activeRoots = [];

  function maxActiveViews() {
    const configured = Number(window.LargeGraphsMaxActiveViews);
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

  function ensureControls(root) {
    if (!root) {
      return null;
    }

    if (root.__largeGraphsJlControls) {
      return root.__largeGraphsJlControls;
    }

    root.style.position = "relative";

    const controls = document.createElement("div");
    controls.style.cssText = "position:absolute;top:16px;right:16px;z-index:4;display:flex;align-items:center;gap:10px;pointer-events:none;";

    const fitButton = document.createElement("button");
    fitButton.type = "button";
    fitButton.textContent = "Fit View";
    fitButton.style.cssText = "pointer-events:auto;padding:10px 14px;border:1px solid rgba(148,163,184,0.28);border-radius:999px;background:rgba(255,255,255,0.82);backdrop-filter:blur(18px);box-shadow:0 14px 32px rgba(15,23,42,0.12);font:600 13px/1 ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;color:#0f172a;cursor:pointer;transition:transform 140ms ease, box-shadow 140ms ease, background 140ms ease;";
    fitButton.addEventListener("mouseenter", function () {
      if (!fitButton.disabled) {
        fitButton.style.transform = "translateY(-1px)";
        fitButton.style.boxShadow = "0 18px 36px rgba(15,23,42,0.16)";
        fitButton.style.background = "rgba(255,255,255,0.92)";
      }
    });
    fitButton.addEventListener("mouseleave", function () {
      fitButton.style.transform = "translateY(0)";
      fitButton.style.boxShadow = fitButton.disabled ? "none" : "0 14px 32px rgba(15,23,42,0.12)";
      fitButton.style.background = fitButton.disabled ? "rgba(255,255,255,0.45)" : "rgba(255,255,255,0.82)";
    });
    fitButton.addEventListener("click", function () {
      void fitView(root);
    });

    controls.appendChild(fitButton);
    root.appendChild(controls);

    root.__largeGraphsJlControls = controls;
    root.__largeGraphsJlFitButton = fitButton;
    updateControls(root);
    return controls;
  }

  function updateControls(root) {
    const controls = root && root.__largeGraphsJlControls;
    const fitButton = root && root.__largeGraphsJlFitButton;
    if (!controls || !fitButton) {
      return;
    }

    const sigma = root.__largeGraphsJlSigma;
    const graph = sigma && sigma.getGraph ? sigma.getGraph() : null;
    const enabled = Boolean(sigma && graph && graph.order > 0 && !root.__largeGraphsJlPaused);
    controls.style.display = root.__largeGraphsJlPaused ? "none" : "flex";
    fitButton.disabled = !enabled;
    fitButton.style.cursor = enabled ? "pointer" : "default";
    fitButton.style.opacity = enabled ? "1" : "0.7";
    fitButton.style.boxShadow = enabled ? "0 14px 32px rgba(15,23,42,0.12)" : "none";
    fitButton.style.background = enabled ? "rgba(255,255,255,0.82)" : "rgba(255,255,255,0.45)";
    fitButton.style.color = enabled ? "#0f172a" : "#64748b";
  }

  async function fitView(root) {
    const sigma = root && root.__largeGraphsJlSigma;
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

  function decodeHtml(raw) {
    return String(raw || "")
      .replaceAll("&quot;", '"')
      .replaceAll("&#39;", "'")
      .replaceAll("&lt;", "<")
      .replaceAll("&gt;", ">")
      .replaceAll("&amp;", "&");
  }

  function parsePayload(root) {
    const payloadNode = root && document.getElementById(root.id + "-payload");
    if (!payloadNode) {
      return null;
    }

    try {
      return JSON.parse(decodeHtml(payloadNode.textContent));
    } catch (_error) {
      return null;
    }
  }

  function drawFallbackPreview(root, stage) {
    const payload = parsePayload(root);
    if (!payload) {
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

    const background = payload.config?.background || stage.style.background || "#ffffff";
    context.fillStyle = background;
    context.fillRect(0, 0, width, height);

    const nodes = Array.isArray(payload.nodes) ? payload.nodes : [];
    const edges = Array.isArray(payload.edges) ? payload.edges : [];
    if (!nodes.length) {
      return frame.toDataURL("image/png");
    }

    let minX = Infinity;
    let maxX = -Infinity;
    let minY = Infinity;
    let maxY = -Infinity;
    const nodeMap = new Map();

    for (const node of nodes) {
      const x = Number(node.x) || 0;
      const y = Number(node.y) || 0;
      nodeMap.set(String(node.id), node);
      minX = Math.min(minX, x);
      maxX = Math.max(maxX, x);
      minY = Math.min(minY, y);
      maxY = Math.max(maxY, y);
    }

    const spanX = Math.max(maxX - minX, 1);
    const spanY = Math.max(maxY - minY, 1);
    const padding = Math.max(24, Math.min(width, height) * 0.08);
    const scale = Math.min((width - padding * 2) / spanX, (height - padding * 2) / spanY);
    const centerX = (minX + maxX) / 2;
    const centerY = (minY + maxY) / 2;

    function project(node) {
      const x = Number(node.x) || 0;
      const y = Number(node.y) || 0;
      return {
        x: width / 2 + (x - centerX) * scale,
        y: height / 2 - (y - centerY) * scale,
      };
    }

    context.lineCap = "round";
    for (const edge of edges) {
      const source = nodeMap.get(String(edge.source));
      const target = nodeMap.get(String(edge.target));
      if (!source || !target) {
        continue;
      }

      const a = project(source);
      const b = project(target);
      context.beginPath();
      context.moveTo(a.x, a.y);
      context.lineTo(b.x, b.y);
      context.strokeStyle = edge.color || "rgba(148, 163, 184, 0.55)";
      context.lineWidth = Math.max(0.75, (Number(edge.size) || 1) * 0.8);
      context.globalAlpha = 0.9;
      context.stroke();
    }

    context.globalAlpha = 1;
    const labeledNodes = [];
    for (const node of nodes) {
      const p = project(node);
      const radius = Math.max(2.5, Math.min(16, (Number(node.size) || 1) * 2.2));
      context.beginPath();
      context.arc(p.x, p.y, radius, 0, Math.PI * 2);
      context.fillStyle = node.color || "#2563eb";
      context.shadowColor = "rgba(15, 23, 42, 0.12)";
      context.shadowBlur = radius * 1.8;
      context.fill();
      if (node.label) {
        labeledNodes.push({ node, p, radius });
      }
    }

    context.shadowBlur = 0;
    context.font = "12px ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";
    context.fillStyle = "#334155";
    context.textBaseline = "middle";
    for (const item of labeledNodes.slice(0, 80)) {
      context.fillText(String(item.node.label), item.p.x + item.radius + 4, item.p.y);
    }

    return frame.toDataURL("image/png");
  }

  function createPreview(root, stage) {
    return drawFallbackPreview(root, stage) || snapshotStage(stage);
  }

  function showPausedPreview(root, message) {
    const stage = root && root.querySelector(".large-graphs-jl-stage");
    if (!stage) {
      return;
    }

    ensureControls(root);
    const preview = root.__largeGraphsJlPreview || createPreview(root, stage);
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
      root.__largeGraphsJlPreview = createPreview(root, stage);
    }

    cleanup(root);
    root.__largeGraphsJlPaused = true;
    showPausedPreview(root, message);
    updateControls(root);
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

    ensureControls(root);
    root.__largeGraphsJlRenderToken = (root.__largeGraphsJlRenderToken || 0) + 1;
    const renderToken = root.__largeGraphsJlRenderToken;
    cleanup(root);
    installCleanup(root);
    root.__largeGraphsJlPaused = false;
    root.__largeGraphsJlPreview = null;
    updateControls(root);

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
      updateControls(root);
      return sigma;
    } catch (error) {
      status.textContent = "Sigma.js failed to load";
      const details = document.createElement("pre");
      details.textContent = String(error);
      details.style.cssText = "position:absolute;left:12px;right:12px;bottom:12px;max-height:40%;overflow:auto;margin:0;padding:12px;background:#fff;border:1px solid #d1d5db;font:12px monospace;color:#991b1b;";
      stage.appendChild(details);
      updateControls(root);
      return null;
    }
  }

  window.LargeGraphs = { render };
})();
