"""
    layout_graph(nodes, edges; layout=nothing, layout_kwargs...)
    layout_graph(g::Graphs.AbstractGraph; layout=nothing, node_mapper=..., edge_mapper=..., layout_kwargs...)

Normalize graph inputs and apply an optional layout step without building a
`SigmaGraph`. The return value is a named tuple with `nodes` and `edges`.
"""
function layout_graph(nodes, edges; layout=nothing, layout_kwargs...)
    normalized_nodes, normalized_edges = _normalize_graph_inputs(nodes, edges)
    (
        nodes=_apply_layout(normalized_nodes, normalized_edges, layout; layout_kwargs...),
        edges=normalized_edges,
    )
end

function layout_graph(
    g::Graphs.AbstractGraph;
    layout=nothing,
    node_mapper=vertex -> (id=string(vertex),),
    edge_mapper=edge -> (source=string(Graphs.src(edge)), target=string(Graphs.dst(edge))),
    layout_kwargs...,
)
    nodes = [node_mapper(vertex) for vertex in Graphs.vertices(g)]
    edges = [edge_mapper(edge) for edge in Graphs.edges(g)]
    layout_graph(nodes, edges; layout=layout, layout_kwargs...)
end

"""
    assemble_graph(nodes, edges; id="sigma-...", config=SigmaConfig(), interaction_state=nothing, ...)
    assemble_graph(layouted; id="sigma-...", config=SigmaConfig(), interaction_state=nothing, ...)

Build a `SigmaGraph` from already-normalized or already-laid-out graph data
without running a layout step.
"""
function assemble_graph(
    nodes,
    edges;
    id=string("sigma-", uuid4()),
    config=SigmaConfig(),
    interaction_state=nothing,
    enable_selection=true,
    enable_tooltips=true,
    highlight_neighbors=true,
)
    normalized_nodes, normalized_edges = _normalize_graph_inputs(nodes, edges)
    SigmaGraph(
        string(id),
        normalized_nodes,
        normalized_edges,
        config,
        _interaction_payload(
            interaction_state;
            enable_selection=enable_selection,
            enable_tooltips=enable_tooltips,
            highlight_neighbors=highlight_neighbors,
        ),
    )
end

function assemble_graph(
    layouted::NamedTuple;
    id=string("sigma-", uuid4()),
    config=SigmaConfig(),
    interaction_state=nothing,
    enable_selection=true,
    enable_tooltips=true,
    highlight_neighbors=true,
)
    @assert haskey(layouted, :nodes) && haskey(layouted, :edges)
    assemble_graph(
        layouted.nodes,
        layouted.edges;
        id=id,
        config=config,
        interaction_state=interaction_state,
        enable_selection=enable_selection,
        enable_tooltips=enable_tooltips,
        highlight_neighbors=highlight_neighbors,
    )
end

"""
    graph(nodes, edges; id="sigma-...", config=SigmaConfig(), layout=nothing, layout_kwargs...)

Build a normalized `SigmaGraph` from node and edge collections.

Accepted node inputs include `NodeSpec`, named tuples, dictionaries, and tuples
of the form `(id, x, y, size=1.0, label=nothing)`. Accepted edge inputs include
`EdgeSpec`, named tuples, dictionaries, and tuples of the form
`(source, target, size=1.0, label=nothing)`.
"""
function graph(
    nodes,
    edges;
    id=string("sigma-", uuid4()),
    config=SigmaConfig(),
    layout=nothing,
    interaction_state=nothing,
    enable_selection=true,
    enable_tooltips=true,
    highlight_neighbors=true,
    layout_kwargs...,
)
    layouted = layout_graph(nodes, edges; layout=layout, layout_kwargs...)
    assemble_graph(
        layouted;
        id=id,
        config=config,
        interaction_state=interaction_state,
        enable_selection=enable_selection,
        enable_tooltips=enable_tooltips,
        highlight_neighbors=highlight_neighbors,
    )
end

function _normalize_graph_inputs(nodes, edges)
    normalized_nodes = _normalize_nodes(nodes)
    normalized_edges = _normalize_edges(edges)
    _validate_graph_inputs(normalized_nodes, normalized_edges)
    normalized_nodes, normalized_edges
end

function _build_render_config(;
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
)
    SigmaConfig(
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
    )
end

"""
    graph(g::Graphs.AbstractGraph; id="sigma-...", config=SigmaConfig(), layout=nothing, node_mapper=..., edge_mapper=..., layout_kwargs...)

Build a normalized `SigmaGraph` from a `Graphs.jl` graph object.

`node_mapper` receives each vertex and should return any supported node input.
`edge_mapper` receives each graph edge and should return any supported edge input.
The defaults keep only connectivity and use stringified vertex ids.
"""
function graph(
    g::Graphs.AbstractGraph;
    id=string("sigma-", uuid4()),
    config=SigmaConfig(),
    layout=nothing,
    interaction_state=nothing,
    enable_selection=true,
    enable_tooltips=true,
    highlight_neighbors=true,
    node_mapper=vertex -> (id=string(vertex),),
    edge_mapper=edge -> (source=string(Graphs.src(edge)), target=string(Graphs.dst(edge))),
    layout_kwargs...,
)
    layouted = layout_graph(
        g;
        layout=layout,
        node_mapper=node_mapper,
        edge_mapper=edge_mapper,
        layout_kwargs...,
    )
    assemble_graph(
        layouted;
        id=id,
        config=config,
        interaction_state=interaction_state,
        enable_selection=enable_selection,
        enable_tooltips=enable_tooltips,
        highlight_neighbors=highlight_neighbors,
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
    interaction_state=nothing,
    enable_selection=true,
    enable_tooltips=true,
    highlight_neighbors=true,
    layout_kwargs...,
)
    config = _build_render_config(
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
    )
    layouted = layout_graph(nodes, edges; layout=layout, layout_kwargs...)
    assemble_graph(
        layouted;
        id=id,
        config=config,
        interaction_state=interaction_state,
        enable_selection=enable_selection,
        enable_tooltips=enable_tooltips,
        highlight_neighbors=highlight_neighbors,
    )
end

"""
    render(g::Graphs.AbstractGraph; kwargs...)

Create a `SigmaGraph` from a `Graphs.jl` graph object with inline rendering configuration.
"""
function render(
    g::Graphs.AbstractGraph;
    id=string("sigma-", uuid4()),
    layout=nothing,
    node_mapper=vertex -> (id=string(vertex),),
    edge_mapper=edge -> (source=string(Graphs.src(edge)), target=string(Graphs.dst(edge))),
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
    interaction_state=nothing,
    enable_selection=true,
    enable_tooltips=true,
    highlight_neighbors=true,
    layout_kwargs...,
)
    config = _build_render_config(
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
    )
    layouted = layout_graph(
        g;
        layout=layout,
        node_mapper=node_mapper,
        edge_mapper=edge_mapper,
        layout_kwargs...,
    )
    assemble_graph(
        layouted;
        id=id,
        config=config,
        interaction_state=interaction_state,
        enable_selection=enable_selection,
        enable_tooltips=enable_tooltips,
        highlight_neighbors=highlight_neighbors,
    )
end

render(value::SigmaGraph) = value
