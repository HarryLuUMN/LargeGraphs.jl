using Graphs
using LargeGraphs
using Random

function gallery_cases()
    [
        (
            slug="circular-overview",
            title="Circular Overview",
            category="Layouts",
            description="A compact ring-and-spoke example using the built-in circular layout for fast structural inspection.",
            build=build_circular_overview,
        ),
        (
            slug="layered-hierarchy",
            title="Layered Hierarchy",
            category="Layouts",
            description="A staged pipeline example that applies the tree layout to a directed hierarchy and exports it as a presentation-ready view.",
            build=build_layered_hierarchy,
        ),
        (
            slug="styled-teams",
            title="Styled Teams",
            category="Styling",
            description="A small showcase of labels, palette choices, edge emphasis, and the presentation profile.",
            build=build_styled_teams,
        ),
        (
            slug="interactive-neighborhoods",
            title="Interactive Neighborhoods",
            category="Interaction",
            description="A standalone export with tooltips, click selection, and neighbor highlighting enabled for lightweight exploration.",
            build=build_interactive_neighborhoods,
        ),
        (
            slug="large-graphsjl-overview",
            title="Large Graphs.jl Overview",
            category="Scale",
            description="A larger graph rendered from a `Graphs.jl` object with the recommended fast force-directed path and large-graph profile.",
            build=build_large_graphsjl_overview,
        ),
        (
            slug="dense-spectral-map",
            title="Dense Spectral Map",
            category="Density",
            description="A denser graph rendered with the spectral layout and dense profile to show the low-cost path recommended for edge-heavy structure.",
            build=build_dense_spectral_map,
        ),
        (
            slug="cheap-50k-preview",
            title="50k Cheap Preview",
            category="Scale",
            description="A 50,000-node showcase that uses a cheap random layout, sparse labeling, and the large profile to keep the export practical.",
            build=build_cheap_50k_preview,
        ),
        (
            slug="gpu-experimental-layout",
            title="GPU Experimental Layout",
            category="Experimental",
            description="A force-directed case that requests the experimental CUDA backend and still exports cleanly on machines that fall back to CPU.",
            build=build_gpu_experimental_layout,
        ),
        (
            slug="pipeline-runtime-comparison",
            title="Pipeline Runtime Comparison",
            category="Pipeline",
            description="A measured staged-vs-one-shot example that turns layout, assemble, render, and export timings into a presentation-friendly comparison view.",
            build=build_pipeline_runtime_comparison,
        ),
    ]
end

function build_circular_overview()
    nodes = [
        (id="hub", label="Hub", size=4.5, color="#0f172a"),
        (id="n1", label="Search", size=2.2, color="#2563eb"),
        (id="n2", label="Pipelines", size=2.0, color="#0ea5e9"),
        (id="n3", label="Exports", size=2.0, color="#0891b2"),
        (id="n4", label="Metrics", size=2.2, color="#14b8a6"),
        (id="n5", label="Docs", size=1.9, color="#22c55e"),
        (id="n6", label="Benchmarks", size=2.1, color="#84cc16"),
        (id="n7", label="Sharing", size=2.0, color="#f59e0b"),
        (id="n8", label="Reports", size=2.1, color="#f97316"),
    ]
    edges = vcat(
        [(source="hub", target="n$i", size=1.3, color="#cbd5e1") for i in 1:8],
        [(source="n$i", target="n$(i == 8 ? 1 : i + 1)", size=0.7, color="#94a3b8") for i in 1:8],
    )

    render(
        nodes,
        edges;
        layout=:circular,
        radius=2.6,
        height="680px",
        background="#f8fafc",
        profile=:presentation,
    )
end

