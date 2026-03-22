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

struct BenchmarkRun
    stage_timings_ms::Dict{String, Float64}
    artifact_bytes::Int
end

backend_name(::LargeGraphsBackend) = "LargeGraphs"
backend_name(::GraphMakieBackend) = "GraphMakie"

artifact_extension(::LargeGraphsBackend) = "html"
artifact_extension(::GraphMakieBackend) = "png"

default_backends() = BenchmarkBackend[LargeGraphsBackend(), GraphMakieBackend()]

function run_backend_once(
    ::LargeGraphsBackend,
    graph::Graphs.AbstractGraph,
    output_path::AbstractString;
    layout_seed::Int,
)
    config = SigmaConfig(width="1200px", height="800px", hide_edges_on_move=true)

    layouted, layout_ms = _time_ms() do
        LargeGraphs.layout_graph(
            graph;
            layout=:force_directed,
            algorithm=:fruchterman_reingold,
            iterations=80,
            seed=layout_seed,
        )
    end

    sigma_graph, assemble_ms = _time_ms() do
        LargeGraphs.assemble_graph(layouted; config=config)
    end

    _, export_ms = _time_ms() do
        LargeGraphs.savehtml(output_path, sigma_graph)
    end

    BenchmarkRun(
        Dict(
            "layout_ms" => layout_ms,
            "assemble_ms" => assemble_ms,
            "export_ms" => export_ms,
        ),
        filesize(output_path),
    )
end

function run_backend_once(
    ::GraphMakieBackend,
    graph::Graphs.AbstractGraph,
    output_path::AbstractString;
    layout_seed::Int,
)
    Random.seed!(layout_seed)

    figure, plot_ms = _time_ms() do
        figure = Figure(size=(1200, 800))
        axis = Axis(figure[1, 1], title="GraphMakie benchmark", xticksvisible=false, yticksvisible=false)
        graphplot!(axis, graph; node_size=5, edge_width=1)
        figure
    end

    _, export_ms = _time_ms() do
        CairoMakie.save(output_path, figure)
    end

    BenchmarkRun(
        Dict(
            "plot_ms" => plot_ms,
            "export_ms" => export_ms,
        ),
        filesize(output_path),
    )
end

function _time_ms(f::Function)
    started = time_ns()
    value = f()
    elapsed_ms = (time_ns() - started) / 1_000_000
    value, elapsed_ms
end
