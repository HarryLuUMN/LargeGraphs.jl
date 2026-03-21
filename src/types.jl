"""
    NodeSpec(id; x=0.0, y=0.0, size=1.0, label=nothing, color=nothing, attributes=Dict())

Node specification for a Sigma graph.

`id` is required. Remaining fields control layout, labeling, styling, and any
additional Sigma-compatible node attributes.
"""
struct NodeSpec
    id::String
    x::Float64
    y::Float64
    size::Float64
    label::Union{Nothing, String}
    color::Union{Nothing, String}
    attributes::Dict{String, Any}
end

"""
    EdgeSpec(source, target; id=nothing, size=1.0, label=nothing, color=nothing, attributes=Dict())

Edge specification for a Sigma graph.

If `id` is omitted, a UUID-backed edge key is generated automatically.
"""
struct EdgeSpec
    id::String
    source::String
    target::String
    size::Float64
    label::Union{Nothing, String}
    color::Union{Nothing, String}
    attributes::Dict{String, Any}
end

"""
    SigmaConfig(; kwargs...)

Rendering configuration for a `SigmaGraph`.

The default settings target notebook output and moderately large graphs while
allowing callers to tune viewport size, background color, label density, and
node sizing behavior.
"""
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

"""
    SigmaGraph

Normalized graph object used by `LargeGraphs` for HTML rendering and export.
"""
struct SigmaGraph
    id::String
    nodes::Vector{NodeSpec}
    edges::Vector{EdgeSpec}
    config::SigmaConfig
    interaction::Dict{String, Any}
end

SigmaGraph(id, nodes, edges, config) = SigmaGraph(string(id), nodes, edges, config, Dict{String, Any}())

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