function build_layered_hierarchy()
    nodes = [
        (id="root", label="LargeGraphs", size=4.2, color="#1d4ed8"),
        (id="pipeline", label="Pipeline", size=2.6, color="#2563eb"),
        (id="layouts", label="Layouts", size=2.4, color="#0f766e"),
        (id="export", label="Export", size=2.4, color="#7c3aed"),
        (id="docs", label="Docs", size=2.2, color="#ea580c"),
        (id="layout_graph", label="layout_graph", size=1.7, color="#60a5fa"),
        (id="assemble_graph", label="assemble_graph", size=1.7, color="#60a5fa"),
        (id="render", label="render", size=1.7, color="#60a5fa"),
        (id="sfdp", label=":sfdp", size=1.7, color="#34d399"),
        (id="tree", label="tree_layout", size=1.7, color="#34d399"),
        (id="savehtml", label="savehtml", size=1.7, color="#c084fc"),
        (id="offline", label="offline export", size=1.7, color="#c084fc"),
        (id="readme", label="README", size=1.6, color="#fb923c"),
        (id="documenter", label="Documenter", size=1.6, color="#fb923c"),
    ]
    edges = [
        (source="root", target="pipeline", size=1.2, color="#cbd5e1"),
        (source="root", target="layouts", size=1.2, color="#cbd5e1"),
        (source="root", target="export", size=1.2, color="#cbd5e1"),
        (source="root", target="docs", size=1.2, color="#cbd5e1"),
        (source="pipeline", target="layout_graph", size=0.9, color="#93c5fd"),
        (source="pipeline", target="assemble_graph", size=0.9, color="#93c5fd"),
        (source="pipeline", target="render", size=0.9, color="#93c5fd"),
        (source="layouts", target="sfdp", size=0.9, color="#86efac"),
        (source="layouts", target="tree", size=0.9, color="#86efac"),
        (source="export", target="savehtml", size=0.9, color="#d8b4fe"),
        (source="export", target="offline", size=0.9, color="#d8b4fe"),
        (source="docs", target="readme", size=0.9, color="#fdba74"),
        (source="docs", target="documenter", size=0.9, color="#fdba74"),
    ]

    layouted = layout_graph(nodes, edges; layout=:tree, algorithm=:layered, root="root", sibling_gap=1.2, level_gap=1.1)
    assemble_graph(
        layouted;
        config=SigmaConfig(height="760px", background="#f8fafc", profile=:presentation),
    )
end

function build_styled_teams()
    nodes = [
        (id="north-1", label="North / A", size=3.4, color="#1d4ed8"),
        (id="north-2", label="North / B", size=2.6, color="#3b82f6"),
        (id="north-3", label="North / C", size=2.2, color="#93c5fd"),
        (id="south-1", label="South / A", size=3.4, color="#0f766e"),
        (id="south-2", label="South / B", size=2.6, color="#14b8a6"),
        (id="south-3", label="South / C", size=2.2, color="#99f6e4"),
        (id="ops", label="Ops", size=3.0, color="#7c3aed"),
        (id="design", label="Design", size=2.8, color="#db2777"),
    ]
    edges = [
        (source="north-1", target="north-2", size=1.8, color="#60a5fa"),
        (source="north-2", target="north-3", size=1.2, color="#93c5fd"),
        (source="south-1", target="south-2", size=1.8, color="#2dd4bf"),
        (source="south-2", target="south-3", size=1.2, color="#99f6e4"),
        (source="north-1", target="ops", size=1.0, color="#a78bfa"),
        (source="south-1", target="ops", size=1.0, color="#a78bfa"),
        (source="ops", target="design", size=1.1, color="#f472b6"),
        (source="design", target="north-3", size=0.9, color="#f9a8d4"),
        (source="design", target="south-3", size=0.9, color="#f9a8d4"),
    ]

    render(
        nodes,
        edges;
        layout=:force_directed,
        algorithm=:sfdp,
        iterations=80,
        seed=11,
        height="700px",
        background="#fffdf8",
        profile=:presentation,
        render_edge_labels=false,
    )
end

