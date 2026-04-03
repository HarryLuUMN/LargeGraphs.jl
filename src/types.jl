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
The `runtime` field stores the requested browser runtime (`:auto`, `:sigma`,
`:webgpu`, or `:offline_canvas`).
"""
struct SigmaGraph
    id::String
    nodes::Vector{NodeSpec}
    edges::Vector{EdgeSpec}
    config::SigmaConfig
    runtime::Symbol
    interaction::Dict{String, Any}
end

SigmaGraph(id, nodes, edges, config) = SigmaGraph(string(id), nodes, edges, config, :auto, Dict{String, Any}())
SigmaGraph(id, nodes, edges, config, interaction::Dict{String, Any}) = SigmaGraph(string(id), nodes, edges, config, :auto, interaction)

const _RUNTIME_OPTIONS = (:auto, :sigma, :webgpu, :offline_canvas)

function _normalize_runtime(runtime)
    normalized = runtime isa Symbol ? runtime : Symbol(lowercase(string(runtime)))
    normalized in _RUNTIME_OPTIONS && return normalized
    supported = join(string.(collect(_RUNTIME_OPTIONS)), ", ")
    throw(ArgumentError("Unknown runtime: $(repr(runtime)). Supported runtimes: $(supported)."))
end

const _SIGMA_PROFILES = Dict{Symbol, NamedTuple{(:camera_ratio, :render_edge_labels, :hide_edges_on_move, :label_density, :label_grid_cell_size, :max_node_size, :min_node_size), Tuple{Float64, Bool, Bool, Float64, Int, Float64, Float64}}}(
    :default => (
        camera_ratio=1.0,
        render_edge_labels=false,
        hide_edges_on_move=false,
        label_density=1.0,
        label_grid_cell_size=80,
        max_node_size=16.0,
        min_node_size=2.0,
    ),
    :dense => (
        camera_ratio=1.0,
        render_edge_labels=false,
        hide_edges_on_move=true,
        label_density=0.6,
        label_grid_cell_size=96,
        max_node_size=12.0,
        min_node_size=1.5,
    ),
    :large => (
        camera_ratio=1.0,
        render_edge_labels=false,
        hide_edges_on_move=true,
        label_density=0.35,
        label_grid_cell_size=120,
        max_node_size=9.0,
        min_node_size=1.0,
    ),
    :presentation => (
        camera_ratio=0.9,
        render_edge_labels=true,
        hide_edges_on_move=false,
        label_density=1.2,
        label_grid_cell_size=72,
        max_node_size=20.0,
        min_node_size=2.5,
    ),
)

function _normalize_profile(profile)
    normalized = profile isa Symbol ? profile : Symbol(lowercase(string(profile)))
    normalized === :auto && return :auto
    haskey(_SIGMA_PROFILES, normalized) && return normalized
    supported = join(sort!(collect(string(key) for key in keys(_SIGMA_PROFILES))), ", ")
    throw(ArgumentError("Unknown profile: $(repr(profile)). Supported profiles: $(supported), auto."))
end

function _recommended_profile(node_count::Integer, edge_count::Integer)
    nodes = max(Int(node_count), 0)
    edges = max(Int(edge_count), 0)
    density = nodes == 0 ? 0.0 : edges / nodes
    (nodes >= 1_200 || edges >= 6_000 || (nodes >= 600 && density >= 8.0)) && return :large
    (nodes >= 400 || edges >= 1_500 || (nodes >= 250 && density >= 5.0)) && return :dense
    :default
end

function _resolve_profile(profile, node_count::Integer, edge_count::Integer)
    normalized = _normalize_profile(profile)
    normalized === :auto ? _recommended_profile(node_count, edge_count) : normalized
end

_profile_settings(profile, node_count::Integer=0, edge_count::Integer=0) = _SIGMA_PROFILES[_resolve_profile(profile, node_count, edge_count)]

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

function SigmaConfig(;
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
    settings = _profile_settings(profile, node_count, edge_count)
    SigmaConfig(
        string(isnothing(width) ? "100%" : width),
        string(isnothing(height) ? "700px" : height),
        string(isnothing(background) ? "#ffffff" : background),
        Float64(isnothing(camera_ratio) ? settings.camera_ratio : camera_ratio),
        Bool(isnothing(render_edge_labels) ? settings.render_edge_labels : render_edge_labels),
        Bool(isnothing(hide_edges_on_move) ? settings.hide_edges_on_move : hide_edges_on_move),
        Float64(isnothing(label_density) ? settings.label_density : label_density),
        Int(isnothing(label_grid_cell_size) ? settings.label_grid_cell_size : label_grid_cell_size),
        Float64(isnothing(max_node_size) ? settings.max_node_size : max_node_size),
        Float64(isnothing(min_node_size) ? settings.min_node_size : min_node_size),
    )
end
