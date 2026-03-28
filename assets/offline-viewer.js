(function () {
  if (window.LargeGraphsOffline) {
    return;
  }

  function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value));
  }

  function normalizePayload(rawPayload) {
    const payload = rawPayload && typeof rawPayload === "object" ? rawPayload : {};
    const config = payload.config && typeof payload.config === "object" ? payload.config : {};
    return {
      id: payload.id,
      config: {
        background: config.background ?? "#ffffff",
        labelDensity: config.labelDensity ?? 1,
      },
      nodes: (Array.isArray(payload.nodes) ? payload.nodes : []).map(function (node) {
        return Object.assign({ size: 1 }, node);
      }),
      edges: (Array.isArray(payload.edges) ? payload.edges : []).map(function (edge) {
        return Object.assign({ size: 1 }, edge);
      }),
    };
  }

  function parsePayload(root) {
    const payloadNode = root && document.getElementById(root.id + "-payload");
    if (!payloadNode) {
      return null;
    }
    try {
      return normalizePayload(JSON.parse(payloadNode.textContent || "{}"));
    } catch (_error) {
      return null;
    }
  }

  function boundsFromNodes(nodes) {
    let minX = Infinity;
    let maxX = -Infinity;
    let minY = Infinity;
    let maxY = -Infinity;
    for (const node of nodes) {
      const x = Number(node.x) || 0;
      const y = Number(node.y) || 0;
      minX = Math.min(minX, x);
      maxX = Math.max(maxX, x);
      minY = Math.min(minY, y);
      maxY = Math.max(maxY, y);
    }
    if (!Number.isFinite(minX) || !Number.isFinite(maxX) || !Number.isFinite(minY) || !Number.isFinite(maxY)) {
      return { minX: -1, maxX: 1, minY: -1, maxY: 1 };
    }
    if (Math.abs(maxX - minX) < 1.0e-9) {
      minX -= 1;
      maxX += 1;
    }
    if (Math.abs(maxY - minY) < 1.0e-9) {
      minY -= 1;
      maxY += 1;
    }
    return { minX, maxX, minY, maxY };
  }

  function render(rootId) {
    const root = document.getElementById(rootId);
    if (!root) {
      return null;
    }

    const stage = root.querySelector(".large-graphs-jl-stage");
    if (!stage) {
      return null;
    }

    const payload = parsePayload(root);
    if (!payload) {
      stage.textContent = "Unable to parse graph payload";
      return null;
    }

    stage.innerHTML = "";
    stage.style.position = "relative";

    const width = Math.max(1, Math.round(stage.clientWidth || stage.getBoundingClientRect().width || 1));
    const height = Math.max(1, Math.round(stage.clientHeight || stage.getBoundingClientRect().height || 1));
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    canvas.style.width = "100%";
    canvas.style.height = "100%";
    stage.appendChild(canvas);

    const hint = document.createElement("div");
    hint.textContent = "Offline mode";
    hint.style.cssText = "position:absolute;right:12px;bottom:10px;font:600 11px/1.2 ui-sans-serif,-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;color:#334155;background:rgba(255,255,255,0.8);padding:4px 8px;border-radius:999px;border:1px solid rgba(148,163,184,0.35);";
    stage.appendChild(hint);

    const context = canvas.getContext("2d");
    if (!context) {
      return null;
    }

    const nodes = Array.isArray(payload.nodes) ? payload.nodes : [];
    const edges = Array.isArray(payload.edges) ? payload.edges : [];
    const nodeMap = new Map();
    for (const node of nodes) {
      nodeMap.set(String(node.id), node);
    }

    const baseBounds = boundsFromNodes(nodes);
    let zoom = 1;
    let panX = 0;
    let panY = 0;
    let dragStart = null;

    function project(node) {
      const padding = 36;
      const spanX = baseBounds.maxX - baseBounds.minX;
      const spanY = baseBounds.maxY - baseBounds.minY;
      const sx = (width - 2 * padding) / spanX;
      const sy = (height - 2 * padding) / spanY;
      const scale = Math.min(sx, sy) * zoom;
      const cx = (baseBounds.minX + baseBounds.maxX) / 2;
      const cy = (baseBounds.minY + baseBounds.maxY) / 2;
      return {
        x: (Number(node.x) - cx) * scale + width / 2 + panX,
        y: (cy - Number(node.y)) * scale + height / 2 + panY,
      };
    }

    function draw() {
      context.clearRect(0, 0, width, height);
      context.fillStyle = payload.config?.background || "#ffffff";
      context.fillRect(0, 0, width, height);

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
        context.strokeStyle = edge.color || "#94a3b8";
        context.lineWidth = clamp(Number(edge.size) || 1, 0.5, 6);
        context.globalAlpha = 0.7;
        context.stroke();
      }

      context.globalAlpha = 1;
      for (const node of nodes) {
        const p = project(node);
        const radius = clamp((Number(node.size) || 1) * 2.4, 2, 14);
        context.beginPath();
        context.arc(p.x, p.y, radius, 0, 2 * Math.PI);
        context.fillStyle = node.color || "#2563eb";
        context.fill();

        if (payload.config?.labelDensity !== 0 && node.label) {
          context.fillStyle = "#0f172a";
          context.font = "500 12px ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";
          context.textBaseline = "middle";
          context.fillText(String(node.label), p.x + radius + 4, p.y);
        }
      }
    }

    canvas.addEventListener("wheel", function (event) {
      event.preventDefault();
      const direction = event.deltaY > 0 ? -1 : 1;
      const nextZoom = zoom * (1 + direction * 0.08);
      zoom = clamp(nextZoom, 0.25, 8);
      draw();
    }, { passive: false });

    canvas.addEventListener("pointerdown", function (event) {
      dragStart = { x: event.clientX, y: event.clientY, panX, panY };
      canvas.setPointerCapture(event.pointerId);
    });

    canvas.addEventListener("pointermove", function (event) {
      if (!dragStart) {
        return;
      }
      panX = dragStart.panX + (event.clientX - dragStart.x);
      panY = dragStart.panY + (event.clientY - dragStart.y);
      draw();
    });

    canvas.addEventListener("pointerup", function () {
      dragStart = null;
    });

    draw();
    return { redraw: draw };
  }

  window.LargeGraphsOffline = { render };
})();
