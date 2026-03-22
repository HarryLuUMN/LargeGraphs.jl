# Rendering Benchmarks

This subproject provides a runnable benchmark scaffold to compare rendering-focused graph visualization work between:

- `LargeGraphs` (interactive Sigma.js HTML export)
- `GraphMakie` (Makie figure rasterization to PNG via Cairo)

The benchmark measures end-to-end artifact generation from the same input graphs per scenario.

## Structure

- `Project.toml`: isolated benchmark dependencies
- `src/Scenarios.jl`: graph scenario definitions and deterministic generators
- `src/Backends.jl`: backend-specific rendering/export adapters
- `src/Runner.jl`: benchmark loop, timing, JSON output, and Markdown report generation
- `scripts/run_smoke.jl`: small sanity run
- `scripts/run_benchmarks.jl`: default benchmark run
- `results/raw/`: JSON summaries (`latest.json` and timestamped snapshots)
- `results/artifacts/`: rendered output artifacts (`.html` / `.png`)
- `notebooks/benchmark_walkthrough.ipynb`: notebook example

## Quick Start

From repository root:

```bash
julia --project=benchmarks benchmarks/scripts/run_smoke.jl
```

Run the default scaffold set:

```bash
julia --project=benchmarks benchmarks/scripts/run_benchmarks.jl
```

Results are written to:

- `benchmarks/results/raw/latest.json`
- `benchmarks/results/raw/summary-<timestamp>.json`
- `benchmarks/results/summary.md`
- `benchmarks/results/artifacts/*`

The generated Markdown report includes:

- an overview table per scenario
- total timings plus per-stage timing breakdowns
- trimmed means, standard deviation, and coefficient of variation
- automatic speedup and artifact-size comparisons between backends

## Current Scenarios

- `erdos_renyi_small`: 200 nodes
- `erdos_renyi_medium`: 800 nodes
- `preferential_attachment_medium`: 1000 nodes

You can customize scenario sizes and density by editing `src/Scenarios.jl` or by passing custom `Scenario` vectors to `run_benchmarks`.

## Notes On Fairness

This scaffold intentionally compares the same task class for both backends: generate a visual artifact from a graph scenario.

- `LargeGraphs`: layout, graph assembly, and standalone HTML export
- `GraphMakie`: plot construction and PNG export

The backends target different output media, so this first scaffold is a practical starting point rather than a final authoritative performance ranking.

## Measurement Notes

- Smoke runs default to `warmup=2` and `samples=3`
- Default benchmark runs use `warmup=2` and `samples=5`
- The harness runs `GC.gc()` before each warmup and timed sample to reduce cross-run noise
- The JSON output stores `total_ms` and `stages_ms` separately so you can isolate which phase dominates
