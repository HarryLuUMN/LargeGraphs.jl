"""
    LargeGraphsJL

Render interactive Sigma.js graph visualizations from Julia data structures,
with notebook-friendly HTML output and standalone HTML export.
"""
module LargeGraphsJL

using JSON3
using Random
using UUIDs

export EdgeSpec, NodeSpec, SigmaConfig, SigmaGraph, circular_layout, force_directed_layout, graph, grid_layout, random_layout, render, savehtml, spring_layout

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

Normalized graph object used by `LargeGraphsJL` for HTML rendering and export.
"""
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

"""
    random_layout(nodes; seed=nothing, extent=1.0)
    random_layout(nodes, edges; seed=nothing, extent=1.0)

Assign random coordinates to each node.
"""
function random_layout(nodes; kwargs...)
    _random_layout(_normalize_nodes(nodes); kwargs...)
end

function random_layout(nodes, edges; kwargs...)
    random_layout(nodes; kwargs...)
end

"""
    circular_layout(nodes; radius=1.0, start_angle=0.0)
    circular_layout(nodes, edges; radius=1.0, start_angle=0.0)

Place nodes evenly on a circle in input order.
"""
function circular_layout(nodes; kwargs...)
    _circular_layout(_normalize_nodes(nodes); kwargs...)
end

function circular_layout(nodes, edges; kwargs...)
    circular_layout(nodes; kwargs...)
end

"""
    grid_layout(nodes; columns=nothing, spacing=1.0)
    grid_layout(nodes, edges; columns=nothing, spacing=1.0)

Place nodes on a centered rectangular grid.
"""
function grid_layout(nodes; kwargs...)
    _grid_layout(_normalize_nodes(nodes); kwargs...)
end

function grid_layout(nodes, edges; kwargs...)
    grid_layout(nodes; kwargs...)
end

"""
    force_directed_layout(nodes, edges; algorithm=:fruchterman_reingold, kwargs...)

Compute a lightweight force-directed layout from the graph structure.

Supported algorithms:
- `:fruchterman_reingold` (same core as `spring_layout`)
- `:kamada_kawai`
- `:forceatlas2`
"""
function force_directed_layout(nodes, edges; algorithm=:fruchterman_reingold, kwargs...)
    _force_directed_layout(_normalize_nodes(nodes), _normalize_edges(edges); algorithm=algorithm, kwargs...)
end

"""
    spring_layout(nodes, edges; iterations=100, seed=nothing, extent=1.0, gravity=0.05, cooling=0.9)

Compatibility wrapper for Fruchterman-Reingold force-directed layout.
"""
function spring_layout(nodes, edges; kwargs...)
    force_directed_layout(nodes, edges; algorithm=:fruchterman_reingold, kwargs...)
end

"""
    savehtml(path, graph::SigmaGraph)
    savehtml(path, nodes, edges; kwargs...)

