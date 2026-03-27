module LargeGraphsCUDAExt

using CUDA
using LargeGraphs

function gpu_backend_available()
    CUDA.functional()
end

function gpu_fruchterman_reingold_layout(
    nodes::Vector{LargeGraphs.NodeSpec},
    edges::Vector{LargeGraphs.EdgeSpec};
    iterations=100,
    seed=nothing,
    extent=1.0,
    gravity=0.05,
    cooling=0.9,
)
    count = length(nodes)
    count == 0 && return LargeGraphs.NodeSpec[]
    count == 1 && return [LargeGraphs._with_position(only(nodes), 0.0, 0.0)]

    xs0, ys0 = LargeGraphs._initial_positions(nodes; seed=seed, extent=extent)
    xs = CuArray(Float32.(xs0))
    ys = CuArray(Float32.(ys0))
    indexed_edges = LargeGraphs._edge_indices(nodes, edges)
    sources = isempty(indexed_edges) ? CuArray(Int32[]) : CuArray(Int32[first(edge) for edge in indexed_edges])
    targets = isempty(indexed_edges) ? CuArray(Int32[]) : CuArray(Int32[last(edge) for edge in indexed_edges])

    area = max(extent^2, 1.0)
    optimal_distance = sqrt(area / count)
    optimal_distance_sq = Float32(optimal_distance^2)
    inv_optimal_distance = Float32(1.0 / optimal_distance)
    temperature = Float32(max(extent, 1.0))
    gravity32 = Float32(gravity)
    count_range = reshape(CuArray(Int32.(collect(1:count))), count, 1)

    for _ in 1:max(1, Int(iterations))
        dx = xs .- permutedims(xs)
        dy = ys .- permutedims(ys)
        distance_sq = max.(dx .* dx .+ dy .* dy, Float32(1.0e-18))
        repulsion_scale = optimal_distance_sq ./ distance_sq
        repulsion_x = sum(dx .* repulsion_scale; dims=2)
        repulsion_y = sum(dy .* repulsion_scale; dims=2)

        attraction_x = CUDA.zeros(Float32, count)
        attraction_y = CUDA.zeros(Float32, count)
        if !isempty(indexed_edges)
            edge_dx = xs[sources] .- xs[targets]
            edge_dy = ys[sources] .- ys[targets]
            edge_distance = max.(sqrt.(edge_dx .* edge_dx .+ edge_dy .* edge_dy), Float32(1.0e-9))
            attraction_scale = edge_distance .* inv_optimal_distance
            edge_fx = edge_dx .* attraction_scale
            edge_fy = edge_dy .* attraction_scale
            attraction_x .= vec(sum((count_range .== permutedims(sources)) .* permutedims(edge_fx) .- (count_range .== permutedims(targets)) .* permutedims(edge_fx); dims=2))
            attraction_y .= vec(sum((count_range .== permutedims(sources)) .* permutedims(edge_fy) .- (count_range .== permutedims(targets)) .* permutedims(edge_fy); dims=2))
        end

        disp_x = vec(repulsion_x) .- attraction_x .- gravity32 .* xs
        disp_y = vec(repulsion_y) .- attraction_y .- gravity32 .* ys
        disp_norm = sqrt.(disp_x .* disp_x .+ disp_y .* disp_y)
        safe_norm = max.(disp_norm, Float32(1.0e-9))
        step = min.(disp_norm, temperature)
        xs .= xs .+ disp_x ./ safe_norm .* step
        ys .= ys .+ disp_y ./ safe_norm .* step
        temperature *= Float32(cooling)
    end

    xs_host, ys_host = LargeGraphs._rescale_positions(Float64.(Array(xs)), Float64.(Array(ys)); extent=extent)
    [LargeGraphs._with_position(node, xs_host[index], ys_host[index]) for (index, node) in pairs(nodes)]
end

end
