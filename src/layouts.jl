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
