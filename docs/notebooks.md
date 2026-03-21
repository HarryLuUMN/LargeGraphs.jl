# Notebook Guide

## Environment Setup

In an IJulia notebook, activate the environment that contains `LargeGraphsJL`
before importing the package:

```julia
using Pkg
Pkg.activate(isdir(joinpath(pwd(), "src")) ? pwd() : joinpath(pwd(), ".."))
Pkg.instantiate()
```

Then load the package:

```julia
using LargeGraphsJL
```

## Rendering

Any `SigmaGraph` value renders as HTML in the notebook output area:

```julia
viz = render(nodes, edges; height="600px", hide_edges_on_move=true)
display(viz)
```

Evaluating `viz` as the last expression in a cell also works.

## Demos in This Repository

- `examples/demo_notebook.ipynb` shows a notebook workflow that builds a large random graph.
- `examples/demo_large_graph.jl` generates the same style of output from a script and writes HTML to disk.

## Practical Advice

- Keep labels sparse for large graphs.
- Use `hide_edges_on_move=true` when panning feels sluggish.
- Save a standalone HTML copy when you need to share results with someone outside Julia.
