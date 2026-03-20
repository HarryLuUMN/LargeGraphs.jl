using LargeGraphsJL
using Random

function random_graph(node_count::Integer=10_000, edge_count::Integer=30_000; seed::Integer=7)
    rng = MersenneTwister(seed)
    nodes = Vector{NamedTuple}(undef, node_count)
    for i in 1:node_count
        nodes[i] = (
            id=string(i),
            x=rand(rng),
            y=rand(rng),
            size=1.0 + 2.0 * rand(rng),
            color=rand(rng, ("#2563eb", "#0891b2", "#059669", "#d97706")),
            label=i <= 250 ? "node-$i" : nothing,
        )
    end

    edges = Vector{NamedTuple}(undef, edge_count)
    for i in 1:edge_count
        source = rand(rng, 1:node_count)
        target = rand(rng, 1:node_count)
        edges[i] = (
            source=string(source),
            target=string(target),
            size=0.5,
            color="#cbd5e1",
        )
    end

    render(
        nodes,
        edges;
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
