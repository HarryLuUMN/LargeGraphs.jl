module LGRenderBenchmarks

include("Scenarios.jl")
include("Backends.jl")
include("Runner.jl")

export BenchmarkConfig, BenchmarkResult, Scenario, default_backends, default_scenarios, run_benchmarks

end
