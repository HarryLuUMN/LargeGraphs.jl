# Pipeline Guide

`LargeGraphs` supports three related workflows, but the staged pipeline is the recommended default when you want control, reuse, or benchmarking clarity.

## Workflow selection

| Workflow | Best for | Core calls |
| --- | --- | --- |
| Staged pipeline | Reuse one layout across multiple renders or exports | `layout_graph` -> `assemble_graph` |
| One-shot render | Fast notebook iteration | `render` |
| `Graphs.jl` direct render | Existing `Graphs.jl` projects | `render(g; ...)` |

## Recommended staged workflow

Use the staged pipeline when you want to:

- cache or inspect layout results
- render the same graph with multiple configurations
- benchmark layout separately from rendering/export
- export one layout to several artifacts

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

The staged workflow splits into three responsibilities:

1. `layout_graph(...)` normalizes the inputs and computes coordinates.
2. `assemble_graph(...)` turns positioned nodes and normalized edges into a `SigmaGraph`.
3. `display(...)` and `savehtml(...)` present or export the result.

## One-shot rendering

Use `render(...)` when you want a single call and do not need to reuse intermediate results.

```julia
viz = render(
    nodes,
    edges;
    layout=:force_directed,
    algorithm=:fruchterman_reingold,
    iterations=120,
    seed=7,
    height="520px",
)
```

This is the shortest path for exploratory notebook work, but it couples layout and rendering.

## `Graphs.jl` input

Use direct `Graphs.jl` rendering when your upstream pipeline already produces `Graphs.AbstractGraph` values.

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

## Example notebooks

- `examples/demo_staged_pipeline.ipynb` — recommended staged workflow
- `examples/demo_notebook.ipynb` — general notebook rendering
- `examples/demo_graphsjl.ipynb` — `Graphs.jl` workflow
- `examples/demo_layout_functions.ipynb` — direct layout calls
- `examples/demo_interactions.ipynb` — notebook interaction state

## Why this matters for benchmarking

The staged workflow makes performance analysis much clearer because it lets you separate:

- layout cost
- graph assembly cost
- render/export cost

That is the preferred path for serious benchmarks or repeated exports.
