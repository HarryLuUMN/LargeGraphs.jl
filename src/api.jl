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
    profile=:default,
    interaction_state=nothing,
    enable_selection=true,
    enable_tooltips=true,
    highlight_neighbors=true,
)
    normalized_nodes, normalized_edges = _normalize_graph_inputs(nodes, edges)
    resolved_profile = _resolve_profile(profile, length(normalized_nodes), length(normalized_edges))
    resolved_config = resolved_profile == :default ? config : SigmaConfig(
        width=config.width,
        height=config.height,
        background=config.background,
        camera_ratio=config.camera_ratio,
        profile=resolved_profile,
        node_count=length(normalized_nodes),
        edge_count=length(normalized_edges),
    )
    SigmaGraph(
        string(id),
        normalized_nodes,
        normalized_edges,
        resolved_config,
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
    profile=:default,
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
        profile=profile,
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
    profile=:default,
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
        profile=profile,
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
    profile=:default,
    node_count=0,
    edge_count=0,
    width=nothing,
    height=nothing,
    background=nothing,
    camera_ratio=nothing,
    render_edge_labels=nothing,
    hide_edges_on_move=nothing,
    label_density=nothing,
    label_grid_cell_size=nothing,
    max_node_size=nothing,
    min_node_size=nothing,
)
    SigmaConfig(
        profile=profile,
        node_count=node_count,
        edge_count=edge_count,
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
    profile=:default,
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
        profile=profile,
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
    profile=:default,
    width=nothing,
    height=nothing,
    background=nothing,
    camera_ratio=nothing,
    render_edge_labels=nothing,
    hide_edges_on_move=nothing,
    label_density=nothing,
    label_grid_cell_size=nothing,
    max_node_size=nothing,
    min_node_size=nothing,
    interaction_state=nothing,
    enable_selection=true,
    enable_tooltips=true,
    highlight_neighbors=true,
    layout_kwargs...,
)
    layouted = layout_graph(nodes, edges; layout=layout, layout_kwargs...)
    config = _build_render_config(
        profile=profile,
        node_count=length(layouted.nodes),
        edge_count=length(layouted.edges),
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
    profile=:default,
    width=nothing,
    height=nothing,
    background=nothing,
    camera_ratio=nothing,
    render_edge_labels=nothing,
    hide_edges_on_move=nothing,
    label_density=nothing,
    label_grid_cell_size=nothing,
    max_node_size=nothing,
    min_node_size=nothing,
    interaction_state=nothing,
    enable_selection=true,
    enable_tooltips=true,
    highlight_neighbors=true,
    layout_kwargs...,
)
    layouted = layout_graph(
        g;
        layout=layout,
        node_mapper=node_mapper,
        edge_mapper=edge_mapper,
        layout_kwargs...,
    )
    config = _build_render_config(
        profile=profile,
        node_count=length(layouted.nodes),
        edge_count=length(layouted.edges),
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

"""
    recommend_profile(nodes, edges)
    recommend_profile(g::Graphs.AbstractGraph)

Recommend a rendering profile from graph size and density.
"""
function recommend_profile(nodes, edges)
    normalized_nodes, normalized_edges = _normalize_graph_inputs(nodes, edges)
    _recommended_profile(length(normalized_nodes), length(normalized_edges))
end

recommend_profile(g::Graphs.AbstractGraph) = _recommended_profile(Graphs.nv(g), Graphs.ne(g))

function _attribute_dict(value)
    isnothing(value) && return Dict{String, Any}()
    value isa NamedTuple && return Dict{String, Any}(string(k) => v for (k, v) in pairs(value))
    value isa AbstractDict && return Dict{String, Any}(string(k) => v for (k, v) in pairs(value))
    Dict{String, Any}("value" => value)
end

function _dict_get_any(dict::AbstractDict{String, Any}, keys, default=nothing)
    for key in keys
        key_string = string(key)
        haskey(dict, key_string) && return dict[key_string]
    end
    default
end

function _edge_attribute_value(attributes::AbstractDict, edge; undirected_lookup::Bool)
    source = Graphs.src(edge)
    target = Graphs.dst(edge)
    keys = Any[
        edge,
        (source, target),
        (string(source), string(target)),
        string(source) * "=>" * string(target),
    ]
    if undirected_lookup
        append!(keys, Any[
            (target, source),
            (string(target), string(source)),
            string(target) * "=>" * string(source),
        ])
    end
    for key in keys
        haskey(attributes, key) && return attributes[key]
    end
    nothing
end

"""
    vertex_attribute_mapper(attributes; kwargs...)

Build a `node_mapper` for `graph(g; node_mapper=...)` or `render(g; node_mapper=...)`
from a vertex-attribute lookup table.
"""
function vertex_attribute_mapper(
    attributes::AbstractDict;
    id_mapper=vertex -> string(vertex),
    label_keys=(:label, "label", :name, "name"),
    color_keys=(:color, "color"),
    size_keys=(:size, "size", :weight, "weight"),
    attributes_key=:attributes,
)
    function mapper(vertex)
        raw = haskey(attributes, vertex) ? attributes[vertex] : nothing
        data = _attribute_dict(raw)
        nested_attributes = _attribute_dict(_dict_get_any(data, (attributes_key, string(attributes_key)), Dict{String, Any}()))
        return (
            id=string(id_mapper(vertex)),
            label=_dict_get_any(data, label_keys, nothing),
            color=_dict_get_any(data, color_keys, nothing),
            size=_dict_get_any(data, size_keys, 1.0),
            attributes=nested_attributes,
        )
    end
    mapper
end

"""
    edge_attribute_mapper(attributes; kwargs...)

Build an `edge_mapper` for `graph(g; edge_mapper=...)` or `render(g; edge_mapper=...)`
from an edge-attribute lookup table.
"""
function edge_attribute_mapper(
    attributes::AbstractDict;
    source_mapper=src -> string(src),
    target_mapper=dst -> string(dst),
    id_keys=(:id, "id", :key, "key"),
    label_keys=(:label, "label"),
    color_keys=(:color, "color"),
    size_keys=(:size, "size", :weight, "weight"),
    attributes_key=:attributes,
    undirected_lookup=true,
)
    function mapper(edge)
        raw = _edge_attribute_value(attributes, edge; undirected_lookup=undirected_lookup)
        data = _attribute_dict(raw)
        nested_attributes = _attribute_dict(_dict_get_any(data, (attributes_key, string(attributes_key)), Dict{String, Any}()))
        return (
            source=string(source_mapper(Graphs.src(edge))),
            target=string(target_mapper(Graphs.dst(edge))),
            id=_dict_get_any(data, id_keys, nothing),
            label=_dict_get_any(data, label_keys, nothing),
            color=_dict_get_any(data, color_keys, nothing),
            size=_dict_get_any(data, size_keys, 1.0),
            attributes=nested_attributes,
        )
    end
    mapper
end

function _timed_stage(f::Function)
    started = time_ns()
    value = f()
    elapsed_seconds = (time_ns() - started) / 1.0e9
    value, elapsed_seconds
end

"""
    timed_layout(nodes, edges; layout=nothing, layout_kwargs...)

Run `layout_graph` and return the result plus elapsed time in seconds.
"""
function timed_layout(nodes, edges; layout=nothing, layout_kwargs...)
    result, elapsed_seconds = _timed_stage(() -> layout_graph(nodes, edges; layout=layout, layout_kwargs...))
    (stage=:layout, seconds=elapsed_seconds, result=result)
end

"""
    timed_assemble(nodes, edges; kwargs...)
    timed_assemble(layouted; kwargs...)

Run `assemble_graph` and return the result plus elapsed time in seconds.
"""
function timed_assemble(nodes, edges; kwargs...)
    result, elapsed_seconds = _timed_stage(() -> assemble_graph(nodes, edges; kwargs...))
    (stage=:assemble, seconds=elapsed_seconds, result=result)
end

function timed_assemble(layouted::NamedTuple; kwargs...)
    result, elapsed_seconds = _timed_stage(() -> assemble_graph(layouted; kwargs...))
    (stage=:assemble, seconds=elapsed_seconds, result=result)
end

"""
    timed_render(nodes, edges; kwargs...)
    timed_render(g::Graphs.AbstractGraph; kwargs...)

Run `render` and return the result plus elapsed time in seconds.
"""
function timed_render(nodes, edges; kwargs...)
    result, elapsed_seconds = _timed_stage(() -> render(nodes, edges; kwargs...))
    (stage=:render, seconds=elapsed_seconds, result=result)
end

function timed_render(g::Graphs.AbstractGraph; kwargs...)
    result, elapsed_seconds = _timed_stage(() -> render(g; kwargs...))
    (stage=:render, seconds=elapsed_seconds, result=result)
end

"""
    timed_export(path, graph::SigmaGraph; kwargs...)
    timed_export(path, nodes, edges; kwargs...)

Run `savehtml` and return the output path plus elapsed time in seconds.
"""
function timed_export(path::AbstractString, value::SigmaGraph; kwargs...)
    result, elapsed_seconds = _timed_stage(() -> savehtml(path, value; kwargs...))
    (stage=:export, seconds=elapsed_seconds, result=result)
end

function timed_export(path::AbstractString, nodes, edges; kwargs...)
    result, elapsed_seconds = _timed_stage(() -> savehtml(path, nodes, edges; kwargs...))
    (stage=:export, seconds=elapsed_seconds, result=result)
end

"""
    profile_pipeline(nodes, edges; layout=nothing, layout_kwargs=NamedTuple(), assemble_kwargs=NamedTuple(), render_kwargs=NamedTuple(), export_path=nothing, export_kwargs=NamedTuple())

Run a staged pipeline and capture timings for layout, assemble, render, and optional export.
"""
function profile_pipeline(
    nodes,
    edges;
    layout=nothing,
    layout_kwargs=NamedTuple(),
    assemble_kwargs=NamedTuple(),
    render_kwargs=NamedTuple(),
    export_path=nothing,
    export_kwargs=NamedTuple(),
)
    layout_stage = timed_layout(nodes, edges; layout=layout, pairs(layout_kwargs)...)
    assemble_stage = timed_assemble(layout_stage.result; pairs(assemble_kwargs)...)
    render_stage = timed_render(nodes, edges; layout=layout, pairs(layout_kwargs)..., pairs(render_kwargs)...)
    export_stage = isnothing(export_path) ? nothing : timed_export(string(export_path), render_stage.result; pairs(export_kwargs)...)
    timings = Dict{Symbol, Float64}(
        :layout => layout_stage.seconds,
        :assemble => assemble_stage.seconds,
        :render => render_stage.seconds,
    )
    !isnothing(export_stage) && (timings[:export] = export_stage.seconds)
    (
        timings=timings,
        layout=layout_stage,
        assemble=assemble_stage,
        render=render_stage,
        export_stage=export_stage,
    )
end
