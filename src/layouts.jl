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
    orthogonal_layout(nodes, edges; extent=1.0, layer_spacing=1.0, component_spacing=2.0)

Place nodes on a grid using a breadth-first spanning forest with alternating
horizontal and vertical levels.
"""
function orthogonal_layout(nodes, edges; kwargs...)
    _orthogonal_layout(_normalize_nodes(nodes), _normalize_edges(edges); kwargs...)
end

"""
    spectral_layout(nodes, edges; extent=1.0, jitter=1.0e-6, seed=nothing)

Compute a spectral embedding from the graph Laplacian.
"""
function spectral_layout(nodes, edges; kwargs...)
    _spectral_layout(_normalize_nodes(nodes), _normalize_edges(edges); kwargs...)
end

"""
    tree_layout(nodes, edges; algorithm=:layered, root=nothing, level_gap=1.0, sibling_gap=1.0, extent=1.0)

Compute a tree-oriented layout for rooted trees or forests.

Supported algorithms:
- `:layered`
- `:radial`
"""
function tree_layout(nodes, edges; algorithm=:layered, kwargs...)
    _tree_layout(_normalize_nodes(nodes), _normalize_edges(edges); algorithm=algorithm, kwargs...)
end

"""
    hierarchy_layout(nodes; parent_key=:parent, id_key=:id, algorithm=:layered, kwargs...)
    hierarchy_layout(nodes, edges; parent_key=:parent, id_key=:id, algorithm=:layered, kwargs...)

Compute a hierarchy layout from node-level parent references.
"""
function hierarchy_layout(nodes; parent_key=:parent, id_key=:id, algorithm=:layered, kwargs...)
    input_nodes = collect(nodes)
    normalized_nodes = _normalize_nodes(input_nodes)
    fallback_ids = [node.id for node in normalized_nodes]
    resolved_ids = [_hierarchy_node_id(input_nodes[index], id_key, fallback_ids[index]) for index in eachindex(input_nodes)]
    known_ids = Set(resolved_ids)
    hierarchy_edges = EdgeSpec[]
    for (index, item) in pairs(input_nodes)
        parent = _hierarchy_node_parent(item, parent_key)
        isnothing(parent) && continue
        parent_id = string(parent)
        parent_id in known_ids || continue
        push!(hierarchy_edges, EdgeSpec(parent_id, resolved_ids[index]))
    end
    _tree_layout(normalized_nodes, hierarchy_edges; algorithm=algorithm, kwargs...)
end

function hierarchy_layout(nodes, edges; kwargs...)
    hierarchy_layout(nodes; kwargs...)
end

"""
    force_directed_layout(nodes, edges; algorithm=:fruchterman_reingold, kwargs...)

Compute a lightweight force-directed layout from the graph structure.

Supported algorithms:
- `:fruchterman_reingold` (same core as `spring_layout`)
- `:kamada_kawai`
- `:forceatlas2`
- `:network_spring`
- `:sfdp`
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
    layout === :orthogonal && return orthogonal_layout
    layout === :spectral && return spectral_layout
    layout === :tree && return tree_layout
    layout === :hierarchy && return hierarchy_layout
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

function _orthogonal_layout(
    nodes::Vector{NodeSpec},
    edges::Vector{EdgeSpec};
    extent=1.0,
    layer_spacing=1.0,
    component_spacing=2.0,
)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    count == 1 && return [_with_position(only(nodes), 0.0, 0.0)]

    adjacency = [Int[] for _ in 1:count]
    for (source, target) in _edge_indices(nodes, edges)
        push!(adjacency[source], target)
        push!(adjacency[target], source)
    end
    for neighbors in adjacency
        sort!(neighbors)
    end

    xs = zeros(Float64, count)
    ys = zeros(Float64, count)
    visited = falses(count)
    component_order = sortperm([(-length(adjacency[index]), index) for index in 1:count])
    x_shift = 0.0

    for root in component_order
        visited[root] && continue
        component_nodes, levels = _orthogonal_component_levels(root, adjacency, visited)
        max_depth = maximum(levels[node] for node in component_nodes)

        for depth in 0:max_depth
            level_nodes = sort([node for node in component_nodes if levels[node] == depth]; by=node -> (-length(adjacency[node]), node))
            offsets = _orthogonal_offsets(length(level_nodes), layer_spacing)
            for (index, node) in pairs(level_nodes)
                if iseven(depth)
                    xs[node] = depth * layer_spacing
                    ys[node] = offsets[index]
                else
                    xs[node] = offsets[index]
                    ys[node] = -depth * layer_spacing
                end
            end
        end

        component_xs = xs[component_nodes]
        component_ys = ys[component_nodes]
        min_x, max_x = extrema(component_xs)
        min_y, max_y = extrema(component_ys)
        for node in component_nodes
            xs[node] += x_shift - min_x
            ys[node] -= (max_y + min_y) / 2
        end
        x_shift += (max_x - min_x) + component_spacing
    end

    xs, ys = _rescale_positions(xs, ys; extent=extent)
    [_with_position(node, xs[index], ys[index]) for (index, node) in pairs(nodes)]
