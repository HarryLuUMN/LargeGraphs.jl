"""
    graph(nodes, edges; id="sigma-...", config=SigmaConfig(), layout=nothing, layout_kwargs...)

Build a normalized `SigmaGraph` from node and edge collections.

Accepted node inputs include `NodeSpec`, named tuples, dictionaries, and tuples
of the form `(id, x, y, size=1.0, label=nothing)`. Accepted edge inputs include
`EdgeSpec`, named tuples, dictionaries, and tuples of the form
`(source, target, size=1.0, label=nothing)`.
"""
function graph(nodes, edges; id=string("sigma-", uuid4()), config=SigmaConfig(), layout=nothing, layout_kwargs...)
    normalized_nodes = _normalize_nodes(nodes)
    normalized_edges = _normalize_edges(edges)
    _validate_graph_inputs(normalized_nodes, normalized_edges)
    SigmaGraph(
        string(id),
        _apply_layout(normalized_nodes, normalized_edges, layout; layout_kwargs...),
        normalized_edges,
        config,
    )
end

"""
    render(nodes, edges; layout=nothing, kwargs...)

Create a `SigmaGraph` with inline rendering configuration.

This is the main convenience entry point for notebook display.
"""
function render(
    nodes,
    edges;
    id=string("sigma-", uuid4()),
    layout=nothing,
    width="100%",
    height="700px",
    background="#ffffff",
    camera_ratio=1.0,
    render_edge_labels=false,
    hide_edges_on_move=false,
    label_density=1.0,
    label_grid_cell_size=80,
    max_node_size=16.0,
    min_node_size=2.0,
    layout_kwargs...,
)
    graph(
        nodes,
        edges;
        id=id,
        layout=layout,
        config=SigmaConfig(
            width=width,
            height=height,
            background=background,
            camera_ratio=camera_ratio,
            render_edge_labels=render_edge_labels,
            hide_edges_on_move=hide_edges_on_move,
            label_density=label_density,
            label_grid_cell_size=label_grid_cell_size,
            max_node_size=max_node_size,
            min_node_size=min_node_size,
        ),
        layout_kwargs...,
    )
end

render(value::SigmaGraph) = value
