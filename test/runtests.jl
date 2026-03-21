using Test
using LargeGraphsJL

@testset "LargeGraphsJL" begin
    positioned_nodes = [
        (id="a", x=0.0, y=0.0, label="A", color="#2563eb"),
        Dict("id" => "b", "x" => 1.0, "y" => 1.0, "label" => "B", "color" => "#059669"),
    ]

    layout_nodes = [
        (id="a", label="A", color="#2563eb"),
        (id="b", label="B", color="#059669"),
        (id="c", label="C", color="#d97706"),
        (id="d", label="D", color="#7c3aed"),
    ]

    edges = [
        (source="a", target="b", color="#94a3b8"),
        (source="b", target="c", color="#94a3b8"),
        (source="c", target="d", color="#94a3b8"),
    ]

    viz = render(positioned_nodes, [(source="a", target="b", color="#94a3b8")])

    @test viz isa SigmaGraph
    @test render(viz) === viz
    @test length(viz.nodes) == 2
    @test length(viz.edges) == 1

    random_nodes = random_layout(layout_nodes; seed=11, extent=2.0)
    @test random_nodes isa Vector{NodeSpec}
    @test [node.id for node in random_nodes] == ["a", "b", "c", "d"]
    @test all(-2.0 <= node.x <= 2.0 for node in random_nodes)
    @test all(-2.0 <= node.y <= 2.0 for node in random_nodes)

    circular_nodes = circular_layout(layout_nodes; radius=2.0)
    @test isapprox(circular_nodes[1].x, 2.0; atol=1.0e-8)
    @test isapprox(circular_nodes[1].y, 0.0; atol=1.0e-8)
    @test all(isapprox(sqrt(node.x^2 + node.y^2), 2.0; atol=1.0e-8) for node in circular_nodes)

    grid_nodes = grid_layout(layout_nodes; columns=2, spacing=3.0)
    @test Set((node.x, node.y) for node in grid_nodes) == Set([
        (-1.5, 1.5),
        (1.5, 1.5),
        (-1.5, -1.5),
        (1.5, -1.5),
    ])

    spring_nodes = spring_layout(layout_nodes, edges; iterations=40, seed=5, extent=1.5)
    @test [node.id for node in spring_nodes] == ["a", "b", "c", "d"]
    @test all(-1.5 <= node.x <= 1.5 for node in spring_nodes)
    @test all(-1.5 <= node.y <= 1.5 for node in spring_nodes)
    @test length(Set((round(node.x, digits=6), round(node.y, digits=6)) for node in spring_nodes)) == 4

    fr_nodes = force_directed_layout(layout_nodes, edges; algorithm=:fruchterman_reingold, iterations=40, seed=5, extent=1.5)
    @test [node.id for node in fr_nodes] == ["a", "b", "c", "d"]
    @test all(-1.5 <= node.x <= 1.5 for node in fr_nodes)
    @test all(-1.5 <= node.y <= 1.5 for node in fr_nodes)
    @test length(Set((round(node.x, digits=6), round(node.y, digits=6)) for node in fr_nodes)) == 4

    kk_nodes = force_directed_layout(layout_nodes, edges; algorithm=:kamada_kawai, iterations=80, seed=5, extent=1.5)
    @test [node.id for node in kk_nodes] == ["a", "b", "c", "d"]
    @test all(-1.5 <= node.x <= 1.5 for node in kk_nodes)
    @test all(-1.5 <= node.y <= 1.5 for node in kk_nodes)
    @test length(Set((round(node.x, digits=6), round(node.y, digits=6)) for node in kk_nodes)) == 4

    fa2_nodes = force_directed_layout(layout_nodes, edges; algorithm=:forceatlas2, iterations=80, seed=5, extent=1.5)
    @test [node.id for node in fa2_nodes] == ["a", "b", "c", "d"]
    @test all(-1.5 <= node.x <= 1.5 for node in fa2_nodes)
    @test all(-1.5 <= node.y <= 1.5 for node in fa2_nodes)
    @test length(Set((round(node.x, digits=6), round(node.y, digits=6)) for node in fa2_nodes)) == 4

    circular_viz = render(layout_nodes, edges; layout=:circular)
    @test circular_viz isa SigmaGraph
    @test all(isapprox(sqrt(node.x^2 + node.y^2), 1.0; atol=1.0e-8) for node in circular_viz.nodes)

    force_viz = render(
        layout_nodes,
        edges;
        layout=:force_directed,
        algorithm=:kamada_kawai,
        iterations=60,
        seed=13,
        extent=1.2,
    )
    @test force_viz isa SigmaGraph
    @test all(-1.2 <= node.x <= 1.2 for node in force_viz.nodes)
    @test all(-1.2 <= node.y <= 1.2 for node in force_viz.nodes)

    custom_viz = render(layout_nodes, edges; layout=(nodes, edges; shift=0.0) -> [
        NodeSpec(node.id; x=index + shift, y=-index, size=node.size, label=node.label, color=node.color, attributes=node.attributes)
        for (index, node) in pairs(nodes)
    ], shift=3.0)
    @test [node.x for node in custom_viz.nodes] == [4.0, 5.0, 6.0, 7.0]
    @test [node.y for node in custom_viz.nodes] == [-1.0, -2.0, -3.0, -4.0]

    @test_throws "Unsupported force-directed algorithm" force_directed_layout(layout_nodes, edges; algorithm=:unknown)

    html = sprint(show, MIME"text/html"(), viz)
    @test occursin("large-graphs-jl-root", html)
    @test occursin("window.LargeGraphsJL.render", html)
    @test occursin("void window.LargeGraphsJL.render", html)
    @test occursin("Loading Sigma.js", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))
    @test occursin("root.__largeGraphsJlRenderToken", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))
    @test occursin("root.__largeGraphsJlSigma.kill()", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))
    @test occursin("defaultMaxActiveViews = 4", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))
    @test occursin("Graph paused to keep the notebook responsive", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))
    @test occursin("window.LargeGraphsJLMaxActiveViews", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))
    @test occursin("Paused Preview", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))
    @test occursin("Reactivate graph", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))
    @test occursin("drawFallbackPreview", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))
    @test occursin("createPreview(root, stage)", read(joinpath(pkgdir(LargeGraphsJL), "assets", "sigma-viewer.js"), String))

    tempdir = mktempdir()
    output = joinpath(tempdir, "graph.html")
    savehtml(output, positioned_nodes, [(source="a", target="b", color="#94a3b8")]; height="480px")
    exported = read(output, String)
    @test occursin("<!doctype html>", exported)
    @test occursin("large-graphs-jl-root", exported)
end
