import { Application, Graphics } from 'pixi.js';

type PointerLike = { x: number; y: number };

type NodePayload = {
  id: string;
  x: number;
  y: number;
  size?: number;
  label?: string | null;
  color?: string | null;
};

type EdgePayload = {
  key?: string;
  source: string;
  target: string;
  size?: number;
  color?: string | null;
};

type GraphPayload = {
  nodes?: NodePayload[];
  edges?: EdgePayload[];
  config?: {
    background?: string;
    labelDensity?: number;
  };
};

type RuntimeContext = {
  root: HTMLElement;
  stage: HTMLElement;
  status: HTMLElement;
  payload: GraphPayload;
  renderToken: number;
};

type ProjectedNode = {
  id: string;
  x: number;
  y: number;
  radius: number;
  data: NodePayload;
};

type RuntimeCore = {
  clearSelection(root: HTMLElement): void;
  failRender(context: RuntimeContext, title: string, error: unknown): null;
  finalizeRender(context: RuntimeContext, api: RuntimeApi): RuntimeApi | null;
  hoverNode(root: HTMLElement, nodeId: string, pointer: PointerLike): void;
  interactionEnabled(root: HTMLElement, key: string, fallback: boolean): boolean;
  isContextStale(context: RuntimeContext): boolean;
  leaveNode(root: HTMLElement, nodeId: string | null): void;
  nodeNeighbors(root: HTMLElement, nodeId: string): string[];
  prepareRoot(rootId: string, loadingText: string): RuntimeContext | null;
  renderOfflineFallback(context: RuntimeContext, reason: string, error?: unknown): RuntimeApi | null;
  toggleSelection(root: HTMLElement, nodeId: string, pointer: PointerLike): void;
  updateControls(root: HTMLElement): void;
};

type RuntimeApi = {
  destroy(root: HTMLElement): void;
  fitView(root: HTMLElement): Promise<null> | null;
  hasContent(root: HTMLElement): boolean;
  isReady(root: HTMLElement): boolean;
  reactivate(root: HTMLElement): Promise<unknown> | unknown;
  updateHighlight(root: HTMLElement, nodeId: string | null): void;
};

type DragState = {
  clientX: number;
  clientY: number;
  panX: number;
  panY: number;
  moved: boolean;
};

declare global {
  interface Window {
    LargeGraphsRuntimeCore: RuntimeCore;
    LargeGraphsWebGPU?: { render(rootId: string): Promise<unknown> };
  }
}

const core = window.LargeGraphsRuntimeCore;

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function nodeRadius(node: NodePayload): number {
  return clamp((Number(node.size) || 1) * 2.4, 2, 16);
}

function stageSize(stage: HTMLElement): { width: number; height: number } {
  return {
    width: Math.max(1, Math.round(stage.clientWidth || stage.getBoundingClientRect().width || 1)),
    height: Math.max(1, Math.round(stage.clientHeight || stage.getBoundingClientRect().height || 1)),
  };
}

