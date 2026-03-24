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
    family::Symbol
    configured_density::Float64
    realized_density::Float64
    nodes::Int
    edges::Int
    total_samples::Vector{Float64}
    stage_samples::Dict{String, Vector{Float64}}
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
        run_backend_once(backend, graph, warmup_path; layout_seed=scenario.seed + i)
    end

    total_timings_ms = Float64[]
    stage_timings_ms = Dict{String, Vector{Float64}}()
    bytes = 0

    for i in 1:config.samples
        run_id = lpad(string(i), 2, '0')
        output_path = _artifact_path(artifacts_dir, scenario.name, backend_name(backend), run_id, artifact_extension(backend))
        GC.gc()
        run = run_backend_once(backend, graph, output_path; layout_seed=scenario.seed + 100 + i)
        push!(total_timings_ms, sum(values(run.stage_timings_ms)))
        _push_stage_timings!(stage_timings_ms, run.stage_timings_ms)
        bytes = run.artifact_bytes
    end

    BenchmarkResult(
        backend_name(backend),
        scenario.name,
        scenario.family,
        scenario.density,
        _graph_density(graph),
        nv(graph),
        ne(graph),
        total_timings_ms,
        stage_timings_ms,
        bytes,
    )
end

function _artifact_path(artifacts_dir::AbstractString, scenario_name::AbstractString, backend::AbstractString, run_id::AbstractString, extension::AbstractString)
    backend_slug = lowercase(replace(backend, ' ' => '_'))
    joinpath(artifacts_dir, "$(scenario_name)-$(backend_slug)-$(run_id).$(extension)")
end

function _push_stage_timings!(all_samples::Dict{String, Vector{Float64}}, run_samples::Dict{String, Float64})
    for (stage_name, timing_ms) in run_samples
        push!(get!(all_samples, stage_name, Float64[]), timing_ms)
    end
end

function _to_row(result::BenchmarkResult)
    total_stats = _stats_dict(result.total_samples)
    stage_rows = Dict(stage_name => _stats_dict(samples) for (stage_name, samples) in sort(collect(result.stage_samples); by=first))
    Dict(
        "backend" => result.backend,
        "scenario" => result.scenario,
        "family" => String(result.family),
        "configured_density" => result.configured_density,
        "realized_density" => result.realized_density,
        "nodes" => result.nodes,
        "edges" => result.edges,
        "artifact_bytes" => result.artifact_bytes,
        "total_ms" => total_stats,
        "stages_ms" => stage_rows,
    )
end

function _stats_dict(samples::Vector{Float64})
    std_ms = length(samples) > 1 ? std(samples) : 0.0
    Dict(
        "samples" => samples,
        "sample_count" => length(samples),
        "mean" => mean(samples),
        "trimmed_mean" => _trimmed_mean(samples),
        "median" => median(samples),
        "min" => minimum(samples),
        "max" => maximum(samples),
        "std" => std_ms,
        "cv_pct" => mean(samples) == 0 ? 0.0 : (std_ms / mean(samples)) * 100.0,
    )
end

function _print_summary(results::Vector{BenchmarkResult}, summary_path::AbstractString)
    println("Render benchmark summary")
    println("results file: $(summary_path)")
    for result in results
        total_mean_ms = round(mean(result.total_samples); digits=2)
        total_trimmed_mean_ms = round(_trimmed_mean(result.total_samples); digits=2)
        stage_parts = [
            "$(stage_name)=$(round(_trimmed_mean(samples); digits=2)) ms"
            for (stage_name, samples) in sort(collect(result.stage_samples); by=first)
        ]
        println("- $(result.scenario) | $(result.backend) | family=$(result.family), density=$(round(result.realized_density; digits=4)), total_mean=$(total_mean_ms) ms, total_trimmed_mean=$(total_trimmed_mean_ms) ms, $(join(stage_parts, ", ")), artifact=$(result.artifact_bytes) bytes")
    end
end

