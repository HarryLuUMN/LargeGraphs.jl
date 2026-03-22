using Graphs
using Random

struct Scenario
    name::String
    family::Symbol
    n::Int
    density::Float64
    seed::Int
end

function default_scenarios()
    [
        Scenario("erdos_renyi_small", :erdos_renyi, 200, 0.02, 11),
        Scenario("erdos_renyi_medium", :erdos_renyi, 800, 0.006, 22),
        Scenario("preferential_attachment_medium", :preferential_attachment, 1000, 0.003, 33),
    ]
end

function build_graph(s::Scenario)
    if s.family === :erdos_renyi
        return _erdos_renyi_graph(s.n, s.density, s.seed)
    end
    if s.family === :preferential_attachment
        return _preferential_attachment_graph(s.n, s.density, s.seed)
    end
    error("Unsupported scenario family: $(s.family)")
end

function _erdos_renyi_graph(n::Int, p::Float64, seed::Int)
    rng = MersenneTwister(seed)
    g = SimpleGraph(n)
    for u in 1:(n - 1)
        for v in (u + 1):n
            rand(rng) <= p && add_edge!(g, u, v)
        end
    end
    g
end

function _preferential_attachment_graph(n::Int, density::Float64, seed::Int)
    rng = MersenneTwister(seed)
    m = max(2, Int(round(density * n)))
    m = min(m, max(2, n - 1))

    g = SimpleGraph(n)
    for u in 1:m
        for v in (u + 1):m
            add_edge!(g, u, v)
        end
    end

    targets = Int[]
    for v in 1:m
        append!(targets, fill(v, degree(g, v)))
    end

    for new_vertex in (m + 1):n
        chosen = Set{Int}()
        while length(chosen) < m
            candidate = isempty(targets) ? rand(rng, 1:(new_vertex - 1)) : rand(rng, targets)
            candidate == new_vertex && continue
            push!(chosen, candidate)
        end

        for existing in chosen
            add_edge!(g, new_vertex, existing)
        end

        for existing in chosen
            push!(targets, existing)
            push!(targets, new_vertex)
        end
    end

    g
end
