"""
    savehtml(path, graph::SigmaGraph; self_contained=true, runtime=:auto)
    savehtml(path, nodes, edges; kwargs...)

Write a standalone HTML document containing the graph viewer.

When `self_contained=true`, the export embeds an offline canvas runtime that
does not fetch Sigma.js from a CDN.
"""
function savehtml(path::AbstractString, value::SigmaGraph; self_contained=true, runtime=:auto)
    open(path, "w") do io
        write(io, _standalone_html(value; self_contained=self_contained, runtime=runtime))
    end
    path
end

function savehtml(path::AbstractString, nodes, edges; self_contained=true, runtime=:auto, kwargs...)
    savehtml(path, render(nodes, edges; kwargs...); self_contained=self_contained, runtime=runtime)
end

function Base.show(io::IO, ::MIME"text/html", value::SigmaGraph)
    print(io, _html(value))
end

function Base.show(io::IO, ::MIME"text/plain", value::SigmaGraph)
    print(io, "SigmaGraph($(length(value.nodes)) nodes, $(length(value.edges)) edges)")
end

function _graph_payload(value::SigmaGraph)
    coordinate_step = _coordinate_quantization_step(value.nodes)
    _trim_payload_numbers((
        id=value.id,
        nodes=[_node_payload(node; coordinate_step=coordinate_step) for node in value.nodes],
        edges=[_edge_payload(edge) for edge in value.edges],
        config=_config_payload(value.config),
        interaction=value.interaction,
    ))
end

function _node_payload(node::NodeSpec; coordinate_step::Float64)
    merge(
        Dict{String, Any}(
            "id" => node.id,
            "x" => _quantize_coordinate(node.x, coordinate_step),
            "y" => _quantize_coordinate(node.y, coordinate_step),
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

function _coordinate_quantization_step(nodes)
    isempty(nodes) && return 0.0
    min_x = minimum(node.x for node in nodes)
    max_x = maximum(node.x for node in nodes)
    min_y = minimum(node.y for node in nodes)
    max_y = maximum(node.y for node in nodes)
    span = max(max_x - min_x, max_y - min_y, 1.0)
    span / 16_384
end

_quantize_coordinate(value::Real, step::Float64) = step <= 0 ? Float64(value) : round(Float64(value) / step) * step

function _trim_payload_numbers(value)
    value isa AbstractDict && return Dict{String, Any}(string(key) => _trim_payload_numbers(entry) for (key, entry) in pairs(value))
    value isa NamedTuple && return Dict{String, Any}(string(key) => _trim_payload_numbers(entry) for (key, entry) in pairs(value))
    value isa AbstractVector && return [_trim_payload_numbers(entry) for entry in value]
    value isa AbstractFloat && return _trim_float(value)
    value isa Real && return value
    value
end

function _trim_float(value::AbstractFloat)
    isfinite(value) || return value
    rounded = round(Float64(value); digits=6)
    abs(rounded) < 5.0e-7 && return 0.0
    rounded
end

function _html(value::SigmaGraph; runtime=:sigma)
    graph_id = _escape_html_attribute(value.id)
    payload_id = _escape_html_attribute("$(value.id)-payload")
    payload = _escape_script_data(JSON3.write(_graph_payload(value)))
    bootstrap, invocation = _runtime_bootstrap(runtime, value.id)
    """
    <div id="$(graph_id)" class="large-graphs-jl-root" style="width: $(_escape_html_attribute(value.config.width));">
      <div class="large-graphs-jl-stage" style="width: 100%; height: $(_escape_html_attribute(value.config.height)); background: $(_escape_html_attribute(value.config.background));"></div>
    </div>
    <script type="application/json" id="$(payload_id)">$(payload)</script>
    <script>
    $(bootstrap)
    $(invocation)
    </script>
    """
end

function _standalone_html(value::SigmaGraph; self_contained=true, runtime=:auto)
    resolved_runtime = _resolve_export_runtime(runtime; self_contained=self_contained)
    """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>LargeGraphs Demo</title>
    </head>
    <body>
    $(_html(value; runtime=resolved_runtime))
    </body>
    </html>
    """
end

_resolve_export_runtime(runtime::Symbol; self_contained::Bool) = runtime === :auto ? (self_contained ? :offline_canvas : :sigma) : runtime

function _runtime_bootstrap(runtime::Symbol, id::String)
    runtime === :sigma && return (
        read(joinpath(pkgdir(@__MODULE__), "assets", "sigma-viewer.js"), String),
        "void window.LargeGraphs.render(\"$(_escape_javascript_string(id))\");",
    )
    runtime === :offline_canvas && return (
        read(joinpath(pkgdir(@__MODULE__), "assets", "offline-viewer.js"), String),
        "void window.LargeGraphsOffline.render(\"$(_escape_javascript_string(id))\");",
    )
    error("Unsupported HTML runtime: $(runtime)")
end

function _escape_html_attribute(value)
    escaped = replace(string(value), "&" => "&amp;")
    escaped = replace(escaped, "\"" => "&quot;")
    escaped = replace(escaped, "<" => "&lt;")
    replace(escaped, ">" => "&gt;")
end

function _escape_javascript_string(value)
    escaped = replace(string(value), "\\" => "\\\\")
    escaped = replace(escaped, "\"" => "\\\"")
    escaped = replace(escaped, "\n" => "\\n")
    escaped = replace(escaped, "\r" => "\\r")
    replace(escaped, "</" => "<\\/")
end

function _escape_script_data(value)
    replace(string(value), "</" => "<\\/")
end
