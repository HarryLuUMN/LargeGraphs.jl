using Test
using LargeGraphs
using Graphs

@testset "LargeGraphs" begin
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

    tree_nodes = [
        (id="root", label="Root", color="#2563eb"),
        (id="left", label="Left", color="#059669"),
        (id="right", label="Right", color="#d97706"),
        (id="left-left", label="LeftLeft", color="#7c3aed"),
        (id="left-right", label="LeftRight", color="#db2777"),
        (id="right-left", label="RightLeft", color="#0891b2"),
    ]

    tree_edges = [
        (source="root", target="left", color="#94a3b8"),
        (source="root", target="right", color="#94a3b8"),
        (source="left", target="left-left", color="#94a3b8"),
        (source="left", target="left-right", color="#94a3b8"),
        (source="right", target="right-left", color="#94a3b8"),
    ]

    viz = render(positioned_nodes, [(source="a", target="b", color="#94a3b8")])

    @test viz isa SigmaGraph
    @test render(viz) === viz
    @test length(viz.nodes) == 2
    @test length(viz.edges) == 1

    dense_config = SigmaConfig(profile=:dense)
    @test dense_config.hide_edges_on_move == true
    @test dense_config.label_density == 0.6
    @test dense_config.max_node_size == 12.0
    @test dense_config.min_node_size == 1.5

    presentation_config = SigmaConfig(profile=:presentation, label_density=0.8)
    @test presentation_config.render_edge_labels == true
    @test presentation_config.label_density == 0.8
    @test_throws "Unknown profile" SigmaConfig(profile=:unknown)

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

    orthogonal_nodes = orthogonal_layout(layout_nodes, edges; extent=2.0, layer_spacing=1.0)
    @test [node.id for node in orthogonal_nodes] == ["a", "b", "c", "d"]
    @test all(-2.0 <= node.x <= 2.0 for node in orthogonal_nodes)
    @test all(-2.0 <= node.y <= 2.0 for node in orthogonal_nodes)
    @test length(Set((round(node.x, digits=6), round(node.y, digits=6)) for node in orthogonal_nodes)) == 4
    @test length(Set(round(node.x, digits=6) for node in orthogonal_nodes)) > 1
    @test length(Set(round(node.y, digits=6) for node in orthogonal_nodes)) > 1

    spectral_nodes = spectral_layout(layout_nodes, edges; extent=1.5, seed=5)
    @test [node.id for node in spectral_nodes] == ["a", "b", "c", "d"]
    @test all(-1.5 <= node.x <= 1.5 for node in spectral_nodes)
    @test all(-1.5 <= node.y <= 1.5 for node in spectral_nodes)
    @test length(Set((round(node.x, digits=6), round(node.y, digits=6)) for node in spectral_nodes)) >= 2

    layered_tree_nodes = tree_layout(tree_nodes, tree_edges; algorithm=:layered, root="root", extent=1.5)
    layered_depths = Dict(node.id => node.y for node in layered_tree_nodes)
    @test [node.id for node in layered_tree_nodes] == ["root", "left", "right", "left-left", "left-right", "right-left"]
    @test layered_depths["root"] > layered_depths["left"]
    @test layered_depths["left"] > layered_depths["left-left"]
    @test layered_depths["left"] > layered_depths["left-right"]
    @test layered_depths["right"] > layered_depths["right-left"]
    @test all(-1.5 <= node.x <= 1.5 for node in layered_tree_nodes)
    @test all(-1.5 <= node.y <= 1.5 for node in layered_tree_nodes)

    radial_tree_nodes = tree_layout(tree_nodes, tree_edges; algorithm=:radial, root="root", extent=1.5)
    radial_radii = Dict(node.id => sqrt(node.x^2 + node.y^2) for node in radial_tree_nodes)
    @test radial_radii["root"] < radial_radii["left"]
    @test radial_radii["root"] < radial_radii["right"]
    @test radial_radii["left-left"] > radial_radii["left"]
    @test radial_radii["left-right"] > radial_radii["left"]
    @test radial_radii["right-left"] > radial_radii["right"]
    @test all(-1.5 <= node.x <= 1.5 for node in radial_tree_nodes)
    @test all(-1.5 <= node.y <= 1.5 for node in radial_tree_nodes)

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

    orthogonal_viz = render(layout_nodes, edges; layout=:orthogonal, extent=1.2, layer_spacing=1.0)
    @test orthogonal_viz isa SigmaGraph
    @test all(-1.2 <= node.x <= 1.2 for node in orthogonal_viz.nodes)
    @test all(-1.2 <= node.y <= 1.2 for node in orthogonal_viz.nodes)

    spectral_viz = render(layout_nodes, edges; layout=:spectral, extent=1.2, seed=13)
    @test spectral_viz isa SigmaGraph
    @test all(-1.2 <= node.x <= 1.2 for node in spectral_viz.nodes)
    @test all(-1.2 <= node.y <= 1.2 for node in spectral_viz.nodes)

    tree_viz = render(tree_nodes, tree_edges; layout=:tree, algorithm=:layered, root="root", extent=1.2)
    @test tree_viz isa SigmaGraph
    @test tree_viz.nodes[1].y > tree_viz.nodes[2].y
    @test all(-1.2 <= node.x <= 1.2 for node in tree_viz.nodes)
    @test all(-1.2 <= node.y <= 1.2 for node in tree_viz.nodes)

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

    staged_layout = layout_graph(layout_nodes, edges; layout=:grid, columns=2)
    @test keys(staged_layout) == (:nodes, :edges)
    @test staged_layout.nodes isa Vector{NodeSpec}
    @test staged_layout.edges isa Vector{EdgeSpec}
    @test Set((node.x, node.y) for node in staged_layout.nodes) == Set([
        (-0.5, 0.5),
        (0.5, 0.5),
        (-0.5, -0.5),
        (0.5, -0.5),
    ])

    staged_viz = assemble_graph(staged_layout; id="staged", config=SigmaConfig(height="480px"))
    @test staged_viz isa SigmaGraph
    @test staged_viz.id == "staged"
    @test staged_viz.config.height == "480px"
    @test [node.id for node in staged_viz.nodes] == ["a", "b", "c", "d"]

    staged_parts_viz = assemble_graph(staged_layout.nodes, staged_layout.edges; id="staged-parts")
    @test staged_parts_viz isa SigmaGraph
    @test staged_parts_viz.id == "staged-parts"

    staged_profiled_viz = assemble_graph(staged_layout; id="staged-profiled", profile=:large)
    @test staged_profiled_viz.config.hide_edges_on_move == true
    @test staged_profiled_viz.config.label_density == 0.35

    staged_profiled_custom = assemble_graph(
        staged_layout;
        id="staged-profiled-custom",
        profile=:dense,
        config=SigmaConfig(height="460px", background="#f8fafc"),
    )
    @test staged_profiled_custom.config.height == "460px"
    @test staged_profiled_custom.config.background == "#f8fafc"
    @test staged_profiled_custom.config.hide_edges_on_move == true

    custom_viz = render(layout_nodes, edges; layout=(nodes, edges; shift=0.0) -> [
        NodeSpec(node.id; x=index + shift, y=-index, size=node.size, label=node.label, color=node.color, attributes=node.attributes)
        for (index, node) in pairs(nodes)
    ], shift=3.0)
    @test [node.x for node in custom_viz.nodes] == [4.0, 5.0, 6.0, 7.0]
    @test [node.y for node in custom_viz.nodes] == [-1.0, -2.0, -3.0, -4.0]

    graph_input = SimpleGraph(4)
    add_edge!(graph_input, 1, 2)
    add_edge!(graph_input, 2, 3)
    add_edge!(graph_input, 3, 4)

    graph_viz = render(graph_input; layout=:circular)
    @test graph_viz isa SigmaGraph
    @test [node.id for node in graph_viz.nodes] == ["1", "2", "3", "4"]
    @test Set((edge.source, edge.target) for edge in graph_viz.edges) == Set([("1", "2"), ("2", "3"), ("3", "4")])

    profiled_render = render(layout_nodes, edges; profile=:large)
    @test profiled_render.config.hide_edges_on_move == true
    @test profiled_render.config.label_density == 0.35

    overridden_profiled_render = render(layout_nodes, edges; profile=:large, label_density=0.9)
    @test overridden_profiled_render.config.label_density == 0.9

    profiled_graph = graph(layout_nodes, edges; profile=:dense)
    @test profiled_graph.config.hide_edges_on_move == true
    @test profiled_graph.config.label_density == 0.6

    mapped_graph = graph(
        graph_input;
        node_mapper=vertex -> (id="v$(vertex)", label="Node $(vertex)", size=vertex + 0.5, color=vertex % 2 == 0 ? "#2563eb" : "#059669"),
        edge_mapper=edge -> (source="v$(src(edge))", target="v$(dst(edge))", size=0.4, color="#94a3b8", label="$(src(edge))->$(dst(edge))"),
        layout=:grid,
        columns=2,
    )
    @test mapped_graph isa SigmaGraph
    @test [node.id for node in mapped_graph.nodes] == ["v1", "v2", "v3", "v4"]
    @test mapped_graph.nodes[2].label == "Node 2"
    @test mapped_graph.nodes[4].size == 4.5
    @test all(edge.label !== nothing for edge in mapped_graph.edges)
    @test Set((node.x, node.y) for node in mapped_graph.nodes) == Set([
        (-0.5, 0.5),
        (0.5, 0.5),
        (-0.5, -0.5),
        (0.5, -0.5),
    ])

    staged_graph_input = layout_graph(
        graph_input;
        layout=:grid,
        node_mapper=vertex -> (id="g$(vertex)", label="Graph $(vertex)"),
        edge_mapper=edge -> (source="g$(src(edge))", target="g$(dst(edge))"),
        columns=2,
    )
    @test [node.id for node in staged_graph_input.nodes] == ["g1", "g2", "g3", "g4"]
    @test all(startswith(edge.source, "g") for edge in staged_graph_input.edges)

    interaction_state = InteractionState()
    @test selected_node(interaction_state) === nothing
    @test hovered_node(interaction_state) === nothing
    @test isempty(selected_neighbors(interaction_state))
    @test isempty(interaction_events(interaction_state))
    @test interaction_state.connected == false

    bridge = LargeGraphs._interaction_bridge(interaction_state)
    @test bridge["targetName"] == "largegraphs_events"
    @test bridge["sessionId"] == interaction_state.id

    LargeGraphs._apply_interaction_event!(interaction_state, Dict("eventType" => "connected", "timestamp" => 1.0))
    @test interaction_state.connected == true

    LargeGraphs._apply_interaction_event!(interaction_state, Dict("eventType" => "hover", "nodeId" => "b", "neighborIds" => ["a", "c"], "timestamp" => 2.0))
    @test hovered_node(interaction_state) == "b"
    @test interaction_events(interaction_state)[end].event_type == :hover

    LargeGraphs._apply_interaction_event!(interaction_state, Dict("eventType" => "select", "nodeId" => "b", "neighborIds" => ["a", "c"], "timestamp" => 3.0))
    @test selected_node(interaction_state) == "b"
    @test selected_neighbors(interaction_state) == ["a", "c"]

    LargeGraphs._apply_interaction_event!(interaction_state, Dict("eventType" => "leave", "nodeId" => "b", "timestamp" => 4.0))
    @test hovered_node(interaction_state) === nothing

    LargeGraphs._apply_interaction_event!(interaction_state, Dict("eventType" => "clear_selection", "timestamp" => 5.0))
    @test selected_node(interaction_state) === nothing
    @test isempty(selected_neighbors(interaction_state))

    clear!(interaction_state)
    @test isempty(interaction_events(interaction_state))

    interactive_viz = render(layout_nodes, edges; interaction_state=InteractionState(), layout=:grid, columns=2)
    @test interactive_viz.interaction["enableSelection"] == true
    @test interactive_viz.interaction["enableTooltips"] == true
    @test interactive_viz.interaction["highlightNeighbors"] == true
    @test interactive_viz.interaction["bridge"]["targetName"] == "largegraphs_events"

    @test_throws "Unsupported force-directed algorithm" force_directed_layout(layout_nodes, edges; algorithm=:unknown)
    @test_throws "Unsupported tree layout algorithm" tree_layout(tree_nodes, tree_edges; algorithm=:unknown)
    @test_throws "Unknown tree root" tree_layout(tree_nodes, tree_edges; root="missing")
    @test_throws "Edges reference node ids that are missing from the node list" render([(id="1",)], [(source="1", target="2")])
    @test_throws "Duplicate node ids are not supported" render([(id="1",), (id="1",)], [(source="1", target="1")])

    html = sprint(show, MIME"text/html"(), viz)
    @test occursin("large-graphs-jl-root", html)
    @test occursin("window.LargeGraphs.render", html)
    @test occursin("void window.LargeGraphs.render", html)
    @test occursin("Loading Sigma.js", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("root.__largeGraphsJlRenderToken", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("root.__largeGraphsJlSigma.kill()", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("defaultMaxActiveViews = 4", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("Graph paused to keep the notebook responsive", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("window.LargeGraphsMaxActiveViews", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("Paused Preview", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("Reactivate graph", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("drawFallbackPreview", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("createPreview(root, stage)", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("aria-label\", \"Fit view\"", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("Lock camera", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("Unlock camera", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("toggleCameraLock", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("camera.animate", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("setCustomBBox", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("ratio: 1", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("new_comm", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("largegraphs:interaction", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("enterNode", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("clickNode", read(joinpath(pkgdir(LargeGraphs), "assets", "sigma-viewer.js"), String))
    @test occursin("enableTooltips", html)
    @test occursin("highlightNeighbors", html)

    escaped_viz = render(
        [(id="unsafe\"id", x=0.0, y=0.0, label="</script><script>alert(1)</script>")],
        EdgeSpec[];
        id="unsafe\"id",
    )
    escaped_html = sprint(show, MIME"text/html"(), escaped_viz)
    @test occursin("unsafe&quot;id", escaped_html)
    @test occursin("<\\/script><script>alert(1)<\\/script>", escaped_html)
    @test !occursin("</script><script>alert(1)</script>", escaped_html)
    @test occursin("""window.LargeGraphs.render("unsafe\\\"id")""", escaped_html)

    tempdir = mktempdir()
    output = joinpath(tempdir, "graph.html")
    savehtml(output, positioned_nodes, [(source="a", target="b", color="#94a3b8")]; height="480px")
    exported = read(output, String)
    @test occursin("<!doctype html>", exported)
    @test occursin("large-graphs-jl-root", exported)
end