function build_interactive_neighborhoods()
    nodes = [
        (id="a", label="Alpha", size=3.4, color="#2563eb"),
        (id="b", label="Beta", size=2.6, color="#0ea5e9"),
        (id="c", label="Gamma", size=2.4, color="#14b8a6"),
        (id="d", label="Delta", size=2.2, color="#22c55e"),
        (id="e", label="Epsilon", size=2.1, color="#84cc16"),
        (id="f", label="Zeta", size=2.4, color="#eab308"),
        (id="g", label="Eta", size=2.6, color="#f97316"),
        (id="h", label="Theta", size=2.8, color="#ef4444"),
        (id="i", label="Iota", size=2.2, color="#ec4899"),
        (id="j", label="Kappa", size=2.0, color="#8b5cf6"),
    ]
    edges = [
        (source="a", target="b", size=1.1, color="#94a3b8"),
        (source="a", target="c", size=1.1, color="#94a3b8"),
        (source="a", target="d", size=1.1, color="#94a3b8"),
        (source="b", target="e", size=0.9, color="#94a3b8"),
        (source="c", target="f", size=0.9, color="#94a3b8"),
        (source="d", target="g", size=0.9, color="#94a3b8"),
        (source="e", target="h", size=0.9, color="#cbd5e1"),
        (source="f", target="h", size=0.9, color="#cbd5e1"),
        (source="g", target="i", size=0.9, color="#cbd5e1"),
        (source="h", target="j", size=0.9, color="#cbd5e1"),
        (source="i", target="j", size=0.9, color="#cbd5e1"),
    ]

    graph(
        nodes,
        edges;
        layout=:force_directed,
        algorithm=:forceatlas2,
        iterations=70,
        seed=5,
        config=SigmaConfig(height="720px", background="#f8fafc", profile=:default),
        enable_selection=true,
        enable_tooltips=true,
        highlight_neighbors=true,
    )
end

function build_large_graphsjl_overview(; node_count=900, extra_edges=2200, seed=7)
    rng = MersenneTwister(seed)
    g = SimpleGraph(node_count)

    for vertex in 2:node_count
        add_edge!(g, vertex - 1, vertex)
        anchor = rand(rng, 1:vertex - 1)
        add_edge!(g, vertex, anchor)
    end

    while ne(g) < node_count - 1 + extra_edges
        source = rand(rng, 1:nv(g))
        target = rand(rng, 1:nv(g))
        source == target && continue
        add_edge!(g, source, target)
    end

    render(
        g;
        layout=:force_directed,
        algorithm=:sfdp,
        iterations=90,
        seed=seed,
        profile=:large,
        height="820px",
        background="#f8fafc",
        node_mapper=vertex -> (
            id="v$vertex",
            label=vertex <= 80 ? "v$vertex" : nothing,
            size=vertex <= 25 ? 2.8 : 1.4,
            color=vertex <= 25 ? "#1d4ed8" : "#38bdf8",
        ),
        edge_mapper=edge -> (
            source="v$(src(edge))",
            target="v$(dst(edge))",
            size=0.35,
            color="#cbd5e1",
        ),
    )
end

