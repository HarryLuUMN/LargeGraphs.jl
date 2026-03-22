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
    summary_md_path = joinpath(config.output_root, "summary.md")
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

    _write_markdown_summary(results, summary_md_path, latest_path, summary_path)
    _print_summary(results, summary_path)

    return (
        results=results,
        summary_path=summary_path,
        summary_md_path=summary_md_path,
        artifacts_dir=artifacts_dir,
    )
end

function _run_single(backend::BenchmarkBackend, graph, scenario::Scenario, config::BenchmarkConfig, artifacts_dir::AbstractString)
    for i in 1:config.warmup
        warmup_path = _artifact_path(artifacts_dir, scenario.name, backend_name(backend), "warmup$(i)", artifact_extension(backend))
        GC.gc()
        render_artifact(backend, graph, warmup_path; layout_seed=scenario.seed + i)
    end

    timings_ms = Float64[]
    bytes = 0
    for i in 1:config.samples
        run_id = lpad(string(i), 2, '0')
        output_path = _artifact_path(artifacts_dir, scenario.name, backend_name(backend), run_id, artifact_extension(backend))
        GC.gc()
        elapsed_s = @elapsed begin
            bytes = render_artifact(backend, graph, output_path; layout_seed=scenario.seed + 100 + i)
        end
        push!(timings_ms, elapsed_s * 1000.0)
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
    std_ms = length(result.samples) > 1 ? std(result.samples) : 0.0
    Dict(
        "backend" => result.backend,
        "scenario" => result.scenario,
        "nodes" => result.nodes,
        "edges" => result.edges,
        "samples_ms" => result.samples,
        "sample_count" => length(result.samples),
        "mean_ms" => mean(result.samples),
        "trimmed_mean_ms" => _trimmed_mean(result.samples),
        "median_ms" => median(result.samples),
        "min_ms" => minimum(result.samples),
        "max_ms" => maximum(result.samples),
        "std_ms" => std_ms,
        "cv_pct" => mean(result.samples) == 0 ? 0.0 : (std_ms / mean(result.samples)) * 100.0,
        "artifact_bytes" => result.artifact_bytes,
    )
end

function _print_summary(results::Vector{BenchmarkResult}, summary_path::AbstractString)
    println("Render benchmark summary")
    println("results file: $(summary_path)")
    for result in results
        mean_ms = round(mean(result.samples); digits=2)
        trimmed_mean_ms = round(_trimmed_mean(result.samples); digits=2)
        median_ms = round(median(result.samples); digits=2)
        min_ms = round(minimum(result.samples); digits=2)
        max_ms = round(maximum(result.samples); digits=2)
        std_ms = round(length(result.samples) > 1 ? std(result.samples) : 0.0; digits=2)
        println("- $(result.scenario) | $(result.backend) | nodes=$(result.nodes), edges=$(result.edges), mean=$(mean_ms) ms, trimmed_mean=$(trimmed_mean_ms) ms, median=$(median_ms) ms, min=$(min_ms) ms, max=$(max_ms) ms, std=$(std_ms) ms, artifact=$(result.artifact_bytes) bytes")
    end
end

function _trimmed_mean(samples::Vector{Float64})
    length(samples) <= 2 && return mean(samples)
    trimmed = sort(samples)[2:(end - 1)]
    isempty(trimmed) ? mean(samples) : mean(trimmed)
end

