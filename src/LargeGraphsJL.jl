module LargeGraphsJL

using JSON3
using UUIDs

export EdgeSpec, NodeSpec, SigmaConfig, SigmaGraph, graph, render, savehtml

struct NodeSpec
    id::String
    x::Float64
    y::Float64
    size::Float64
    label::Union{Nothing, String}
    color::Union{Nothing, String}
    attributes::Dict{String, Any}
end

struct EdgeSpec
    id::String
    source::String
    target::String
    size::Float64
    label::Union{Nothing, String}
    color::Union{Nothing, String}
    attributes::Dict{String, Any}
end

struct SigmaConfig
    width::String
    height::String
    background::String
    camera_ratio::Float64
    render_edge_labels::Bool
    hide_edges_on_move::Bool
    label_density::Float64
    label_grid_cell_size::Int
    max_node_size::Float64
    min_node_size::Float64
end

struct SigmaGraph
    id::String
    nodes::Vector{NodeSpec}
    edges::Vector{EdgeSpec}
    config::SigmaConfig
end

NodeSpec(id; x=0.0, y=0.0, size=1.0, label=nothing, color=nothing, attributes=Dict{String, Any}()) =
    NodeSpec(string(id), Float64(x), Float64(y), Float64(size), _string_or_nothing(label), _string_or_nothing(color), Dict{String, Any}(string(k) => v for (k, v) in pairs(attributes)))

EdgeSpec(source, target; id=nothing, size=1.0, label=nothing, color=nothing, attributes=Dict{String, Any}()) =
    EdgeSpec(
        isnothing(id) ? string(uuid4()) : string(id),
        string(source),
        string(target),
        Float64(size),
        _string_or_nothing(label),
        _string_or_nothing(color),
        Dict{String, Any}(string(k) => v for (k, v) in pairs(attributes)),
    )

SigmaConfig(;
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
) = SigmaConfig(
    string(width),
    string(height),
    string(background),
    Float64(camera_ratio),
    Bool(render_edge_labels),
    Bool(hide_edges_on_move),
    Float64(label_density),
    Int(label_grid_cell_size),
    Float64(max_node_size),
    Float64(min_node_size),
)

function graph(nodes, edges; id=string("sigma-", uuid4()), config=SigmaConfig())
    SigmaGraph(string(id), _normalize_nodes(nodes), _normalize_edges(edges), config)
end

function render(nodes, edges; kwargs...)
    graph(nodes, edges; kwargs...)
end

function savehtml(path::AbstractString, value::SigmaGraph)
    open(path, "w") do io
        write(io, _standalone_html(value))
    end
    path
end

function Base.show(io::IO, ::MIME"text/html", value::SigmaGraph)
    print(io, _html(value))
end

function _normalize_nodes(nodes)
    result = NodeSpec[]
    for item in nodes
        push!(result, _node(item))
    end
    result
end

function _normalize_edges(edges)
    result = EdgeSpec[]
    for item in edges
        push!(result, _edge(item))
    end
    result
end

_node(value::NodeSpec) = value
_edge(value::EdgeSpec) = value

function _node(value::NamedTuple)
    NodeSpec(
        get(value, :id, error("Node tuples must define :id"));
        x=get(value, :x, 0.0),
        y=get(value, :y, 0.0),
        size=get(value, :size, 1.0),
        label=get(value, :label, nothing),
        color=get(value, :color, nothing),
        attributes=get(value, :attributes, Dict{String, Any}()),
    )
end

function _edge(value::NamedTuple)
    EdgeSpec(
        get(value, :source, error("Edge tuples must define :source")),
        get(value, :target, error("Edge tuples must define :target"));
        id=get(value, :id, nothing),
        size=get(value, :size, 1.0),
        label=get(value, :label, nothing),
        color=get(value, :color, nothing),
        attributes=get(value, :attributes, Dict{String, Any}()),
    )
end