function _graph_density(graph)
    n = nv(graph)
    n <= 1 && return 0.0
    return (2 * ne(graph)) / (n * (n - 1))
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
        "| Scenario | Nodes | Edges | Faster backend | Total speedup | Smaller artifact | Size ratio | Largest stage share |",
        "| --- | ---: | ---: | --- | ---: | --- | ---: | --- |",
    ]

    for scenario_name in scenario_names
        scenario_results = grouped[scenario_name]
        fastest = _fastest_result(scenario_results)
        smallest = _smallest_artifact_result(scenario_results)
        slowest = _slowest_result(scenario_results)
        largest = _largest_artifact_result(scenario_results)
        speedup = _comparison_total_ms(slowest) / _comparison_total_ms(fastest)
        size_ratio = largest.artifact_bytes / smallest.artifact_bytes
        stage_name, stage_share = _largest_stage_share(fastest)
        push!(
            lines,
            "| `$(scenario_name)` | `$(fastest.family)` | $(fastest.nodes) | $(fastest.edges) | $(_fmt(fastest.realized_density; digits=4)) | $(fastest.backend) | $(_fmt(speedup; digits=2))x | $(smallest.backend) | $(_fmt(size_ratio; digits=2))x | $(stage_name) ($(_fmt(stage_share; digits=1))%) |",
        )
    end

    push!(lines, "", "## Scenario Details", "")
    for scenario_name in scenario_names
        scenario_results = sort(grouped[scenario_name]; by=_comparison_total_ms)
        push!(lines, "### $(scenario_name)", "")
        push!(lines, "| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |")
        push!(lines, "| --- | ---: | ---: | ---: | ---: | --- |")
        for result in scenario_results
            total_mean_ms = mean(result.total_samples)
            total_std_ms = length(result.total_samples) > 1 ? std(result.total_samples) : 0.0
            total_cv_pct = total_mean_ms == 0 ? 0.0 : (total_std_ms / total_mean_ms) * 100.0
            push!(
                lines,
                "| $(result.backend) | $(_fmt(_trimmed_mean(result.total_samples); digits=2)) | $(_fmt(total_mean_ms; digits=2)) | $(_fmt(total_cv_pct; digits=1)) | $(_fmt_bytes(result.artifact_bytes)) | $(_stage_breakdown_summary(result)) |",
            )
        end
        push!(lines, "")
        for result in scenario_results
            push!(lines, "#### $(result.backend) stage details")
            push!(lines, "")
            push!(lines, "| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |")
            push!(lines, "| --- | ---: | ---: | ---: | ---: |")
            total_ms = _comparison_total_ms(result)
            for (stage_name, samples) in sort(collect(result.stage_samples); by=first)
                stage_mean_ms = mean(samples)
                stage_std_ms = length(samples) > 1 ? std(samples) : 0.0
                stage_cv_pct = stage_mean_ms == 0 ? 0.0 : (stage_std_ms / stage_mean_ms) * 100.0
                stage_trimmed_ms = _trimmed_mean(samples)
                share_pct = total_ms == 0 ? 0.0 : (stage_trimmed_ms / total_ms) * 100.0
                push!(
                    lines,
                    "| `$(stage_name)` | $(_fmt(stage_trimmed_ms; digits=2)) | $(_fmt(stage_mean_ms; digits=2)) | $(_fmt(share_pct; digits=1))% | $(_fmt(stage_cv_pct; digits=1)) |",
                )
            end
            push!(lines, "")
        end
        push!(lines, _scenario_observation(scenario_results))
        push!(lines, "")
    end

    push!(lines, "## Notes", "")
    push!(lines, "- Timings are split by backend stage and then summed into `total_ms`.")
    push!(lines, "- `Trimmed mean` drops the fastest and slowest sample when at least three timed samples are available.")
    push!(lines, "- `CV (%)` highlights run-to-run stability; lower values indicate steadier measurements.")
    push!(lines, "- Overview speedups and winners are based on total `trimmed mean` so one noisy sample does not dominate the comparison.")

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
    speedup = _comparison_total_ms(slowest) / _comparison_total_ms(fastest)
    size_ratio = largest.artifact_bytes / smallest.artifact_bytes
    dominant_stage, dominant_share = _largest_stage_share(fastest)
    "`$(fastest.backend)` was faster overall by $(_fmt(speedup; digits=2))x. Its largest timed stage was `$(dominant_stage)` at $(_fmt(dominant_share; digits=1))% of total trimmed mean, while `$(smallest.backend)` produced the smaller artifact by $(_fmt(size_ratio; digits=2))x."
end

_fastest_result(results::Vector{BenchmarkResult}) = _pick_min(_comparison_total_ms, results)
_slowest_result(results::Vector{BenchmarkResult}) = _pick_max(_comparison_total_ms, results)
_smallest_artifact_result(results::Vector{BenchmarkResult}) = _pick_min(result -> result.artifact_bytes, results)
_largest_artifact_result(results::Vector{BenchmarkResult}) = _pick_max(result -> result.artifact_bytes, results)

_comparison_total_ms(result::BenchmarkResult) = _trimmed_mean(result.total_samples)

function _largest_stage_share(result::BenchmarkResult)
    total_ms = _comparison_total_ms(result)
    best_name = ""
    best_share = -Inf
    for (stage_name, samples) in result.stage_samples
        share_pct = total_ms == 0 ? 0.0 : (_trimmed_mean(samples) / total_ms) * 100.0
        if share_pct > best_share
            best_name = stage_name
            best_share = share_pct
        end
    end
    best_name, best_share
end

function _stage_breakdown_summary(result::BenchmarkResult)
    parts = String[]
    total_ms = _comparison_total_ms(result)
    for (stage_name, samples) in sort(collect(result.stage_samples); by=first)
        stage_trimmed_ms = _trimmed_mean(samples)
        share_pct = total_ms == 0 ? 0.0 : (stage_trimmed_ms / total_ms) * 100.0
        push!(parts, "`$(stage_name)` $(_fmt(stage_trimmed_ms; digits=2)) ms ($(_fmt(share_pct; digits=1))%)")
    end
    join(parts, ", ")
end

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
