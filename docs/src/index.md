# LargeGraphs Documentation

`LargeGraphs` renders interactive Sigma.js graph views from plain Julia data.
It is designed for notebook-first exploration with the option to export
standalone HTML snapshots, and it now includes a small batch of built-in layout
algorithms for basic graph drawing.

## Scope

This package is intentionally small:

- normalize node and edge inputs into a stable internal form
- compute lightweight random, circular, grid, and force-directed layouts
- render HTML suitable for IJulia and Jupyter display
- export a standalone HTML document for sharing outside the notebook

It does not attempt to be a full graph algorithms package or a heavy-duty
layout engine.

## Start Here

- Use [API reference](api.md) for constructor and function details.
- Use [Notebook guide](notebooks.md) for IJulia and Jupyter workflows.
- Use [Troubleshooting](troubleshooting.md) when rendering does not behave as expected.

## Layout Entry Points

- Call `random_layout`, `circular_layout`, `grid_layout`, `force_directed_layout`,
  or `spring_layout` directly when you want explicit positioned nodes.
- Pass `layout=:random`, `:circular`, `:grid`, `:spring`, or `:force_directed`
  to `graph(...)` or `render(...)` when you want layout as a convenience.
- For `layout=:force_directed`, choose `algorithm=:fruchterman_reingold`,
  `:kamada_kawai`, or `:forceatlas2`.
- Pass a custom callable to `layout=` when the built-in layouts are not enough.

## Local Docs Build

From the repository root, instantiate the docs environment and build:

```bash
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
julia --project=docs docs/make.jl
```
