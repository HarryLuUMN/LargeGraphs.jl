using Dates
using JSON3
using Statistics

struct BenchmarkConfig
    samples::Int
    warmup::Int
    output_root::String
end

struct BenchmarkResult
    backend::String
    scenario::String
    nodes::Int
    edges::Int
    samples::Vector{Float64}
    artifact_bytes::Int
end

BenchmarkConfig(; samples::Int=4, warmup::Int=1, output_root::AbstractString=joinpath(@__DIR__, "..", "results")) =
    BenchmarkConfig(samples, warmup, abspath(output_root))

function run_benchmarks(; scenarios=default_scenarios(), backends=default_backends(), config=BenchmarkConfig())
    raw_dir = joinpath(config.output_root, "raw")
    artifacts_dir = joinpath(config.output_root, "artifacts")
    mkpath(raw_dir)
    mkpath(artifacts_dir)

    results = BenchmarkResult[]

    for scenario in scenarios
        graph = build_graph(scenario)
        for backend in backends
            push!(results, _run_single(backend, graph, scenario, config, artifacts_dir))
        end
    end

    timestamp = Dates.format(now(), "yyyymmdd-HHMMSS")
    summary_path = joinpath(raw_dir, "summary-$(timestamp).json")
    rows = [_to_row(result) for result in results]
    open(summary_path, "w") do io
        JSON3.pretty(io, rows)
    end

    latest_path = joinpath(raw_dir, "latest.json")
    open(latest_path, "w") do io
        JSON3.pretty(io, rows)
    end

    _print_summary(results, summary_path)

    return (results=results, summary_path=summary_path, artifacts_dir=artifacts_dir)
end

function _run_single(backend::BenchmarkBackend, graph, scenario::Scenario, config::BenchmarkConfig, artifacts_dir::AbstractString)
    for i in 1:config.warmup
        warmup_path = _artifact_path(artifacts_dir, scenario.name, backend_name(backend), "warmup$(i)", artifact_extension(backend))
        render_artifact(backend, graph, warmup_path; layout_seed=scenario.seed + i)
    end

    timings_ms = Float64[]
    bytes = 0
    for i in 1:config.samples
        run_id = lpad(string(i), 2, '0')
        output_path = _artifact_path(artifacts_dir, scenario.name, backend_name(backend), run_id, artifact_extension(backend))
        elapsed_ns = @elapsed begin
            bytes = render_artifact(backend, graph, output_path; layout_seed=scenario.seed + 100 + i)
        end
        push!(timings_ms, elapsed_ns * 1000.0)
    end

    BenchmarkResult(
        backend_name(backend),
        scenario.name,
        nv(graph),
        ne(graph),
        timings_ms,
        bytes,
    )
end

function _artifact_path(artifacts_dir::AbstractString, scenario_name::AbstractString, backend::AbstractString, run_id::AbstractString, extension::AbstractString)
    backend_slug = lowercase(replace(backend, ' ' => '_'))
    joinpath(artifacts_dir, "$(scenario_name)-$(backend_slug)-$(run_id).$(extension)")
end

function _to_row(result::BenchmarkResult)
    Dict(
        "backend" => result.backend,
        "scenario" => result.scenario,
        "nodes" => result.nodes,
        "edges" => result.edges,
        "samples_ms" => result.samples,
        "mean_ms" => mean(result.samples),
        "median_ms" => median(result.samples),
        "min_ms" => minimum(result.samples),
        "max_ms" => maximum(result.samples),
        "artifact_bytes" => result.artifact_bytes,
    )
end

function _print_summary(results::Vector{BenchmarkResult}, summary_path::AbstractString)
    println("Render benchmark summary")
    println("results file: $(summary_path)")
    for result in results
        mean_ms = round(mean(result.samples); digits=2)
        median_ms = round(median(result.samples); digits=2)
        min_ms = round(minimum(result.samples); digits=2)
        max_ms = round(maximum(result.samples); digits=2)
        println("- $(result.scenario) | $(result.backend) | nodes=$(result.nodes), edges=$(result.edges), mean=$(mean_ms) ms, median=$(median_ms) ms, min=$(min_ms) ms, max=$(max_ms) ms, artifact=$(result.artifact_bytes) bytes")
    end
end
