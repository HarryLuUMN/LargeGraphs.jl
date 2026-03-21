# LargeGraphsJL

`LargeGraphsJL` is a small Julia package for rendering interactive graph
visualizations with [Sigma.js](https://www.sigmajs.org/) in IJulia and Jupyter
notebooks. It accepts plain Julia collections, includes a lightweight batch of
classic layout algorithms, produces notebook-friendly HTML, and can export
standalone HTML files for sharing outside Julia.

## Why this package

- Targets notebook workflows where fast visual inspection matters.
- Accepts lightweight Julia data structures instead of requiring a graph type.
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
Pkg.add(url="git@github.com:HarryLuUMN/large-graphs-jl.git")
```

### Notebook prerequisite

Install `IJulia` in the Julia environment that backs your notebook kernel:

```julia
using Pkg
Pkg.add("IJulia")
```

If the package is installed in one environment and the notebook kernel points
at another, `using LargeGraphsJL` will fail inside the notebook even if it works
from the terminal.

## Quick Start

```julia
using LargeGraphsJL

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
    layout=:spring,
    iterations=80,
    seed=7,
    height="520px",
    background="#f8fafc",
    hide_edges_on_move=true,
    max_node_size=12.0,
)

display(viz)
savehtml("graph.html", viz)
```

## Notebook Usage

`SigmaGraph` implements HTML display, so a notebook cell only needs to evaluate
or `display` the value returned by `render(...)` or `graph(...)`.

The repository includes:

- `examples/demo_notebook.ipynb` for an IJulia notebook workflow.
- `examples/demo_large_graph.jl` for script-based standalone export.

Typical notebook setup:

```julia
using Pkg
Pkg.activate(isdir(joinpath(pwd(), "src")) ? pwd() : joinpath(pwd(), ".."))
Pkg.instantiate()

using LargeGraphsJL
```

When a graph does not render in Jupyter, open the browser console first. The
viewer loads Sigma.js and Graphology as browser ESM modules, so frontend errors
usually show up there immediately.

## API Overview

### Constructors

- `NodeSpec(id; x, y, size, label, color, attributes)`
- `EdgeSpec(source, target; id, size, label, color, attributes)`
- `SigmaConfig(; width, height, background, camera_ratio, render_edge_labels, hide_edges_on_move, label_density, label_grid_cell_size, max_node_size, min_node_size)`

### Main functions

- `graph(nodes, edges; id, config, layout=nothing, layout_kwargs...)` normalizes graph data into a `SigmaGraph`.
- `render(nodes, edges; layout=nothing, kwargs..., layout_kwargs...)` builds a `SigmaGraph` with inline render options.
- `savehtml(path, graph)` writes a standalone HTML file.
- `savehtml(path, nodes, edges; kwargs...)` combines rendering and export in one call.
- `random_layout(nodes; seed, extent)` assigns random coordinates.
- `circular_layout(nodes; radius, start_angle)` places nodes on a circle.
- `grid_layout(nodes; columns, spacing)` places nodes on a centered grid.
- `spring_layout(nodes, edges; iterations, seed, extent, gravity, cooling)` runs a lightweight force-directed layout.

### Layout usage

You can call a layout function directly when you want explicit positioned nodes:

```julia
positioned_nodes = circular_layout(nodes; radius=2.5)
viz = render(positioned_nodes, edges; height="520px")
```

Or you can let `render` apply the layout for you:

```julia
viz = render(nodes, edges; layout=:spring, iterations=100, seed=3)
```

`layout` accepts:

- symbols: `:random`, `:circular`, `:grid`, `:spring`
- strings with the same names
- a custom callable of the form `(nodes, edges; kwargs...) -> positioned_nodes`

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

### `using LargeGraphsJL` fails in the notebook

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
script uses these settings for a reason. For layouts, `spring_layout` is the
most expensive option because it does iterative force simulation.

## Limitations

- This package currently targets notebook and HTML export workflows, not native GUI rendering.
- The frontend depends on CDN-hosted Sigma.js and Graphology modules.
- The package includes lightweight layouts, not a full graph drawing toolkit.
- Validation of duplicate node IDs or missing referenced nodes is delegated to the browser-side graph construction path.
- `spring_layout` uses an `O(iterations * (n^2 + m))` force simulation, so it is not intended for very large graphs.
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

- `src/LargeGraphsJL.jl`: package source and public API.
- `assets/sigma-viewer.js`: browser bootstrap for Sigma.js rendering.
- `examples/demo_notebook.ipynb`: notebook demo.
- `examples/demo_large_graph.jl`: script demo with standalone export.
- `test/runtests.jl`: package tests.
