# LargeGraphs

`LargeGraphs` is a small Julia package for rendering interactive graph
visualizations with [Sigma.js](https://www.sigmajs.org/) in IJulia and Jupyter
notebooks. It accepts plain Julia collections, includes a lightweight batch of
classic layout algorithms, accepts `Graphs.jl` graph objects, produces
notebook-friendly HTML, and can export standalone HTML files for sharing
outside Julia.

## Why this package

- Targets notebook workflows where fast visual inspection matters.
- Accepts lightweight Julia data structures instead of requiring a graph type.
- Also works directly with `Graphs.jl` when a project already uses the Julia graph ecosystem.
- Keeps the package surface small enough to understand quickly.
- Supports standalone HTML export for demos and reports.

## Installation

### Add from a local checkout

```julia
using Pkg
Pkg.develop(path=".")
Pkg.instantiate()
```

### Add from a Git repository

```julia
using Pkg
Pkg.add(url="git@github.com:HarryLuUMN/LargeGraphs.jl.git")
```

### Notebook prerequisite

Install `IJulia` in the Julia environment that backs your notebook kernel:

```julia
using Pkg
Pkg.add("IJulia")
```

If the package is installed in one environment and the notebook kernel points
at another, `using LargeGraphs` will fail inside the notebook even if it works
from the terminal.

## Primary workflows

Use the staged pipeline as the default workflow, then choose one-shot rendering
or direct `Graphs.jl` input when that better matches your notebook.

| Workflow | Best for | Core calls |
| --- | --- | --- |
| Staged pipeline (recommended) | Reusing one layout across multiple renders/exports | `layout_graph` -> `assemble_graph` |
| One-shot convenience | Fast iteration in a single call | `render` |
| `Graphs.jl` input | Existing `Graphs.jl` projects | `render(g; node_mapper=..., edge_mapper=...)` |

### Staged pipeline (recommended)

```julia
using LargeGraphs

layouted = layout_graph(
    nodes,
    edges;
    layout=:force_directed,
    algorithm=:forceatlas2,
    iterations=60,
    seed=7,
)

viz = assemble_graph(
    layouted;
    config=SigmaConfig(height="520px", background="#f8fafc"),
)

display(viz)
savehtml("graph.html", viz)
```

### One-shot convenience

```julia
using LargeGraphs

nodes = [
    (id="a", size=3.0, label="A", color="#2563eb"),
    (id="b", size=2.5, label="B", color="#059669"),
    (id="c", size=2.0, label="C", color="#d97706"),
]

edges = [
    (source="a", target="b", size=0.8, color="#94a3b8"),
    (source="a", target="c", size=0.8, color="#cbd5e1"),
]

viz = render(
    nodes,
    edges;
    layout=:force_directed,
    algorithm=:fruchterman_reingold,
    iterations=120,
    seed=7,
    height="520px",
    background="#f8fafc",
    hide_edges_on_move=true,
    max_node_size=12.0,
)

display(viz)
savehtml("graph.html", viz)
```

### Graphs.jl input

```julia
using Graphs
using LargeGraphs

g = path_graph(6)

viz = render(
    g;
    layout=:circular,
    node_mapper=v -> (id="v$v", label="Node $v", size=1.5),
    edge_mapper=e -> (source="v$(src(e))", target="v$(dst(e))", color="#94a3b8"),
)
```

## Notebook Usage

`SigmaGraph` implements HTML display, so a notebook cell only needs to evaluate
or `display` the value returned by `render(...)` or `graph(...)`.

The repository includes:

- `examples/demo_staged_pipeline.ipynb` for the recommended staged workflow.
- `examples/demo_notebook.ipynb` for an IJulia notebook workflow.
- `examples/demo_layout_functions.ipynb` for direct layout function demos.
- `examples/demo_graphsjl.ipynb` for direct `Graphs.jl` rendering.
- `examples/demo_interactions.ipynb` for click/hover interaction and Julia-side state updates.
- `examples/demo_large_graph.jl` for script-based standalone export.

Typical notebook setup:

```julia
using Pkg
Pkg.activate(isdir(joinpath(pwd(), "src")) ? pwd() : joinpath(pwd(), ".."))
Pkg.instantiate()

using LargeGraphs
```

When a graph does not render in Jupyter, open the browser console first. The
viewer loads Sigma.js and Graphology as browser ESM modules, so frontend errors
usually show up there immediately.

## Benchmarks

A first rendering benchmark scaffold that compares `LargeGraphs` and `GraphMakie`
is available under `benchmarks/`.

Run a quick smoke benchmark from the repository root:

```bash
julia --project=benchmarks benchmarks/scripts/run_smoke.jl
```

## API Overview

### Constructors

- `NodeSpec(id; x, y, size, label, color, attributes)`
- `EdgeSpec(source, target; id, size, label, color, attributes)`
- `SigmaConfig(; width, height, background, camera_ratio, render_edge_labels, hide_edges_on_move, label_density, label_grid_cell_size, max_node_size, min_node_size)`

### Main functions

- `graph(nodes, edges; id, config, layout=nothing, layout_kwargs...)` normalizes graph data into a `SigmaGraph`.
- `graph(g::Graphs.AbstractGraph; id, config, layout=nothing, node_mapper, edge_mapper, layout_kwargs...)` normalizes a `Graphs.jl` graph into a `SigmaGraph`.
- `layout_graph(nodes, edges; layout=nothing, layout_kwargs...)` runs the layout stage and returns positioned nodes with normalized edges.
- `assemble_graph(layouted_or_nodes, edges=nothing; id, config, interaction_state, ...)` builds a `SigmaGraph` from already-positioned graph data.
- `render(nodes, edges; layout=nothing, kwargs..., layout_kwargs...)` builds a `SigmaGraph` with inline render options.
- `render(g::Graphs.AbstractGraph; layout=nothing, node_mapper, edge_mapper, kwargs..., layout_kwargs...)` renders a `Graphs.jl` graph directly.
- `InteractionState()` records click and hover events back into Julia when the graph is displayed in IJulia.
- `savehtml(path, graph)` writes a standalone HTML file.
- `savehtml(path, nodes, edges; kwargs...)` combines rendering and export in one call.
- `random_layout(nodes; seed, extent)` assigns random coordinates.
- `circular_layout(nodes; radius, start_angle)` places nodes on a circle.
- `grid_layout(nodes; columns, spacing)` places nodes on a centered grid.
- `orthogonal_layout(nodes, edges; extent, layer_spacing, component_spacing)` places nodes on a grid with alternating orthogonal levels.
- `spectral_layout(nodes, edges; extent, seed)` computes a spectral embedding from the graph Laplacian.
- `tree_layout(nodes, edges; algorithm=:layered, kwargs...)` runs tree-oriented layouts with `:layered` and `:radial`.
- `force_directed_layout(nodes, edges; algorithm=:fruchterman_reingold, kwargs...)` runs a force-directed family with `:fruchterman_reingold`, `:kamada_kawai`, or `:forceatlas2`.
- `spring_layout(nodes, edges; iterations, seed, extent, gravity, cooling)` remains as a compatibility alias for Fruchterman-Reingold.

### Layout usage

You can call a layout function directly when you want explicit positioned nodes:

```julia
positioned_nodes = circular_layout(nodes; radius=2.5)
viz = render(positioned_nodes, edges; height="520px")
```

Or you can let `render` apply the layout for you:

```julia
viz = render(nodes, edges; layout=:force_directed, algorithm=:kamada_kawai, iterations=120, seed=3)
```

Tree-shaped data can use a tree-specific layout:

```julia
viz = render(nodes, edges; layout=:tree, algorithm=:layered, root="a", extent=2.0)
```

When you want to split layout from rendering, use the staged pipeline directly:

```julia
layouted = layout_graph(nodes, edges; layout=:force_directed, algorithm=:forceatlas2, iterations=60, seed=7)
viz = assemble_graph(layouted; config=SigmaConfig(height="520px"))
savehtml("graph.html", viz)
```

`layout` accepts:

- symbols: `:random`, `:circular`, `:grid`, `:orthogonal`, `:spectral`, `:tree`, `:spring`, `:force_directed`
- strings with the same names
- a custom callable of the form `(nodes, edges; kwargs...) -> positioned_nodes`

With `layout=:tree`, select the specific algorithm via `algorithm=`:
- `:layered`
- `:radial`

With `layout=:force_directed`, select the specific algorithm via `algorithm=`:
- `:fruchterman_reingold`
- `:kamada_kawai`
- `:forceatlas2`

## Rendering Profiles

The rendering pipeline accepts `profile=` in `SigmaConfig(...)`, `graph(...)`, `render(...)`, and `assemble_graph(...)`.

Available profiles:

- `:default` — current baseline viewer settings
- `:dense` — lower label density and hide edges while moving for denser graphs
- `:large` — more aggressive label reduction and smaller node sizing for larger graphs
- `:presentation` — stronger labels and larger node sizing for demos or screenshots

Explicit keyword arguments still override the profile defaults. For example:

```julia
viz = render(nodes, edges; profile=:large, label_density=0.8)
```

### Accepted input forms

Nodes can be provided as:

- `NodeSpec`
- named tuples such as `(id="a", x=0.0, y=1.0, color="#2563eb")`
- dictionaries with string or symbol keys
- tuples of the form `(id, x, y, size=1.0, label=nothing)`

Edges can be provided as:

- `EdgeSpec`
- named tuples such as `(source="a", target="b", size=0.8)`
- dictionaries with string or symbol keys
- tuples of the form `(source, target, size=1.0, label=nothing)`

You can also pass a `Graphs.jl` graph object directly to `graph(...)` or `render(...)`.
Use `node_mapper` and `edge_mapper` when you want labels, sizes, colors, or
extra attributes derived from graph vertices and edges.

## Notebook Interactions

The viewer now supports:

- hover tooltips
- click-to-select
- neighbor highlighting for the selected node
- optional Julia-side state updates through `IJulia`

Typical usage:

```julia
using LargeGraphs

state = InteractionState()
viz = render(
    nodes,
    edges;
    interaction_state=state,
    layout=:force_directed,
    iterations=80,
    hide_edges_on_move=true,
)

display(viz)
```

After you interact with the graph in the notebook, inspect the state from a new cell:

```julia
selected_node(state)
selected_neighbors(state)
hovered_node(state)
interaction_events(state)
```

Julia-side event updates require `IJulia` and are intended for notebook use.
The browser-side tooltip, selection, and highlight behavior still works in exported HTML.

## Examples

### Save directly to HTML

```julia
savehtml(
    "report-graph.html",
    nodes,
    edges;
    layout=:grid,
    columns=4,
    width="100%",
    height="720px",
    background="#ffffff",
)
```

### Mix typed and untyped graph items

```julia
nodes = [
    NodeSpec("hub"; x=0.0, y=0.0, size=4.0, label="Hub", color="#1d4ed8"),
    Dict("id" => "leaf-1", "x" => -1.0, "y" => 0.5, "color" => "#0f766e"),
    (id="leaf-2", x=1.0, y=-0.2, color="#b45309"),
]

edges = [
    EdgeSpec("hub", "leaf-1"; size=0.7, color="#cbd5e1"),
    (source="hub", target="leaf-2", size=0.7, color="#cbd5e1"),
]

display(render(nodes, edges; render_edge_labels=false))
```

### Use a custom layout function

```julia
function diagonal_layout(nodes, edges; gap=1.0)
    [
        NodeSpec(node.id; x=index * gap, y=-index * gap, size=node.size, label=node.label, color=node.color, attributes=node.attributes)
        for (index, node) in pairs(nodes)
    ]
end

display(render(nodes, edges; layout=diagonal_layout, gap=0.75))
```

## Troubleshooting

### `using LargeGraphs` fails in the notebook

The notebook kernel is usually using a different Julia environment than the one
where the package was added. Activate the intended environment in the notebook
before importing the package.

### The output cell stays blank

Open the browser developer console. Frontend loading failures, blocked network
requests, or JavaScript module errors surface there.

### The exported HTML opens but the graph does not appear

The standalone HTML still loads Sigma.js dependencies from a CDN at runtime. If
the viewing environment blocks external network access, the graph cannot finish
bootstrapping.

### Large graphs feel slow

Reduce labels, lower node sizes, and enable `hide_edges_on_move=true`. The demo
script uses these settings for a reason. Force-directed layouts (`:spring` and
`:force_directed`) use iterative simulation and are generally more expensive
than `:random`, `:circular`, `:grid`, or `:tree`.

## Limitations

- This package currently targets notebook and HTML export workflows, not native GUI rendering.
- The frontend depends on CDN-hosted Sigma.js and Graphology modules.
- The package includes lightweight layouts, not a full graph drawing toolkit.
- Validation of duplicate node IDs or missing referenced nodes is delegated to the browser-side graph construction path.
- Force-directed algorithms use iterative simulation, often with `O(iterations * (n^2 + m))` style costs, so they are not intended for very large graphs.
- Very large graphs still depend on browser memory and WebGL performance.

## Documentation

The repository includes a small `Documenter.jl` site under `docs/`. The source
pages live in `docs/src/`, and you can build them locally with:

```bash
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

Source pages:

- [`docs/src/index.md`](docs/src/index.md)
- [`docs/src/api.md`](docs/src/api.md)
- [`docs/src/notebooks.md`](docs/src/notebooks.md)
- [`docs/src/troubleshooting.md`](docs/src/troubleshooting.md)

## Repository Layout

- `src/LargeGraphs.jl`: package source and public API.
- `assets/sigma-viewer.js`: browser bootstrap for Sigma.js rendering.
- `examples/demo_notebook.ipynb`: notebook demo.
- `examples/demo_large_graph.jl`: script demo with standalone export.
- `test/runtests.jl`: package tests.
_large_graph.jl`: script demo with standalone export.
- `test/runtests.jl`: package tests.
