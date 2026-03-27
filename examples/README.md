# LargeGraphs Examples

This directory is organized by workflow rather than by feature list.

## Core examples

Start with these four unless you already know exactly what you need.

### 1. `demo_staged_pipeline.ipynb`
Use this first.

It demonstrates the recommended staged workflow:
- `layout_graph(...)`
- `assemble_graph(...)`
- `render(...)`
- `savehtml(...)`

This is the best entry point when you want to understand the package structure and the recommended default workflow.

### 2. `demo_notebook.ipynb`
Use this for the general notebook rendering workflow.

It shows:
- notebook rendering
- multiple layout styles
- large-graph viewing patterns

### 3. `demo_networklayout_layouts.ipynb`
Use this when you want the current recommended fast force-directed path.

It focuses on:
- `algorithm=:network_spring`
- `algorithm=:sfdp`
- the `NetworkLayout.jl`-backed options that currently provide the best default speed

### 4. `demo_graphsjl.ipynb`
Use this when your upstream data already lives in `Graphs.jl`.

It shows how to render `Graphs.AbstractGraph` values directly with `node_mapper` and `edge_mapper`.

## Additional examples

### `demo_layout_functions.ipynb`
Use this when layout comparison itself is the main question.

### `demo_interactions.ipynb`
Use this when you want Julia-side interaction state in IJulia.

It focuses on:
- click / hover state
- selected neighbors
- interaction event capture

### `demo_large_graph.jl`
Use this for script-driven standalone export outside a notebook.

It writes HTML directly to disk and is a good reference for batch or report workflows.

## Suggested paths by task

### I want the default way to use the package
Start with:
- `demo_staged_pipeline.ipynb`
- then `demo_networklayout_layouts.ipynb`

### I want the shortest path to seeing a graph in a notebook
Start with:
- `demo_notebook.ipynb`
- then `demo_networklayout_layouts.ipynb` if you want the recommended fast default layout path

### I already use `Graphs.jl`
Start with:
- `demo_graphsjl.ipynb`

### I need to decide which layout to use
Start with:
- `demo_networklayout_layouts.ipynb`
- `demo_layout_functions.ipynb`
- then read `docs/src/layout-guide.md`
- and compare against the staged workflow in `demo_staged_pipeline.ipynb` when you want to separate layout from rendering

### I care about notebook interactivity
Start with:
- `demo_interactions.ipynb`

### I want standalone HTML output from a script
Start with:
- `demo_large_graph.jl`

### I want a browseable showcase site
Start with:
- <https://github.com/HarryLuUMN/LargeGraphGallery>
