using Pkg

project_dir = normpath(joinpath(@__DIR__, ".."))
Pkg.activate(project_dir)
Pkg.instantiate()

using LGRenderBenchmarks

config = BenchmarkConfig(samples=5, warmup=2, output_root=joinpath(project_dir, "results"))
run_benchmarks(config=config)
