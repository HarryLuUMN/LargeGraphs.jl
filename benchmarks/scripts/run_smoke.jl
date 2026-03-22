using Pkg

project_dir = normpath(joinpath(@__DIR__, ".."))
Pkg.activate(project_dir)
Pkg.instantiate()

using LGRenderBenchmarks

smoke_scenarios = [
    Scenario("smoke_erdos_renyi", :erdos_renyi, 120, 0.03, 7),
    Scenario("smoke_preferential_attachment", :preferential_attachment, 180, 0.03, 8),
]
config = BenchmarkConfig(samples=2, warmup=1, output_root=joinpath(project_dir, "results"))
run_benchmarks(scenarios=smoke_scenarios, config=config)
