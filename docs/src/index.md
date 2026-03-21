# LargeGraphsJL Documentation

`LargeGraphsJL` renders interactive Sigma.js graph views from plain Julia data.
It is designed for notebook-first exploration with the option to export
standalone HTML snapshots.

## Scope

This package is intentionally small:

- normalize node and edge inputs into a stable internal form
- render HTML suitable for IJulia and Jupyter display
- export a standalone HTML document for sharing outside the notebook

It does not attempt to be a graph algorithms package or a layout engine.

## Start Here

- Use [API reference](api.md) for constructor and function details.
- Use [Notebook guide](notebooks.md) for IJulia and Jupyter workflows.
- Use [Troubleshooting](troubleshooting.md) when rendering does not behave as expected.

## Local Docs Build

From the repository root, instantiate the docs environment and build:

```bash
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
julia --project=docs docs/make.jl
```
