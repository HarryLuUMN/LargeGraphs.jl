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