end

function _orthogonal_component_levels(root, adjacency, visited)
    component_nodes = Int[]
    levels = fill(-1, length(adjacency))
    queue = [root]
    visited[root] = true
    levels[root] = 0
    head = 1

    while head <= length(queue)
        node = queue[head]
        head += 1
        push!(component_nodes, node)
        ordered_neighbors = sort(adjacency[node]; by=neighbor -> (-length(adjacency[neighbor]), neighbor))
        for neighbor in ordered_neighbors
            visited[neighbor] && continue
            visited[neighbor] = true
            levels[neighbor] = levels[node] + 1
            push!(queue, neighbor)
        end
    end

    component_nodes, levels
end

function _orthogonal_offsets(count, spacing)
    count == 0 && return Float64[]
    start = -spacing * (count - 1) / 2
    [start + spacing * (index - 1) for index in 1:count]
end

function _spectral_layout(nodes::Vector{NodeSpec}, edges::Vector{EdgeSpec}; extent=1.0, jitter=1.0e-6, seed=nothing)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    count == 1 && return [_with_position(only(nodes), 0.0, 0.0)]

    adjacency = zeros(Float64, count, count)
    for (source, target) in _edge_indices(nodes, edges)
        adjacency[source, target] += 1.0
        adjacency[target, source] += 1.0
    end

    degree = vec(sum(adjacency; dims=2))
    laplacian = Diagonal(degree) - adjacency
    eigenpairs = eigen(Symmetric(laplacian))
    order = sortperm(eigenpairs.values)

    x_index = length(order) >= 2 ? order[2] : order[1]
    y_index = length(order) >= 3 ? order[3] : order[min(2, length(order))]
    xs = collect(eigenpairs.vectors[:, x_index])
    ys = collect(eigenpairs.vectors[:, y_index])

    if x_index == y_index || maximum(abs, ys) <= eps(Float64)
        rng = _layout_rng(seed)
        ys = [jitter * (2.0 * rand(rng) - 1.0) + jitter * (i - (count + 1) / 2) for i in 1:count]
    end

    xs, ys = _rescale_positions(xs, ys; extent=extent)
    [_with_position(node, xs[index], ys[index]) for (index, node) in pairs(nodes)]
end

function _tree_layout(nodes::Vector{NodeSpec}, edges::Vector{EdgeSpec}; algorithm=:layered, kwargs...)
    selected = _tree_layout_algorithm(algorithm)
    selected === :layered && return _layered_tree_layout(nodes, edges; kwargs...)
    selected === :radial && return _radial_tree_layout(nodes, edges; kwargs...)
    error("Unsupported tree layout algorithm: $(algorithm)")
end

function _tree_layout_algorithm(algorithm::Symbol)
    algorithm === :layered && return :layered
    algorithm === :radial && return :radial
    error("Unsupported tree layout algorithm: $(algorithm)")
end

_tree_layout_algorithm(algorithm::AbstractString) = _tree_layout_algorithm(Symbol(lowercase(strip(algorithm))))