function baseBounds(nodes: NodePayload[]) {
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

function pointerPosition(canvas: HTMLCanvasElement, event: PointerEvent | WheelEvent | MouseEvent): PointerLike {
  const bounds = canvas.getBoundingClientRect();
  return {
    x: event.clientX - bounds.left,
    y: event.clientY - bounds.top,
  };
}

function colorForNode(node: NodePayload, selectedNode: string | null, selectedNeighbors: Set<string>, highlightNeighbors: boolean): { color: string; alpha: number } {
  const id = String(node.id);
  if (!selectedNode || !highlightNeighbors) {
    return { color: node.color || '#2563eb', alpha: 1 };
  }
  if (id === selectedNode) {
    return { color: node.color || '#2563eb', alpha: 1 };
  }
  if (selectedNeighbors.has(id)) {
    return { color: node.color || '#2563eb', alpha: 0.92 };
  }
  return { color: 'rgba(148,163,184,0.24)', alpha: 0.72 };
}

function shouldDrawEdge(edge: EdgePayload, selectedNode: string | null, highlightNeighbors: boolean): boolean {
  if (!selectedNode || !highlightNeighbors) {
    return true;
  }
  return String(edge.source) === selectedNode || String(edge.target) === selectedNode;
}

function edgeStyle(edge: EdgePayload, selectedNode: string | null, highlightNeighbors: boolean) {
  if (!selectedNode || !highlightNeighbors) {
    return {
      color: edge.color || '#94a3b8',
      alpha: 0.7,
      width: clamp(Number(edge.size) || 1, 0.5, 6),
    };
  }
  const incident = String(edge.source) === selectedNode || String(edge.target) === selectedNode;
  return incident
    ? {
        color: edge.color || '#94a3b8',
        alpha: 0.9,
        width: Math.max(1.2, Number(edge.size) || 1),
      }
    : {
        color: 'rgba(148,163,184,0.16)',
        alpha: 0.2,
        width: clamp(Number(edge.size) || 1, 0.5, 6),
      };
}

function createLabelLayer(stage: HTMLElement): HTMLDivElement {
  const layer = document.createElement('div');
  layer.style.cssText = 'position:absolute;inset:0;pointer-events:none;overflow:hidden;z-index:2;';
  stage.appendChild(layer);
  return layer;
}

function createLabelNodes(nodes: NodePayload[], hoveredNode: string | null, selectedNode: string | null, selectedNeighbors: Set<string>, labelDensity: number): Set<string> {
  const ids = new Set<string>();
  if (hoveredNode) {
    ids.add(String(hoveredNode));
  }
  if (selectedNode) {
    ids.add(String(selectedNode));
    for (const neighbor of selectedNeighbors) {
      ids.add(String(neighbor));
    }
  }

  if (labelDensity <= 0) {
    return ids;
  }

  const budget = clamp(Math.round(12 + labelDensity * 48), 0, 96);
  const ranked = nodes
    .filter((node) => Boolean(node.label))
    .slice()
    .sort((left, right) => (Number(right.size) || 1) - (Number(left.size) || 1));

  for (const node of ranked.slice(0, budget)) {
    ids.add(String(node.id));
  }

  return ids;
}

async function render(rootId: string): Promise<unknown> {
  const prepared = core.prepareRoot(rootId, 'Loading WebGPU renderer…');
  if (!prepared) {
    return null;
  }
  const context: RuntimeContext = prepared;

  try {
    const app = new Application();
    const { width, height } = stageSize(context.stage);

    await app.init({
      width,
      height,
      antialias: true,
      autoStart: false,
      backgroundAlpha: 0,
      preference: 'webgpu',
      powerPreference: 'high-performance',
    });

    if (core.isContextStale(context)) {
      app.destroy({ removeView: true }, true);
      return null;
    }

    const canvas = app.canvas as HTMLCanvasElement;
    canvas.style.width = '100%';
    canvas.style.height = '100%';
    canvas.style.display = 'block';
    context.stage.appendChild(canvas);

    const labelsLayer = createLabelLayer(context.stage);
    const edgesGraphics = new Graphics();
    const nodesGraphics = new Graphics();
    app.stage.addChild(edgesGraphics);
    app.stage.addChild(nodesGraphics);

    const nodes = Array.isArray(context.payload.nodes) ? context.payload.nodes : [];
    const edges = Array.isArray(context.payload.edges) ? context.payload.edges : [];
    const nodeMap = new Map<string, NodePayload>();
    for (const node of nodes) {
      nodeMap.set(String(node.id), node);
    }

    const graphBounds = baseBounds(nodes);
    let zoom = 1;
    let panX = 0;
    let panY = 0;
    let dragState: DragState | null = null;
    let projectedNodes: ProjectedNode[] = [];
    let hoveredNode: string | null = null;

    function project(node: NodePayload): ProjectedNode {
      const padding = 36;
      const spanX = graphBounds.maxX - graphBounds.minX;
      const spanY = graphBounds.maxY - graphBounds.minY;
      const sx = (app.renderer.width - 2 * padding) / spanX;
      const sy = (app.renderer.height - 2 * padding) / spanY;
      const scale = Math.min(sx, sy) * zoom;
      const cx = (graphBounds.minX + graphBounds.maxX) / 2;
      const cy = (graphBounds.minY + graphBounds.maxY) / 2;
      return {
        id: String(node.id),
        x: (Number(node.x) - cx) * scale + app.renderer.width / 2 + panX,
        y: (cy - Number(node.y)) * scale + app.renderer.height / 2 + panY,
        radius: nodeRadius(node),
        data: node,
      };
    }

    function renderLabels(currentNodes: ProjectedNode[], highlightNeighbors: boolean) {
      labelsLayer.innerHTML = '';
      const selectedNode = (context.root as HTMLElement & { __largeGraphsJlSelectedNode?: string | null }).__largeGraphsJlSelectedNode ?? null;
      const selectedNeighbors = ((context.root as HTMLElement & { __largeGraphsJlSelectedNeighbors?: Set<string> }).__largeGraphsJlSelectedNeighbors ?? new Set<string>());
      const labelIds = createLabelNodes(nodes, hoveredNode, selectedNode, selectedNeighbors, Number(context.payload.config?.labelDensity) || 0);

      for (const item of currentNodes) {
        if (!item.data.label || !labelIds.has(item.id)) {
          continue;
        }
        if (selectedNode && highlightNeighbors && item.id !== selectedNode && !selectedNeighbors.has(item.id) && item.id !== hoveredNode) {
          continue;
        }

        const label = document.createElement('div');
        label.textContent = String(item.data.label);
        label.style.cssText = `position:absolute;left:${item.x + item.radius + 4}px;top:${item.y - 9}px;font:500 12px/1.2 ui-sans-serif,-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;color:#0f172a;white-space:nowrap;text-shadow:0 1px 0 rgba(255,255,255,0.7);`;
        labelsLayer.appendChild(label);
      }
    }

    function draw() {
      edgesGraphics.clear();
      nodesGraphics.clear();
      projectedNodes = nodes.map(project);
      const projectedMap = new Map<string, ProjectedNode>();
      for (const item of projectedNodes) {
        projectedMap.set(item.id, item);
      }

      const selectedNode = (context.root as HTMLElement & { __largeGraphsJlSelectedNode?: string | null }).__largeGraphsJlSelectedNode ?? null;
      const selectedNeighbors = ((context.root as HTMLElement & { __largeGraphsJlSelectedNeighbors?: Set<string> }).__largeGraphsJlSelectedNeighbors ?? new Set<string>());
      const highlightNeighbors = core.interactionEnabled(context.root, 'highlightNeighbors', true);

      for (const edge of edges) {
        if (!shouldDrawEdge(edge, selectedNode, highlightNeighbors)) {
          continue;
        }
        const source = projectedMap.get(String(edge.source));
        const target = projectedMap.get(String(edge.target));
        if (!source || !target) {
          continue;
        }
        const style = edgeStyle(edge, selectedNode, highlightNeighbors);
        edgesGraphics
          .moveTo(source.x, source.y)
          .lineTo(target.x, target.y)
          .stroke({ width: style.width, color: style.color, alpha: style.alpha });
      }

      for (const item of projectedNodes) {
        const style = colorForNode(item.data, selectedNode, selectedNeighbors, highlightNeighbors);
        nodesGraphics
          .circle(item.x, item.y, item.radius)
          .fill({ color: style.color, alpha: style.alpha });
      }

      renderLabels(projectedNodes, highlightNeighbors);
      app.render();
    }

    function hitTest(point: PointerLike): ProjectedNode | null {
      for (let index = projectedNodes.length - 1; index >= 0; index -= 1) {
        const item = projectedNodes[index];
        const dx = item.x - point.x;
        const dy = item.y - point.y;
        if (dx * dx + dy * dy <= item.radius * item.radius) {
          return item;
        }
      }
      return null;
    }

    function resize() {
      const next = stageSize(context.stage);
      if (next.width === app.renderer.width && next.height === app.renderer.height) {
        return;
      }
      app.renderer.resize(next.width, next.height);
      draw();
    }

    function onWheel(event: WheelEvent) {
      if ((context.root as HTMLElement & { __largeGraphsJlCameraLocked?: boolean }).__largeGraphsJlCameraLocked) {
        return;
      }
      event.preventDefault();
      const direction = event.deltaY > 0 ? -1 : 1;
      zoom = clamp(zoom * (1 + direction * 0.08), 0.25, 8);
      draw();
    }

    function onPointerDown(event: PointerEvent) {
      if ((context.root as HTMLElement & { __largeGraphsJlCameraLocked?: boolean }).__largeGraphsJlCameraLocked) {
        return;
      }
      dragState = {
        clientX: event.clientX,
        clientY: event.clientY,
        panX,
        panY,
        moved: false,
      };
      canvas.setPointerCapture(event.pointerId);
    }

    function onPointerMove(event: PointerEvent) {
      const pointer = pointerPosition(canvas, event);
      if (dragState) {
        const dx = event.clientX - dragState.clientX;
        const dy = event.clientY - dragState.clientY;
        if (Math.abs(dx) > 2 || Math.abs(dy) > 2) {
          dragState.moved = true;
        }
        panX = dragState.panX + dx;
        panY = dragState.panY + dy;
        draw();
        return;
      }

      const hit = hitTest(pointer);
      const nextHover = hit ? hit.id : null;
      if (nextHover === hoveredNode) {
        if (nextHover) {
          core.hoverNode(context.root, nextHover, pointer);
        }
        return;
      }

      if (hoveredNode) {
        core.leaveNode(context.root, hoveredNode);
      }
      hoveredNode = nextHover;
      if (nextHover) {
        core.hoverNode(context.root, nextHover, pointer);
      }
      draw();
    }

    function onPointerUp(event: PointerEvent) {
      if (!dragState) {
        return;
      }
      const pointer = pointerPosition(canvas, event);
      const wasDrag = dragState.moved;
      dragState = null;
      const hit = hitTest(pointer);

      if (wasDrag) {
        return;
      }
      if (hit) {
        core.toggleSelection(context.root, hit.id, pointer);
      } else {
        core.clearSelection(context.root);
      }
      draw();
    }

    function onPointerLeave() {
      if (hoveredNode) {
        core.leaveNode(context.root, hoveredNode);
        hoveredNode = null;
      }
      dragState = null;
      draw();
    }

    canvas.addEventListener('wheel', onWheel, { passive: false });
    canvas.addEventListener('pointerdown', onPointerDown);
    canvas.addEventListener('pointermove', onPointerMove);
    canvas.addEventListener('pointerup', onPointerUp);
    canvas.addEventListener('pointerleave', onPointerLeave);

    const resizeObserver = typeof ResizeObserver === 'undefined' ? null : new ResizeObserver(() => {
      resize();
    });
    resizeObserver?.observe(context.stage);

    context.status.remove();
    draw();

    core.finalizeRender(context, {
      destroy(root) {
        resizeObserver?.disconnect();
        canvas.removeEventListener('wheel', onWheel);
        canvas.removeEventListener('pointerdown', onPointerDown);
        canvas.removeEventListener('pointermove', onPointerMove);
        canvas.removeEventListener('pointerup', onPointerUp);
        canvas.removeEventListener('pointerleave', onPointerLeave);
        labelsLayer.remove();
        app.destroy({ removeView: true }, true);
        (root as HTMLElement & { __largeGraphsJlPixi?: Application | null }).__largeGraphsJlPixi = null;
      },
      isReady() {
        return true;
      },
      hasContent() {
        return nodes.length > 0;
      },
      fitView() {
        zoom = 1;
        panX = 0;
        panY = 0;
        draw();
        return Promise.resolve(null);
      },
      updateHighlight() {
        draw();
      },
      reactivate() {
        return render(rootId);
      },
    });

    (context.root as HTMLElement & { __largeGraphsJlPixi?: Application | null }).__largeGraphsJlPixi = app;
    return app;
  } catch (error) {
    return core.renderOfflineFallback(context, 'WebGPU runtime unavailable, showing offline fallback.', error);
  }
}

window.LargeGraphsWebGPU = { render };
