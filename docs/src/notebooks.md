# Notebook Guide

## Environment Setup

In an IJulia notebook, activate the environment that contains `LargeGraphs`
before importing the package:

```julia
using Pkg
Pkg.activate(isdir(joinpath(pwd(), "src")) ? pwd() : joinpath(pwd(), ".."))
Pkg.instantiate()
```

Then load the package:

```julia
using LargeGraphs
```

## Rendering

Any `SigmaGraph` value renders as HTML in the notebook output area:

```julia
viz = render(nodes, edges; layout=:force_directed, algorithm=:fruchterman_reingold, iterations=120, seed=7, height="600px", hide_edges_on_move=true)
display(viz)
```

Evaluating `viz` as the last expression in a cell also works.

If you already have a `Graphs.jl` graph, you can render it directly:

```julia
using Graphs

g = wheel_graph(8)
viz = render(
    g;
    layout=:circular,
    node_mapper=v -> (id="v$v", label="v$v", size=v == 1 ? 3.0 : 1.6),
)
```

If you want to inspect or reuse node coordinates before rendering, call a
layout directly:

```julia
positioned_nodes = grid_layout(nodes; columns=4, spacing=1.2)
viz = render(positioned_nodes, edges; height="600px")
```

## Interaction State

For notebook exploration, you can capture click and hover state back into Julia:

```julia
using IJulia
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

After interacting with the graph in the output cell:

```julia
selected_node(state)
selected_neighbors(state)
hovered_node(state)
interaction_events(state)
```

The viewer also shows hover tooltips, supports click-to-select, and highlights
neighbors of the selected node in the browser.

## Demos in This Repository

For a workflow-oriented overview of the repository examples, see `examples/README.md` in the project root.


- `examples/demo_staged_pipeline.ipynb` shows the recommended staged workflow.
- `examples/demo_notebook.ipynb` shows notebook rendering workflows and large-graph viewing.
- `examples/demo_layout_functions.ipynb` shows direct layout functions returning positioned nodes.
- `examples/demo_graphsjl.ipynb` shows the `Graphs.jl` input workflow.
- `examples/demo_interactions.ipynb` shows the notebook interaction workflow.
- `examples/demo_large_graph.jl` generates the same style of output from a script and writes HTML to disk.

## Practical Advice

- Keep labels sparse for large graphs.
- Use `profile=:dense` or `profile=:large` when panning feels sluggish or labels become cluttered.
- Use `:random`, `:circular`, `:grid`, `:spectral`, or `:tree` for cheaper layout options when the graph structure fits; force-directed layouts (`:spring`, `:force_directed`) are more expensive.
- Save a standalone HTML copy when you need to share results with someone outside Julia.