function _layered_tree_layout(
    nodes::Vector{NodeSpec},
    edges::Vector{EdgeSpec};
    root=nothing,
    orientation=:top_down,
    sort_children=:id,
    level_gap=1.0,
    sibling_gap=1.0,
    extent=1.0,
)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    count == 1 && return [_with_position(only(nodes), 0.0, 0.0)]

    structure = _tree_structure(nodes, edges; root=root, sort_children=sort_children)
    xs = zeros(Float64, count)
    ys = zeros(Float64, count)
    next_leaf_x = Ref(0.0)

    for root_index in structure.root_indices
        _assign_layered_tree_positions!(xs, ys, structure.children, structure.depths, root_index, next_leaf_x; level_gap=level_gap, sibling_gap=sibling_gap)
        next_leaf_x[] += sibling_gap
    end

    scaled_xs, scaled_ys = _rescale_positions(xs, ys; extent=extent)
    oriented_xs, oriented_ys = _apply_tree_orientation(scaled_xs, scaled_ys, orientation)
    [_with_position(node, oriented_xs[index], oriented_ys[index]) for (index, node) in pairs(nodes)]
end

function _assign_layered_tree_positions!(xs, ys, children, depths, node_index, next_leaf_x; level_gap=1.0, sibling_gap=1.0)
    child_indices = children[node_index]
    if isempty(child_indices)
        xs[node_index] = next_leaf_x[]
        next_leaf_x[] += sibling_gap
    else
        for child_index in child_indices
            _assign_layered_tree_positions!(xs, ys, children, depths, child_index, next_leaf_x; level_gap=level_gap, sibling_gap=sibling_gap)
        end
        xs[node_index] = (xs[first(child_indices)] + xs[last(child_indices)]) / 2
    end
    ys[node_index] = -depths[node_index] * level_gap
    nothing
end

function _radial_tree_layout(
    nodes::Vector{NodeSpec},
    edges::Vector{EdgeSpec};
    root=nothing,
    orientation=:top_down,
    sort_children=:id,
    level_gap=1.0,
    sibling_gap=1.0,
    extent=1.0,
)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    count == 1 && return [_with_position(only(nodes), 0.0, 0.0)]

    structure = _tree_structure(nodes, edges; root=root, sort_children=sort_children)
    linear_xs = zeros(Float64, count)
    next_leaf_x = Ref(0.0)
    for root_index in structure.root_indices
        _assign_radial_tree_order!(linear_xs, structure.children, root_index, next_leaf_x; sibling_gap=sibling_gap)
        next_leaf_x[] += sibling_gap
    end

    total_span = max(next_leaf_x[] - sibling_gap, sibling_gap)
    xs = zeros(Float64, count)
    ys = zeros(Float64, count)
    for index in 1:count
        depth = structure.depths[index]
        radius = depth * level_gap
        if radius == 0.0
            xs[index] = 0.0
            ys[index] = 0.0
            continue
        end
        angle = 2pi * linear_xs[index] / total_span
        xs[index] = radius * cos(angle)
        ys[index] = radius * sin(angle)
    end

    scaled_xs, scaled_ys = _rescale_positions(xs, ys; extent=extent)
    oriented_xs, oriented_ys = _apply_tree_orientation(scaled_xs, scaled_ys, orientation)
    [_with_position(node, oriented_xs[index], oriented_ys[index]) for (index, node) in pairs(nodes)]
end

function _assign_radial_tree_order!(linear_xs, children, node_index, next_leaf_x; sibling_gap=1.0)
    child_indices = children[node_index]
    if isempty(child_indices)
        linear_xs[node_index] = next_leaf_x[]
        next_leaf_x[] += sibling_gap
    else
        for child_index in child_indices
            _assign_radial_tree_order!(linear_xs, children, child_index, next_leaf_x; sibling_gap=sibling_gap)
        end
        linear_xs[node_index] = (linear_xs[first(child_indices)] + linear_xs[last(child_indices)]) / 2
    end
    nothing
end

