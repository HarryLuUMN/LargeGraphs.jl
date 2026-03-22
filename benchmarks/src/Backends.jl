using CairoMakie
using GraphMakie
using Graphs
using LargeGraphs
using Random

abstract type BenchmarkBackend end

struct LargeGraphsBackend <: BenchmarkBackend
end

struct GraphMakieBackend <: BenchmarkBackend
end

backend_name(::LargeGraphsBackend) = "LargeGraphs"
backend_name(::GraphMakieBackend) = "GraphMakie"

artifact_extension(::LargeGraphsBackend) = "html"
artifact_extension(::GraphMakieBackend) = "png"

default_backends() = BenchmarkBackend[LargeGraphsBackend(), GraphMakieBackend()]

function render_artifact(::LargeGraphsBackend, graph::Graphs.AbstractGraph, output_path::AbstractString; layout_seed::Int)
    sigma_graph = LargeGraphs.render(
        graph;
        layout=:force_directed,
        algorithm=:fruchterman_reingold,
        iterations=80,
        seed=layout_seed,
        width="1200px",
        height="800px",
        hide_edges_on_move=true,
    )
    LargeGraphs.savehtml(output_path, sigma_graph)
    filesize(output_path)
end

function render_artifact(::GraphMakieBackend, graph::Graphs.AbstractGraph, output_path::AbstractString; layout_seed::Int)
    Random.seed!(layout_seed)
    figure = Figure(size=(1200, 800))
    axis = Axis(figure[1, 1], title="GraphMakie benchmark", xticksvisible=false, yticksvisible=false)
    graphplot!(axis, graph; node_size=5, edge_width=1)
    CairoMakie.save(output_path, figure)
    filesize(output_path)
end
