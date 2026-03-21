using Test
using LargeGraphsJL

@testset "LargeGraphsJL" begin
    nodes = [
        (id="a", x=0.0, y=0.0, label="A", color="#2563eb"),
        Dict("id" => "b", "x" => 1.0, "y" => 1.0, "label" => "B", "color" => "#059669"),
    ]

    edges = [
        (source="a", target="b", color="#94a3b8"),
    ]

    viz = render(nodes, edges)

    @test viz isa SigmaGraph
    @test render(viz) === viz
    @test length(viz.nodes) == 2
    @test length(viz.edges) == 1

    html = sprint(show, MIME"text/html"(), viz)
    @test occursin("large-graphs-jl-root", html)
    @test occursin("window.LargeGraphsJL.render", html)
    @test occursin("Loading Sigma.js", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))

    tempdir = mktempdir()
    output = joinpath(tempdir, "graph.html")
    savehtml(output, nodes, edges; height="480px")
    exported = read(output, String)
    @test occursin("<!doctype html>", exported)
    @test occursin("large-graphs-jl-root", exported)
end
