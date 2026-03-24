# LargeGraphs Examples

This directory is organized by workflow rather than by feature list.

## Recommended reading order

### 1. `demo_staged_pipeline.ipynb`
Use this first.

It demonstrates the recommended staged workflow:
- `layout_graph(...)`
- `assemble_graph(...)`
- `render(...)`
- `savehtml(...)`

This is the best entry point when you want to understand how `LargeGraphs` is structured internally and how to separate layout from rendering/export.

### 2. `demo_notebook.ipynb`
Use this for the general notebook rendering workflow.

It shows:
- notebook rendering
- multiple layout styles
- large-graph viewing patterns

### 3. `demo_graphsjl.ipynb`
Use this when your upstream data already lives in `Graphs.jl`.

It shows how to render `Graphs.AbstractGraph` values directly with `node_mapper` and `edge_mapper`.

### 4. `demo_layout_functions.ipynb`
Use this when you want to inspect direct layout functions and compare their outputs.

This is the right example when layout choice itself is the main question.

### 5. `demo_interactions.ipynb`
Use this when you want Julia-side interaction state in IJulia.

It focuses on:
- click / hover state
- selected neighbors
- interaction event capture

### 6. `demo_large_graph.jl`
Use this for script-driven standalone export outside a notebook.

It writes HTML directly to disk and is a good reference for batch or report workflows.

## Suggested paths by task

### I want the default way to use the package
Start with:
- `demo_staged_pipeline.ipynb`

### I want the shortest path to seeing a graph in a notebook
Start with:
- `demo_notebook.ipynb`

### I already use `Graphs.jl`
Start with:
- `demo_graphsjl.ipynb`

### I need to decide which layout to use
Start with:
- `demo_layout_functions.ipynb`
- then read `docs/src/layout-guide.md`
- and compare against the staged workflow in `demo_staged_pipeline.ipynb` when you want to separate layout from rendering

### I care about notebook interactivity
Start with:
- `demo_interactions.ipynb`

### I want standalone HTML output from a script
Start with:
- `demo_large_graph.jl`
