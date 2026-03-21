using LargeGraphs
using Random

function random_graph(node_count::Integer=10_000, edge_count::Integer=30_000; seed::Integer=7)
    rng = MersenneTwister(seed)
    nodes = Vector{NamedTuple}(undef, node_count)
    for i in 1:node_count
        nodes[i] = (
            id=string(i),
            size=1.0 + 2.0 * rand(rng),
            color=rand(rng, ("#2563eb", "#0891b2", "#059669", "#d97706")),
            label=i <= 250 ? "node-$i" : nothing,
        )
    end

    edges = NamedTuple[]
    seen = Set{Tuple{Int, Int}}()
    while length(edges) < edge_count
        source = rand(rng, 1:node_count)
        target = rand(rng, 1:node_count)
        source == target && continue
        edge = source < target ? (source, target) : (target, source)
        edge in seen && continue
        push!(seen, edge)
        push!(edges, (
            source=string(source),
            target=string(target),
            size=0.5,
            color="#cbd5e1",
        ))
    end

    render(
        nodes,
        edges;
        layout=:random,
        seed=seed,
        height="780px",
        render_edge_labels=false,
        hide_edges_on_move=true,
        label_density=0.6,
        max_node_size=10.0,
        min_node_size=1.5,
    )
end

viz = random_graph()
savehtml(joinpath(@__DIR__, "demo_large_graph.html"), viz)
display(viz)
