"""
    savehtml(path, graph::SigmaGraph)
    savehtml(path, nodes, edges; kwargs...)

Write a standalone HTML document containing the graph viewer.
"""
function savehtml(path::AbstractString, value::SigmaGraph)
    open(path, "w") do io
        write(io, _standalone_html(value))
    end
    path
end

function savehtml(path::AbstractString, nodes, edges; kwargs...)
    savehtml(path, render(nodes, edges; kwargs...))
end

function Base.show(io::IO, ::MIME"text/html", value::SigmaGraph)
    print(io, _html(value))
end

function Base.show(io::IO, ::MIME"text/plain", value::SigmaGraph)
    print(io, "SigmaGraph($(length(value.nodes)) nodes, $(length(value.edges)) edges)")
end

function _graph_payload(value::SigmaGraph)
    (
        id=value.id,
        nodes=[_node_payload(node) for node in value.nodes],
        edges=[_edge_payload(edge) for edge in value.edges],
        config=_config_payload(value.config),
        interaction=value.interaction,
    )
end

function _node_payload(node::NodeSpec)
    merge(
        Dict{String, Any}(
            "id" => node.id,
            "x" => node.x,
            "y" => node.y,
            "size" => node.size,
        ),
        isnothing(node.label) ? Dict{String, Any}() : Dict("label" => node.label),
        isnothing(node.color) ? Dict{String, Any}() : Dict("color" => node.color),
        node.attributes,
    )
end

function _edge_payload(edge::EdgeSpec)
    merge(
        Dict{String, Any}(
            "key" => edge.id,
            "source" => edge.source,
            "target" => edge.target,
            "size" => edge.size,
        ),
        isnothing(edge.label) ? Dict{String, Any}() : Dict("label" => edge.label),
        isnothing(edge.color) ? Dict{String, Any}() : Dict("color" => edge.color),
        edge.attributes,
    )
end

function _config_payload(config::SigmaConfig)
    Dict(
        "width" => config.width,
        "height" => config.height,
        "background" => config.background,
        "cameraRatio" => config.camera_ratio,
        "renderEdgeLabels" => config.render_edge_labels,
        "hideEdgesOnMove" => config.hide_edges_on_move,
        "labelDensity" => config.label_density,
        "labelGridCellSize" => config.label_grid_cell_size,
        "maxNodeSize" => config.max_node_size,
        "minNodeSize" => config.min_node_size,
    )
end

function _html(value::SigmaGraph)
    payload = JSON3.write(_graph_payload(value))
    bootstrap = read(joinpath(pkgdir(@__MODULE__), "assets", "sigma-viewer.js"), String)
    """
    <div id="$(value.id)" class="large-graphs-jl-root" style="width: $(value.config.width);">
      <div class="large-graphs-jl-stage" style="width: 100%; height: $(value.config.height); background: $(value.config.background);"></div>
    </div>
    <script type="application/json" id="$(value.id)-payload">$(payload)</script>
    <script>
    $(bootstrap)
    void window.LargeGraphs.render("$(value.id)");
    </script>
    """
end

function _standalone_html(value::SigmaGraph)
    """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>LargeGraphs Demo</title>
    </head>
    <body>
    $(_html(value))
    </body>
    </html>
    """
end