function build_dense_spectral_map(; cluster_count=5, cluster_size=26, seed=21)
    rng = MersenneTwister(seed)
    total_nodes = cluster_count * cluster_size
    nodes = [
        (
            id="v$vertex",
            label=vertex <= 24 ? "v$vertex" : nothing,
            size=vertex <= 10 ? 2.8 : 1.5,
            color=_cluster_palette()[cld(vertex, cluster_size)],
        )
        for vertex in 1:total_nodes
    ]

    g = SimpleGraph(total_nodes)
    for cluster in 0:cluster_count-1
        start_vertex = cluster * cluster_size + 1
        stop_vertex = start_vertex + cluster_size - 1
        for source in start_vertex:stop_vertex
            for target in source + 1:stop_vertex
                rand(rng) <= 0.32 && add_edge!(g, source, target)
            end
        end
    end

    for left_cluster in 1:cluster_count-1
        for right_cluster in left_cluster + 1:cluster_count
            bridge_count = left_cluster + right_cluster <= cluster_count + 1 ? 5 : 3
            for _ in 1:bridge_count
                source = rand(rng, ((left_cluster - 1) * cluster_size + 1):(left_cluster * cluster_size))
                target = rand(rng, ((right_cluster - 1) * cluster_size + 1):(right_cluster * cluster_size))
                add_edge!(g, source, target)
            end
        end
    end

    render(
        g;
        layout=:spectral,
        seed=seed,
        profile=:dense,
        height="820px",
        background="#f8fafc",
        node_mapper=vertex -> nodes[vertex],
        edge_mapper=edge -> (
            source="v$(src(edge))",
            target="v$(dst(edge))",
            size=0.28,
            color=cld(src(edge), cluster_size) == cld(dst(edge), cluster_size) ? "#94a3b8" : "#64748b",
        ),
    )
end

function build_cheap_50k_preview(; node_count=50_000, seed=12)
    g = SimpleGraph(node_count)
    for vertex in 2:node_count
        add_edge!(g, vertex - 1, vertex)
    end
    for vertex in 1:500:node_count-500
        add_edge!(g, vertex, min(node_count, vertex + 500))
    end

    render(
        g;
        layout=:random,
        seed=seed,
        profile=:large,
        height="900px",
        background="#f8fafc",
        hide_edges_on_move=true,
        render_edge_labels=false,
        node_mapper=vertex -> (
            id="v$vertex",
            label=vertex % 5000 == 1 ? "v$vertex" : nothing,
            size=vertex % 5000 == 1 ? 2.2 : 0.8,
            color=vertex % 5000 == 1 ? "#1d4ed8" : "#60a5fa",
        ),
        edge_mapper=edge -> (
            source="v$(src(edge))",
            target="v$(dst(edge))",
            size=0.05,
            color="#cbd5e1",
        ),
    )
end

function build_gpu_experimental_layout(; seed=9)
    nodes = [
        (id="hub", label="hub", size=4.4, color="#111827"),
        (id="etl", label="ETL", size=2.4, color="#2563eb"),
        (id="warehouse", label="Warehouse", size=2.6, color="#1d4ed8"),
        (id="serve", label="Serve", size=2.3, color="#0f766e"),
        (id="dash", label="Dashboards", size=2.1, color="#14b8a6"),
        (id="ml", label="ML", size=2.2, color="#7c3aed"),
        (id="alerts", label="Alerts", size=2.0, color="#db2777"),
        (id="ops", label="Ops", size=2.0, color="#ea580c"),
        (id="auth", label="Auth", size=1.8, color="#f59e0b"),
        (id="audit", label="Audit", size=1.8, color="#84cc16"),
        (id="cache", label="Cache", size=1.8, color="#38bdf8"),
        (id="queue", label="Queue", size=1.8, color="#8b5cf6"),
    ]
    edges = [
        (source="hub", target="etl", size=1.1, color="#cbd5e1"),
        (source="hub", target="warehouse", size=1.1, color="#cbd5e1"),
        (source="hub", target="serve", size=1.1, color="#cbd5e1"),
        (source="warehouse", target="dash", size=0.9, color="#94a3b8"),
        (source="warehouse", target="ml", size=0.9, color="#94a3b8"),
        (source="serve", target="alerts", size=0.9, color="#94a3b8"),
        (source="serve", target="ops", size=0.9, color="#94a3b8"),
        (source="auth", target="serve", size=0.8, color="#fcd34d"),
        (source="audit", target="warehouse", size=0.8, color="#bef264"),
        (source="cache", target="serve", size=0.8, color="#7dd3fc"),
        (source="queue", target="etl", size=0.8, color="#c4b5fd"),
        (source="etl", target="warehouse", size=0.9, color="#60a5fa"),
        (source="etl", target="queue", size=0.8, color="#a78bfa"),
        (source="ml", target="dash", size=0.8, color="#c4b5fd"),
        (source="ops", target="alerts", size=0.8, color="#fdba74"),
    ]

    render(
        nodes,
        edges;
        layout=:force_directed,
        algorithm=:fruchterman_reingold,
        backend=:gpu,
        iterations=140,
        seed=seed,
        profile=:presentation,
        height="760px",
        background="#0b1120",
        max_node_size=14.0,
        render_edge_labels=false,
    )
