using Pkg

project_dir = normpath(joinpath(@__DIR__, ".."))
Pkg.activate(project_dir)
Pkg.instantiate()

using LGRenderBenchmarks

config = BenchmarkConfig(samples=4, warmup=1, output_root=joinpath(project_dir, "results"))
run_benchmarks(config=config)