Write a standalone HTML document containing the graph viewer.
"""
function savehtml(path::AbstractString, value::SigmaGraph)
    open(path, "w") do io
        write(io, _standalone_html(value))
    end
    path
end

function savehtml(path::AbstractString, nodes, edges; kwargs...)
    savehtml(path, render(nodes, edges; kwargs...))
end

function Base.show(io::IO, ::MIME"text/html", value::SigmaGraph)
    print(io, _html(value))
end

function Base.show(io::IO, ::MIME"text/plain", value::SigmaGraph)
    print(io, "SigmaGraph($(length(value.nodes)) nodes, $(length(value.edges)) edges)")
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
        _required_get(value, :id, "Node tuples must define :id");
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
        _required_get(value, :source, "Edge tuples must define :source"),
        _required_get(value, :target, "Edge tuples must define :target");
        id=get(value, :id, nothing),
        size=get(value, :size, 1.0),
        label=get(value, :label, nothing),
        color=get(value, :color, nothing),
        attributes=get(value, :attributes, Dict{String, Any}()),
    )
end

function _node(value::AbstractDict)
    NodeSpec(
        _coalesce_keys(value, "id", :id, "Node dicts must define id");
        x=_coalesce_keys(value, "x", :x, 0.0),
        y=_coalesce_keys(value, "y", :y, 0.0),
        size=_coalesce_keys(value, "size", :size, 1.0),
        label=_coalesce_keys(value, "label", :label, nothing),
        color=_coalesce_keys(value, "color", :color, nothing),
        attributes=_coalesce_keys(value, "attributes", :attributes, Dict{String, Any}()),
    )
end

function _edge(value::AbstractDict)
    EdgeSpec(
        _coalesce_keys(value, "source", :source, "Edge dicts must define source"),
        _coalesce_keys(value, "target", :target, "Edge dicts must define target");
        id=_coalesce_keys(value, "id", :id, nothing),
        size=_coalesce_keys(value, "size", :size, 1.0),
        label=_coalesce_keys(value, "label", :label, nothing),
        color=_coalesce_keys(value, "color", :color, nothing),
        attributes=_coalesce_keys(value, "attributes", :attributes, Dict{String, Any}()),
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

function _apply_layout(nodes::Vector{NodeSpec}, edges::Vector{EdgeSpec}, layout; layout_kwargs...)
    isnothing(layout) && return nodes
    layout_function = _resolve_layout(layout)
    _normalize_nodes(layout_function(nodes, edges; layout_kwargs...))
end

function _resolve_layout(layout::Symbol)
    layout === :random && return random_layout
    layout === :circular && return circular_layout
    layout === :grid && return grid_layout
    layout === :spring && return spring_layout
    layout === :force_directed && return force_directed_layout
    error("Unsupported layout symbol: $(layout)")
end

_resolve_layout(layout::AbstractString) = _resolve_layout(Symbol(layout))
_resolve_layout(layout::Function) = layout

function _random_layout(nodes::Vector{NodeSpec}; seed=nothing, extent=1.0)
    rng = _layout_rng(seed)
    positioned = Vector{NodeSpec}(undef, length(nodes))
    for (index, node) in pairs(nodes)
        positioned[index] = _with_position(
            node,
            extent * (2.0 * rand(rng) - 1.0),
            extent * (2.0 * rand(rng) - 1.0),
        )
    end
    positioned
end

function _circular_layout(nodes::Vector{NodeSpec}; radius=1.0, start_angle=0.0)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    positioned = Vector{NodeSpec}(undef, count)
    for (index, node) in pairs(nodes)
        angle = start_angle + 2pi * (index - 1) / count
        positioned[index] = _with_position(node, radius * cos(angle), radius * sin(angle))
    end
    positioned
end

function _grid_layout(nodes::Vector{NodeSpec}; columns=nothing, spacing=1.0)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    column_count = isnothing(columns) ? ceil(Int, sqrt(count)) : max(1, Int(columns))
    row_count = ceil(Int, count / column_count)
    x_offset = spacing * (column_count - 1) / 2
    y_offset = spacing * (row_count - 1) / 2
    positioned = Vector{NodeSpec}(undef, count)
    for (index, node) in pairs(nodes)
        slot = index - 1
        col = slot % column_count
        row = slot ÷ column_count
        positioned[index] = _with_position(
            node,
            spacing * col - x_offset,
            y_offset - spacing * row,
        )
    end
    positioned
end

function _force_directed_layout(nodes::Vector{NodeSpec}, edges::Vector{EdgeSpec}; algorithm=:fruchterman_reingold, kwargs...)
    selected = _force_directed_algorithm(algorithm)
    selected === :fruchterman_reingold && return _fruchterman_reingold_layout(nodes, edges; kwargs...)
    selected === :kamada_kawai && return _kamada_kawai_layout(nodes, edges; kwargs...)
    selected === :forceatlas2 && return _forceatlas2_layout(nodes, edges; kwargs...)
    error("Unsupported force-directed algorithm: $(algorithm)")
end

function _force_directed_algorithm(algorithm::Symbol)
    algorithm === :fruchterman_reingold && return :fruchterman_reingold
    algorithm === :spring && return :fruchterman_reingold
    algorithm === :kamada_kawai && return :kamada_kawai
    algorithm === :forceatlas2 && return :forceatlas2
    algorithm === :force_atlas2 && return :forceatlas2
    error("Unsupported force-directed algorithm: $(algorithm)")
end

_force_directed_algorithm(algorithm::AbstractString) = _force_directed_algorithm(Symbol(lowercase(strip(algorithm))))

function _fruchterman_reingold_layout(nodes::Vector{NodeSpec}, edges::Vector{EdgeSpec}; iterations=100, seed=nothing, extent=1.0, gravity=0.05, cooling=0.9)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    count == 1 && return [_with_position(only(nodes), 0.0, 0.0)]
    xs, ys = _initial_positions(nodes; seed=seed, extent=extent)
    indexed_edges = _edge_indices(nodes, edges)
    area = max(extent^2, 1.0)
    optimal_distance = sqrt(area / count)
    temperature = max(extent, 1.0)
    disp_x = zeros(Float64, count)
    disp_y = zeros(Float64, count)

    for _ in 1:max(1, Int(iterations))
        fill!(disp_x, 0.0)
        fill!(disp_y, 0.0)

        for i in 1:(count - 1)
            for j in (i + 1):count
                dx = xs[i] - xs[j]
                dy = ys[i] - ys[j]
                distance = max(sqrt(dx * dx + dy * dy), 1.0e-9)
                force = optimal_distance^2 / distance
                fx = dx / distance * force
                fy = dy / distance * force
                disp_x[i] += fx
                disp_y[i] += fy
                disp_x[j] -= fx
                disp_y[j] -= fy
            end
        end

        for (source, target) in indexed_edges
            dx = xs[source] - xs[target]
            dy = ys[source] - ys[target]
            distance = max(sqrt(dx * dx + dy * dy), 1.0e-9)
            force = distance^2 / optimal_distance
            fx = dx / distance * force
            fy = dy / distance * force
            disp_x[source] -= fx
            disp_y[source] -= fy
            disp_x[target] += fx
            disp_y[target] += fy
        end

        for i in 1:count
            disp_x[i] -= gravity * xs[i]
            disp_y[i] -= gravity * ys[i]
            distance = sqrt(disp_x[i]^2 + disp_y[i]^2)
            if distance > 0.0
                step = min(distance, temperature)
                xs[i] += disp_x[i] / distance * step
                ys[i] += disp_y[i] / distance * step
            end
        end

        temperature *= cooling
    end

    xs, ys = _rescale_positions(xs, ys; extent=extent)
    [_with_position(node, xs[index], ys[index]) for (index, node) in pairs(nodes)]
end

function _kamada_kawai_layout(
    nodes::Vector{NodeSpec},
    edges::Vector{EdgeSpec};
    iterations=150,
    seed=nothing,
    extent=1.0,
    stiffness=1.0,
    learning_rate=0.08,
    gravity=0.01,
    repulsion=0.01,
    max_step=0.25,
)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    count == 1 && return [_with_position(only(nodes), 0.0, 0.0)]

    xs, ys = _initial_positions(nodes; seed=seed, extent=extent)
    distances = _all_pairs_shortest_paths(nodes, edges)
    finite_distances = [distances[i, j] for i in 1:count for j in 1:count if i != j && isfinite(distances[i, j])]
    diameter = isempty(finite_distances) ? 1.0 : max(maximum(finite_distances), 1.0)
    target_scale = (2 * extent) / diameter

    ideal = Matrix{Float64}(undef, count, count)
    spring = Matrix{Float64}(undef, count, count)
    for i in 1:count
        for j in 1:count
            if i == j
                ideal[i, j] = 0.0
                spring[i, j] = 0.0
                continue
            end
            d = distances[i, j]
            if !isfinite(d)
                d = diameter
            end
            d = max(d, 1.0e-9)
            ideal[i, j] = target_scale * d
            spring[i, j] = stiffness / (d * d)
        end
    end

    for _ in 1:max(1, Int(iterations))
        for i in 1:count
            fx = 0.0
            fy = 0.0
            xi = xs[i]
            yi = ys[i]
            for j in 1:count
                i == j && continue
                dx = xi - xs[j]
                dy = yi - ys[j]
                distance = max(sqrt(dx * dx + dy * dy), 1.0e-9)
                spring_force = spring[i, j] * (1.0 - ideal[i, j] / distance)
                fx += spring_force * dx
                fy += spring_force * dy
                repel = repulsion / (distance * distance)
                fx += dx * repel
                fy += dy * repel
            end
            fx += gravity * xi
            fy += gravity * yi
            step = min(max_step, learning_rate * sqrt(fx * fx + fy * fy))
            if step > 0.0
                invnorm = 1.0 / max(sqrt(fx * fx + fy * fy), 1.0e-9)
                xs[i] -= fx * invnorm * step
                ys[i] -= fy * invnorm * step
            end
        end
    end

    xs, ys = _rescale_positions(xs, ys; extent=extent)
    [_with_position(node, xs[index], ys[index]) for (index, node) in pairs(nodes)]
end

function _forceatlas2_layout(
    nodes::Vector{NodeSpec},
    edges::Vector{EdgeSpec};
    iterations=200,
    seed=nothing,
    extent=1.0,
    scaling=1.0,
    gravity=0.05,
    damping=0.85,
    linlog=false,
)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    count == 1 && return [_with_position(only(nodes), 0.0, 0.0)]

    xs, ys = _initial_positions(nodes; seed=seed, extent=extent)
    indexed_edges = _edge_indices(nodes, edges)
    degree = zeros(Float64, count)
    for (source, target) in indexed_edges
        degree[source] += 1.0
        degree[target] += 1.0
    end

    velocity_x = zeros(Float64, count)
    velocity_y = zeros(Float64, count)
    force_x = zeros(Float64, count)
    force_y = zeros(Float64, count)

    for _ in 1:max(1, Int(iterations))
        fill!(force_x, 0.0)
        fill!(force_y, 0.0)

        for i in 1:(count - 1)
            for j in (i + 1):count
                dx = xs[i] - xs[j]
                dy = ys[i] - ys[j]
                distance = max(sqrt(dx * dx + dy * dy), 1.0e-9)
                force = scaling * (degree[i] + 1.0) * (degree[j] + 1.0) / distance
                fx = dx / distance * force
                fy = dy / distance * force
                force_x[i] += fx
                force_y[i] += fy
                force_x[j] -= fx
                force_y[j] -= fy
            end
        end

        for (source, target) in indexed_edges
            dx = xs[source] - xs[target]
            dy = ys[source] - ys[target]
            distance = max(sqrt(dx * dx + dy * dy), 1.0e-9)
            force = linlog ? log1p(distance) : distance
            fx = dx / distance * force
            fy = dy / distance * force
            force_x[source] -= fx
            force_y[source] -= fy
            force_x[target] += fx
            force_y[target] += fy
        end

        for i in 1:count
            force_x[i] -= gravity * (degree[i] + 1.0) * xs[i]
            force_y[i] -= gravity * (degree[i] + 1.0) * ys[i]
            velocity_x[i] = damping * velocity_x[i] + (1.0 - damping) * force_x[i]
            velocity_y[i] = damping * velocity_y[i] + (1.0 - damping) * force_y[i]
            xs[i] += velocity_x[i]
            ys[i] += velocity_y[i]
        end
    end

    xs, ys = _rescale_positions(xs, ys; extent=extent)
    [_with_position(node, xs[index], ys[index]) for (index, node) in pairs(nodes)]
end

function _layout_rng(seed)
    isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
end

function _with_position(node::NodeSpec, x, y)
    NodeSpec(
        node.id;
        x=x,
        y=y,
        size=node.size,
        label=node.label,
        color=node.color,
        attributes=copy(node.attributes),
    )
end

function _initial_positions(nodes::Vector{NodeSpec}; seed=nothing, extent=1.0)
    xs = [node.x for node in nodes]
    ys = [node.y for node in nodes]
    spread = (maximum(xs) - minimum(xs)) + (maximum(ys) - minimum(ys))
    if spread > 0.0
        return xs, ys
    end
    positioned = _random_layout(nodes; seed=seed, extent=extent)
    [node.x for node in positioned], [node.y for node in positioned]
end

function _edge_indices(nodes::Vector{NodeSpec}, edges::Vector{EdgeSpec})
    node_index = Dict(node.id => index for (index, node) in pairs(nodes))
    indexed = Tuple{Int, Int}[]
    for edge in edges
        source = get(node_index, edge.source, 0)
        target = get(node_index, edge.target, 0)
        source == 0 && continue
        target == 0 && continue
        source == target && continue
        push!(indexed, (source, target))
    end
    indexed
end

function _all_pairs_shortest_paths(nodes::Vector{NodeSpec}, edges::Vector{EdgeSpec})
    count = length(nodes)
    distances = fill(Inf, count, count)
    for i in 1:count
        distances[i, i] = 0.0
    end

    for (source, target) in _edge_indices(nodes, edges)
        distances[source, target] = 1.0
        distances[target, source] = 1.0
    end

    for k in 1:count
        for i in 1:count
            dik = distances[i, k]
            !isfinite(dik) && continue
            for j in 1:count
                candidate = dik + distances[k, j]
                candidate < distances[i, j] && (distances[i, j] = candidate)
            end
        end
    end

    distances
end

function _rescale_positions(xs::Vector{Float64}, ys::Vector{Float64}; extent=1.0)
    min_x, max_x = extrema(xs)
    min_y, max_y = extrema(ys)
    span_x = max_x - min_x
    span_y = max_y - min_y
    span = max(span_x, span_y)
    span == 0.0 && return fill(0.0, length(xs)), fill(0.0, length(ys))
    x_center = (max_x + min_x) / 2
    y_center = (max_y + min_y) / 2
    scale = 2 * extent / span
    (
        [(x - x_center) * scale for x in xs],
        [(y - y_center) * scale for y in ys],
    )
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

function _required_get(value::NamedTuple, key::Symbol, message::AbstractString)
    haskey(value, key) || error(message)
    getfield(value, key)
end

function _coalesce_keys(value::AbstractDict, primary, secondary, default)
    if haskey(value, primary)
        return value[primary]
    end
    if haskey(value, secondary)
        return value[secondary]
    end
    default isa AbstractString && occursin("must define", default) && error(default)
    default
end

end