end

function build_pipeline_runtime_comparison(; node_count=220, extra_edges=520, seed=14)
    nodes, edges = _pipeline_case_graph(node_count, extra_edges; seed=seed)
    report = profile_pipeline(
        nodes,
        edges;
        layout=:force_directed,
        layout_kwargs=(algorithm=:sfdp, iterations=70, seed=seed),
        assemble_kwargs=(config=SigmaConfig(profile=:dense, height="760px", background="#f8fafc"),),
        render_kwargs=(profile=:dense, height="760px", background="#f8fafc"),
    )

    stage_nodes = [
        (id="layout", label="layout\n$(_ms(report.layout.seconds))", size=4.1, color="#2563eb"),
        (id="assemble", label="assemble\n$(_ms(report.assemble.seconds))", size=3.4, color="#14b8a6"),
        (id="render", label="render\n$(_ms(report.render.seconds))", size=3.4, color="#7c3aed"),
        (id="total-staged", label="staged total\n$(_ms(report.layout.seconds + report.assemble.seconds))", size=4.4, color="#0f172a"),
        (id="one-shot", label="one-shot render\n$(_ms(report.render.seconds))", size=4.0, color="#ea580c"),
        (id="export", label="offline export\nnot measured in gallery build", size=3.0, color="#64748b"),
    ]
    stage_edges = [
        (source="layout", target="assemble", size=1.4, color="#93c5fd"),
        (source="assemble", target="total-staged", size=1.5, color="#5eead4"),
        (source="render", target="one-shot", size=1.5, color="#c4b5fd"),
        (source="total-staged", target="export", size=1.1, color="#cbd5e1"),
        (source="one-shot", target="export", size=1.1, color="#cbd5e1"),
        (source="layout", target="render", size=0.8, color="#94a3b8"),
    ]

    positioned = layout_graph(stage_nodes, stage_edges; layout=:grid, columns=3, spacing=1.8)
    assemble_graph(
        positioned;
        config=SigmaConfig(height="760px", background="#f8fafc", profile=:presentation),
    )
end

function _cluster_palette()
    ["#1d4ed8", "#0f766e", "#7c3aed", "#ea580c", "#db2777", "#0891b2"]
end

function _pipeline_case_graph(node_count, extra_edges; seed)
    rng = MersenneTwister(seed)
    nodes = [
        (
            id="n$vertex",
            label=vertex <= 14 ? "n$vertex" : nothing,
            size=vertex <= 6 ? 2.7 : 1.5,
            color=vertex <= 40 ? "#2563eb" : "#60a5fa",
        )
        for vertex in 1:node_count
    ]
    edges = [(source="n$(vertex - 1)", target="n$vertex", size=0.35, color="#cbd5e1") for vertex in 2:node_count]

    target_edge_count = length(edges) + extra_edges
    seen = Set{Tuple{Int, Int}}((min(vertex - 1, vertex), max(vertex - 1, vertex)) for vertex in 2:node_count)
    while length(edges) < target_edge_count
        source = rand(rng, 1:node_count)
        target = rand(rng, 1:node_count)
        source == target && continue
        key = (min(source, target), max(source, target))
        key in seen && continue
        push!(seen, key)
        push!(edges, (source="n$source", target="n$target", size=0.3, color="#94a3b8"))
    end

    nodes, edges
end

_ms(seconds) = string(round(seconds * 1000; digits=1), " ms")