function _tree_structure(nodes::Vector{NodeSpec}, edges::Vector{EdgeSpec}; root=nothing, sort_children=:id)
    count = length(nodes)
    node_index = Dict(node.id => index for (index, node) in pairs(nodes))
    undirected = [Int[] for _ in 1:count]
    children = [Int[] for _ in 1:count]
    indegree = zeros(Int, count)

    for edge in edges
        source = get(node_index, edge.source, 0)
        target = get(node_index, edge.target, 0)
        source == 0 && continue
        target == 0 && continue
        source == target && continue
        push!(undirected[source], target)
        push!(undirected[target], source)
        push!(children[source], target)
        indegree[target] += 1
    end

    root_index = _tree_root_index(root, node_index)
    root_candidates = Int[]
    if isnothing(root_index)
        for index in 1:count
            indegree[index] == 0 && push!(root_candidates, index)
        end
    else
        push!(root_candidates, root_index)
    end

    isempty(root_candidates) && push!(root_candidates, _fallback_tree_root(undirected, nodes))

    visited = falses(count)
    parent = fill(0, count)
    depths = fill(-1, count)
    ordered_roots = Int[]

    for candidate in root_candidates
        visited[candidate] && continue
        push!(ordered_roots, candidate)
        _orient_tree_component!(candidate, undirected, visited, parent, depths)
    end

    while true
        next_root = 0
        next_degree = -1
        for index in 1:count
            visited[index] && continue
            degree = length(undirected[index])
            if degree > next_degree
                next_root = index
                next_degree = degree
            end
        end
        next_root == 0 && break
        push!(ordered_roots, next_root)
        _orient_tree_component!(next_root, undirected, visited, parent, depths)
    end

    oriented_children = [Int[] for _ in 1:count]
    for index in 1:count
        parent[index] == 0 && continue
        push!(oriented_children[parent[index]], index)
    end
    for child_list in oriented_children
        _sort_tree_children!(child_list, nodes, undirected, sort_children)
    end

    (root_indices=ordered_roots, children=oriented_children, depths=depths)
end

function _sort_tree_children!(child_list, nodes, undirected, sort_children)
    sort_children === :input && return child_list
    if sort_children === :id
        sort!(child_list; by=index -> nodes[index].id)
        return child_list
    end
    if sort_children === :degree
        sort!(child_list; by=index -> (-length(undirected[index]), nodes[index].id))
        return child_list
    end
    if sort_children isa Function
        sort!(child_list; by=index -> sort_children(nodes[index]))
        return child_list
    end
    error("Unsupported sort_children option: $(sort_children)")
end

function _apply_tree_orientation(xs::Vector{Float64}, ys::Vector{Float64}, orientation)
    normalized = _normalize_tree_orientation(orientation)
    normalized === :top_down && return xs, ys
    normalized === :bottom_up && return xs, [-value for value in ys]
    normalized === :left_right && return [-ys[index] for index in eachindex(ys)], copy(xs)
    normalized === :right_left && return [ys[index] for index in eachindex(ys)], copy(xs)
    error("Unsupported tree orientation: $(orientation)")
end

function _normalize_tree_orientation(orientation::Symbol)
    aliases = Dict(
        :top_down => :top_down,
        :topdown => :top_down,
        :down => :top_down,
        :bottom_up => :bottom_up,
        :bottomup => :bottom_up,
        :up => :bottom_up,
        :left_right => :left_right,
        :leftright => :left_right,
        :right_left => :right_left,
        :rightleft => :right_left,
    )
    haskey(aliases, orientation) && return aliases[orientation]
    error("Unsupported tree orientation: $(orientation)")
end

_normalize_tree_orientation(orientation::AbstractString) = _normalize_tree_orientation(Symbol(lowercase(strip(orientation))))

function _hierarchy_node_parent(item, parent_key)
    key_symbol = Symbol(parent_key)
    item isa NamedTuple && return haskey(item, key_symbol) ? getfield(item, key_symbol) : nothing
    if item isa AbstractDict
        haskey(item, parent_key) && return item[parent_key]
        haskey(item, key_symbol) && return item[key_symbol]
        return nothing
    end
    nothing
end

function _hierarchy_node_id(item, id_key, fallback)
    key_symbol = Symbol(id_key)
    item isa NamedTuple && return haskey(item, key_symbol) ? string(getfield(item, key_symbol)) : string(fallback)
    if item isa AbstractDict
        haskey(item, id_key) && return string(item[id_key])
        haskey(item, key_symbol) && return string(item[key_symbol])
    end
    string(fallback)
end

