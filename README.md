# LargeGraphsJL

`LargeGraphsJL` is a Julia package for rendering large interactive graphs in IJulia and Jupyter notebooks with Sigma.js.

## Install

```julia
using Pkg
Pkg.develop(path=".")
Pkg.instantiate()
```

For notebook use, install IJulia in the Julia environment that provides your Jupyter kernel.

## Quick start

```julia
using LargeGraphsJL

nodes = [
    (id="a", x=0.0, y=0.0, label="A", color="#2563eb"),
    (id="b", x=1.0, y=1.0, label="B", color="#059669"),
]

edges = [
    (source="a", target="b", color="#94a3b8"),
]

viz = render(nodes, edges; height="500px", hide_edges_on_move=true)
display(viz)
savehtml("graph.html", viz)
```

The frontend bootstrap script is bundled in `assets/sigma-viewer.js`. It loads Sigma.js and Graphology as ESM modules inside the notebook output cell.
