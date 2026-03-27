# LargeGraphs Documentation

`LargeGraphs` renders interactive Sigma.js graph views from plain Julia data.
It is designed for notebook-first exploration with the option to export
standalone HTML snapshots, and it now includes a small batch of built-in layout
algorithms for basic graph drawing.

## Primary Workflow

The recommended default is the staged pipeline:

1. `layout_graph(...)` to normalize data and compute coordinates.
2. `assemble_graph(...)` to build a `SigmaGraph` from the layout result.
3. `display(...)` and optionally `savehtml(...)`.

Use `render(...)` when you want a one-shot convenience call, and use
`render(g::Graphs.AbstractGraph; ...)` when your project already starts from a
`Graphs.jl` graph.

## Scope

This package is intentionally small:

- normalize node and edge inputs into a stable internal form
- accept `Graphs.jl` graph objects through the same rendering pipeline
- compute lightweight random, circular, grid, spectral, tree, and force-directed layouts
- render HTML suitable for IJulia and Jupyter display
- support click/hover notebook interactions, selected-neighbor highlighting, and Julia-side interaction state in IJulia
- export a standalone HTML document for sharing outside the notebook

It does not attempt to be a full graph algorithms package or a heavy-duty
layout engine.

## Start Here

- Use [Pipeline guide](pipeline.md) for workflow selection and staged-first usage.
- Use [Alpha Status](alpha-status.md) for current scope, fit, and known limits.
- Use [Validation](validation.md) for the current black-box notebook smoke-check status.
- Use [Choose a layout](layout-guide.md) when deciding between random, spectral, tree, and force-directed rendering paths.
- Use [API reference](api.md) for constructor and function details.
- Use [Notebook guide](notebooks.md) for IJulia and Jupyter workflows.
- Use `examples/README.md` in the repository root when you want a workflow-oriented map of the example notebooks and scripts.
- Use `gallery/README.md` in the repository root for the standalone gallery build and `gallery/build/index.html` for the latest committed static showcase output.
- Use [Troubleshooting](troubleshooting.md) when rendering does not behave as expected.
- Use the repository `benchmarks/` subproject for rendering benchmark scripts and results.

## Layout Entry Points

- Call `random_layout`, `circular_layout`, `grid_layout`, `spectral_layout`, `tree_layout`, `force_directed_layout`,
  or `spring_layout` directly when you want explicit positioned nodes.
- Pass `layout=:random`, `:circular`, `:grid`, `:spectral`, `:tree`, `:spring`, or `:force_directed`
  to `graph(...)` or `render(...)` when you want layout as a convenience.
- For `layout=:tree`, choose `algorithm=:layered` or `:radial`.
- For `layout=:force_directed`, use `algorithm=:sfdp` as the recommended default.
- Alternative force-directed algorithms include `:fruchterman_reingold`,
  `:kamada_kawai`, `:forceatlas2`, and `:network_spring`.
- Pass a custom callable to `layout=` when the built-in layouts are not enough.

## Local Docs Build

From the repository root, instantiate the docs environment and build:

```bash
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
julia --project=docs docs/make.jl
```