function _tree_root_index(root, node_index)
    isnothing(root) && return nothing
    index = get(node_index, string(root), 0)
    index == 0 && error("Unknown tree root: $(root)")
    index
end

function _fallback_tree_root(undirected, nodes)
    best_index = 1
    best_degree = -1
    for (index, node) in pairs(nodes)
        degree = length(undirected[index])
        if degree > best_degree || (degree == best_degree && node.id < nodes[best_index].id)
            best_index = index
            best_degree = degree
        end
    end
    best_index
end

function _orient_tree_component!(root_index, undirected, visited, parent, depths)
    queue = [root_index]
    visited[root_index] = true
    depths[root_index] = 0
    head = 1
    while head <= length(queue)
        current = queue[head]
        head += 1
        for neighbor in undirected[current]
            visited[neighbor] && continue
            visited[neighbor] = true
            parent[neighbor] = current
            depths[neighbor] = depths[current] + 1
            push!(queue, neighbor)
        end
    end
    nothing
end

function _force_directed_layout(nodes::Vector{NodeSpec}, edges::Vector{EdgeSpec}; algorithm=:fruchterman_reingold, kwargs...)
    selected = _force_directed_algorithm(algorithm)
    selected === :fruchterman_reingold && return _fruchterman_reingold_layout(nodes, edges; kwargs...)
    selected === :kamada_kawai && return _kamada_kawai_layout(nodes, edges; kwargs...)
    selected === :forceatlas2 && return _forceatlas2_layout(nodes, edges; kwargs...)
    selected === :network_spring && return _network_spring_layout(nodes, edges; kwargs...)
    selected === :sfdp && return _network_sfdp_layout(nodes, edges; kwargs...)
    error("Unsupported force-directed algorithm: $(algorithm)")
end

function _force_directed_algorithm(algorithm::Symbol)
    algorithm === :fruchterman_reingold && return :fruchterman_reingold
    algorithm === :spring && return :fruchterman_reingold
    algorithm === :kamada_kawai && return :kamada_kawai
    algorithm === :forceatlas2 && return :forceatlas2
    algorithm === :force_atlas2 && return :forceatlas2
    algorithm === :network_spring && return :network_spring
    algorithm === :networklayout_spring && return :network_spring
    algorithm === :sfdp && return :sfdp
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
    optimal_distance_sq = optimal_distance^2
    inv_optimal_distance = 1.0 / optimal_distance
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
                distance_sq = max(dx * dx + dy * dy, 1.0e-18)
                scale = optimal_distance_sq / distance_sq
                fx = dx * scale
                fy = dy * scale
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
            scale = distance * inv_optimal_distance
            fx = dx * scale
            fy = dy * scale
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
                distance_sq = max(dx * dx + dy * dy, 1.0e-18)
                scale = scaling * (degree[i] + 1.0) * (degree[j] + 1.0) / distance_sq
                fx = dx * scale
                fy = dy * scale
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

function _network_spring_layout(
    nodes::Vector{NodeSpec},
    edges::Vector{EdgeSpec};
    iterations=100,
    seed=nothing,
    extent=1.0,
    C=2.0,
)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    count == 1 && return [_with_position(only(nodes), 0.0, 0.0)]
    graph = _layout_graph_for_networklayout(nodes, edges)
    points = NetworkLayout.Spring(iterations=max(1, Int(iterations)), seed=seed, C=Float64(C))(graph)
    _points_to_nodes(nodes, points; extent=extent)
end

function _network_sfdp_layout(
    nodes::Vector{NodeSpec},
    edges::Vector{EdgeSpec};
    iterations=100,
    seed=nothing,
    extent=1.0,
    tol=0.01,
    C=0.2,
    K=1.0,
)
    count = length(nodes)
    count == 0 && return NodeSpec[]
    count == 1 && return [_with_position(only(nodes), 0.0, 0.0)]
    graph = _layout_graph_for_networklayout(nodes, edges)
    points = NetworkLayout.SFDP(
        iterations=max(1, Int(iterations)),
        seed=seed,
        tol=Float64(tol),
        C=Float64(C),
        K=Float64(K),
    )(graph)
    _points_to_nodes(nodes, points; extent=extent)
end