function _write_markdown_summary(
    results::Vector{BenchmarkResult},
    summary_md_path::AbstractString,
    latest_path::AbstractString,
    summary_path::AbstractString,
)
    grouped = Dict{String, Vector{BenchmarkResult}}()
    for result in results
        push!(get!(grouped, result.scenario, BenchmarkResult[]), result)
    end

    scenario_names = sort(collect(keys(grouped)))
    lines = String[
        "# Rendering Benchmark Summary",
        "",
        "Generated from:",
        "- `$(relpath(latest_path, dirname(summary_md_path)))`",
        "- `$(relpath(summary_path, dirname(summary_md_path)))`",
        "",
        "## Overview",
        "",
        "| Scenario | Nodes | Edges | Faster backend | Speedup | Smaller artifact | Size ratio |",
        "| --- | ---: | ---: | --- | ---: | --- | ---: |",
    ]

    for scenario_name in scenario_names
        scenario_results = grouped[scenario_name]
        fastest = _fastest_result(scenario_results)
        smallest = _smallest_artifact_result(scenario_results)
        slowest = _slowest_result(scenario_results)
        largest = _largest_artifact_result(scenario_results)
        speedup = _comparison_time_ms(slowest) / _comparison_time_ms(fastest)
        size_ratio = largest.artifact_bytes / smallest.artifact_bytes
        push!(
            lines,
            "| `$(scenario_name)` | $(fastest.nodes) | $(fastest.edges) | $(fastest.backend) | $(_fmt(speedup; digits=2))x | $(smallest.backend) | $(_fmt(size_ratio; digits=2))x |",
        )
    end

    push!(lines, "", "## Scenario Details", "")
    for scenario_name in scenario_names
        scenario_results = sort(grouped[scenario_name]; by=result -> mean(result.samples))
        push!(lines, "### $(scenario_name)", "")
        push!(lines, "| Backend | Mean (ms) | Trimmed mean (ms) | Median (ms) | Std (ms) | CV (%) | Artifact |")
        push!(lines, "| --- | ---: | ---: | ---: | ---: | ---: | ---: |")
        for result in scenario_results
            mean_ms = mean(result.samples)
            std_ms = length(result.samples) > 1 ? std(result.samples) : 0.0
            cv_pct = mean_ms == 0 ? 0.0 : (std_ms / mean_ms) * 100.0
            push!(
                lines,
                "| $(result.backend) | $(_fmt(mean_ms; digits=2)) | $(_fmt(_trimmed_mean(result.samples); digits=2)) | $(_fmt(median(result.samples); digits=2)) | $(_fmt(std_ms; digits=2)) | $(_fmt(cv_pct; digits=1)) | $(_fmt_bytes(result.artifact_bytes)) |",
            )
        end
        push!(lines, "")
        push!(lines, _scenario_observation(scenario_results))
        push!(lines, "")
    end

    push!(lines, "## Notes", "")
    push!(lines, "- Timings are end-to-end artifact generation times measured after warmup runs.")
    push!(lines, "- `Trimmed mean` drops the fastest and slowest sample when at least three timed samples are available.")
    push!(lines, "- `CV (%)` highlights run-to-run stability; lower values indicate steadier measurements.")
    push!(lines, "- Overview speedups and winners are based on `trimmed mean` so one noisy sample does not dominate the comparison.")

    open(summary_md_path, "w") do io
        write(io, join(lines, "\n"))
        write(io, "\n")
    end
end

function _scenario_observation(results::Vector{BenchmarkResult})
    fastest = _fastest_result(results)
    slowest = _slowest_result(results)
    smallest = _smallest_artifact_result(results)
    largest = _largest_artifact_result(results)
    speedup = _comparison_time_ms(slowest) / _comparison_time_ms(fastest)
    size_ratio = largest.artifact_bytes / smallest.artifact_bytes
    "`$(fastest.backend)` was faster in this scenario by $(_fmt(speedup; digits=2))x, while `$(smallest.backend)` produced the smaller artifact by $(_fmt(size_ratio; digits=2))x."
end

_fastest_result(results::Vector{BenchmarkResult}) = _pick_min(_comparison_time_ms, results)
_slowest_result(results::Vector{BenchmarkResult}) = _pick_max(_comparison_time_ms, results)
_smallest_artifact_result(results::Vector{BenchmarkResult}) = _pick_min(result -> result.artifact_bytes, results)
_largest_artifact_result(results::Vector{BenchmarkResult}) = _pick_max(result -> result.artifact_bytes, results)

_comparison_time_ms(result::BenchmarkResult) = _trimmed_mean(result.samples)

function _pick_min(f, xs)
    best = first(xs)
    best_value = f(best)
    for x in Iterators.drop(xs, 1)
        value = f(x)
        if value < best_value
            best = x
            best_value = value
        end
    end
    best
end

function _pick_max(f, xs)
    best = first(xs)
    best_value = f(best)
    for x in Iterators.drop(xs, 1)
        value = f(x)
        if value > best_value
            best = x
            best_value = value
        end
    end
    best
end

_fmt(value; digits::Int=2) = string(round(value; digits=digits))

function _fmt_bytes(bytes::Int)
    kib = bytes / 1024
    if kib >= 1024
        return string(round(kib / 1024; digits=2), " MiB")
    end
    string(round(kib; digits=1), " KiB")
end