function _node(value::AbstractDict)
    NodeSpec(
        get(value, "id", get(value, :id, error("Node dicts must define id")));
        x=get(value, "x", get(value, :x, 0.0)),
        y=get(value, "y", get(value, :y, 0.0)),
        size=get(value, "size", get(value, :size, 1.0)),
        label=get(value, "label", get(value, :label, nothing)),
        color=get(value, "color", get(value, :color, nothing)),
        attributes=get(value, "attributes", get(value, :attributes, Dict{String, Any}())),
    )
end

function _edge(value::AbstractDict)
    EdgeSpec(
        get(value, "source", get(value, :source, error("Edge dicts must define source"))),
        get(value, "target", get(value, :target, error("Edge dicts must define target")));
        id=get(value, "id", get(value, :id, nothing)),
        size=get(value, "size", get(value, :size, 1.0)),
        label=get(value, "label", get(value, :label, nothing)),
        color=get(value, "color", get(value, :color, nothing)),
        attributes=get(value, "attributes", get(value, :attributes, Dict{String, Any}())),
    )
end

function _node(value::Tuple)
    length(value) >= 3 || error("Tuple nodes must be (id, x, y, ...)")
    NodeSpec(value[1]; x=value[2], y=value[3], size=length(value) >= 4 ? value[4] : 1.0, label=length(value) >= 5 ? value[5] : nothing)
end

function _edge(value::Tuple)
    length(value) >= 2 || error("Tuple edges must be (source, target, ...)")
    EdgeSpec(value[1], value[2]; size=length(value) >= 3 ? value[3] : 1.0, label=length(value) >= 4 ? value[4] : nothing)
end

function _graph_payload(value::SigmaGraph)
    (
        id=value.id,
        nodes=[_node_payload(node) for node in value.nodes],
        edges=[_edge_payload(edge) for edge in value.edges],
        config=_config_payload(value.config),
    )
end

function _node_payload(node::NodeSpec)
    merge(
        Dict{String, Any}(
            "id" => node.id,
            "x" => node.x,
            "y" => node.y,
            "size" => node.size,
        ),
        isnothing(node.label) ? Dict{String, Any}() : Dict("label" => node.label),
        isnothing(node.color) ? Dict{String, Any}() : Dict("color" => node.color),
        node.attributes,
    )
end

function _edge_payload(edge::EdgeSpec)
    merge(
        Dict{String, Any}(
            "key" => edge.id,
            "source" => edge.source,
            "target" => edge.target,
            "size" => edge.size,
        ),
        isnothing(edge.label) ? Dict{String, Any}() : Dict("label" => edge.label),
        isnothing(edge.color) ? Dict{String, Any}() : Dict("color" => edge.color),
        edge.attributes,
    )
end

function _config_payload(config::SigmaConfig)
    Dict(
        "width" => config.width,
        "height" => config.height,
        "background" => config.background,
        "cameraRatio" => config.camera_ratio,
        "renderEdgeLabels" => config.render_edge_labels,
        "hideEdgesOnMove" => config.hide_edges_on_move,
        "labelDensity" => config.label_density,
        "labelGridCellSize" => config.label_grid_cell_size,
        "maxNodeSize" => config.max_node_size,
        "minNodeSize" => config.min_node_size,
    )
end

function _html(value::SigmaGraph)
    payload = JSON3.write(_graph_payload(value))
    bootstrap = read(joinpath(pkgdir(@__MODULE__), "assets", "sigma-viewer.js"), String)
    """
    <div id="$(value.id)" class="large-graphs-jl-root" style="width: $(value.config.width);">
      <div class="large-graphs-jl-stage" style="width: 100%; height: $(value.config.height); background: $(value.config.background);"></div>
    </div>
    <script type="application/json" id="$(value.id)-payload">$(payload)</script>
    <script>
    $(bootstrap)
    window.LargeGraphsJL.render("$(value.id)");
    </script>
    """
end

function _standalone_html(value::SigmaGraph)
    """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>LargeGraphsJL Demo</title>
    </head>
    <body>
    $(_html(value))
    </body>
    </html>
    """
end

_string_or_nothing(value::Nothing) = nothing
_string_or_nothing(value) = string(value)

end
