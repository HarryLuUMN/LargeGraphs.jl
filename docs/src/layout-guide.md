# Choose a Layout

This guide helps you choose a layout based on graph size, structure, and the trade-off between speed and visual structure.

## Quick selection table

| Layout | Needs edges | Best for | Typical scale | Cost | Notes |
| --- | --- | --- | --- | --- | --- |
| `:random` | no | fast previews, very large graphs, baseline rendering | very large | very low | best when you care more about rendering throughput than structure |
| `:circular` | no | cyclic or small graphs, quick inspection | small to medium | very low | simple and stable, preserves input order around a circle |
| `:grid` | no | debugging, regular comparisons, quick deterministic placement | small to medium | very low | useful when structure matters less than repeatability |
| `:orthogonal` | yes | sparse graphs, component overviews, rectilinear drawing | small to medium | low | breadth-first style layout with alternating horizontal and vertical levels |
| `:spectral` | yes | medium graphs where you want a cheap structure-aware layout | medium | low to medium | lightweight alternative to force simulation; good default for denser graphs |
| `:tree` | yes | rooted trees, hierarchies, DAG-like structures | small to medium | low | use `algorithm=:layered` or `:radial` |
| `:force_directed` | yes | natural-looking layouts for exploratory analysis | small to medium | medium with `:sfdp`, high with legacy solvers | supports `:sfdp`, `:network_spring`, `:fruchterman_reingold`, `:kamada_kawai`, `:forceatlas2` |
| `:spring` | yes | compatibility alias for force-directed layout | small to medium | high | maps to Fruchterman-Reingold |

## Practical recommendations

### If the graph is very large
Prefer:
- `:random`
- `:spectral`
- precomputed coordinates

Avoid expensive force simulation unless the graph is still small enough to justify the layout cost.

### If the graph is dense but not huge
Prefer:
- `:spectral`
- `profile=:dense` or `profile=:large`

This is often a better trade-off than force simulation because it preserves more global structure at lower cost.

### If the graph is a tree or hierarchy
Prefer:
- `layout=:tree, algorithm=:layered`
- `layout=:tree, algorithm=:radial`

Use `:layered` when readability matters more than compactness.
Use `:radial` when you want a more compact, symmetric presentation.

### If the goal is a presentation or screenshot
Start with:
- `:circular`
- `:tree`
- `:force_directed`
- Recommended default: `layout=:force_directed, algorithm=:sfdp`
- `profile=:presentation`

Then adjust labels and node sizing for readability.

## Suggested defaults by task

### Fast notebook preview
```julia
render(nodes, edges; layout=:random, profile=:large)
```

### Cheap structure-aware layout
```julia
render(nodes, edges; layout=:spectral, profile=:dense)
```

### Hierarchy view
```julia
render(nodes, edges; layout=:tree, algorithm=:layered)
```

### Natural exploratory layout
```julia
render(nodes, edges; layout=:force_directed, algorithm=:sfdp, iterations=80)
```

## Staged workflow advice

When comparing layouts seriously, prefer the staged pipeline:

```julia
layouted = layout_graph(nodes, edges; layout=:spectral)
viz = assemble_graph(layouted; profile=:dense)
```

This makes it easier to benchmark layout cost separately from rendering and export.
