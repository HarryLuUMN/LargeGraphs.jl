# Alpha Status

`LargeGraphs` is currently positioned as an alpha-stage package for
notebook-first graph visualization in Julia.

## Best Fit

Use it when you want:

- quick interactive graph inspection in IJulia or Jupyter
- direct rendering from lightweight Julia collections or `Graphs.jl`
- standalone HTML export without building a larger web app around the graph
- a staged workflow where layout, graph assembly, and export are easy to reason about separately

## Not Yet Optimized For

This is not yet the best choice when you need:

- a long-term stable public API contract
- a broad suite of battle-tested layout backends with deeply tuned controls
- full-scale benchmark coverage across many datasets, hardware targets, and rendering environments
- polished operational tooling around packaging and hosting exported graphs

## Recommended Starting Point

For early users, the recommended default path is:

1. `layout_graph(...; layout=:force_directed, algorithm=:sfdp, ...)`
2. `assemble_graph(...)`
3. `display(...)` and optionally `savehtml(...)`

If you want the shortest route to something visible in a notebook, use
`render(...; layout=:force_directed, algorithm=:sfdp, ...)`.

## Current Priorities

- keep the staged pipeline obvious and easy to adopt
- keep the fast `NetworkLayout.jl`-backed defaults stable
- validate the main notebook and export workflows with representative examples
- collect feedback from initial users before adding many more surface-level features

## Early-User Expectations

If you are evaluating the package today, expect:

- active iteration on defaults and docs
- good results on the documented example paths
- some rough edges outside the main workflows
- continued refinement of performance, especially around layout choices and benchmark coverage
