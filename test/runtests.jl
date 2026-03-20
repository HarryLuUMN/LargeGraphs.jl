using Test
using LargeGraphsJL

nodes = [
    (id="a", x=0.0, y=0.0, label="A", color="#2563eb"),
    (id="b", x=1.0, y=1.0, label="B", color="#059669"),
]

edges = [
    (source="a", target="b", color="#94a3b8"),
]

viz = render(nodes, edges)

@test viz isa SigmaGraph
@test length(viz.nodes) == 2
@test length(viz.edges) == 1

html = sprint(show, MIME"text/html"(), viz)
@test occursin("large-graphs-jl-root", html)
@test occursin("sigma-viewer.js", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String)) == false
