"""
    savehtml(path, graph::SigmaGraph; self_contained=true, runtime=:auto)
    savehtml(path, nodes, edges; kwargs...)

Write a standalone HTML document containing the graph viewer.

When `self_contained=true`, the export embeds an offline canvas runtime that
does not fetch Sigma.js from a CDN unless the `SigmaGraph` already stores an
explicit runtime such as `:sigma` or `:webgpu`.
"""
function savehtml(path::AbstractString, value::SigmaGraph; self_contained=true, runtime=:auto)
    open(path, "w") do io
        _write_standalone_html(io, value; self_contained=self_contained, runtime=runtime)
    end
    path
end

function savehtml(path::AbstractString, nodes, edges; self_contained=true, runtime=:auto, kwargs...)
    savehtml(path, render(nodes, edges; runtime=runtime, kwargs...); self_contained=self_contained, runtime=runtime)
end

function Base.show(io::IO, ::MIME"text/html", value::SigmaGraph)
    _write_html(io, value; runtime=value.runtime)
end

function Base.show(io::IO, ::MIME"text/plain", value::SigmaGraph)
    print(io, "SigmaGraph($(length(value.nodes)) nodes, $(length(value.edges)) edges, runtime=$(value.runtime))")
end

function _graph_payload(value::SigmaGraph)
    coordinate_step = _coordinate_quantization_step(value.nodes)
    Dict{String, Any}(
        "id" => value.id,
        "nodes" => [_node_payload(node; coordinate_step=coordinate_step) for node in value.nodes],
        "edges" => [_edge_payload(edge) for edge in value.edges],
        "config" => _config_payload(value.config),
        "interaction" => _trim_payload_value(value.interaction),
    )
end

function _node_payload(node::NodeSpec; coordinate_step::Float64)
    payload = Dict{String, Any}()
    payload["id"] = node.id
    payload["x"] = _trim_float(_quantize_coordinate(node.x, coordinate_step))
    payload["y"] = _trim_float(_quantize_coordinate(node.y, coordinate_step))
    node.size != 1.0 && (payload["size"] = _trim_payload_value(node.size))
    !isnothing(node.label) && (payload["label"] = node.label)
    !isnothing(node.color) && (payload["color"] = node.color)
    _append_payload_attributes!(payload, node.attributes)
    payload
end

function _edge_payload(edge::EdgeSpec)
    payload = Dict{String, Any}()
    payload["key"] = edge.id
    payload["source"] = edge.source
    payload["target"] = edge.target
    edge.size != 1.0 && (payload["size"] = _trim_payload_value(edge.size))
    !isnothing(edge.label) && (payload["label"] = edge.label)
    !isnothing(edge.color) && (payload["color"] = edge.color)
    _append_payload_attributes!(payload, edge.attributes)
    payload
end

function _config_payload(config::SigmaConfig)
    payload = Dict{String, Any}()
    config.background != "#ffffff" && (payload["background"] = config.background)
    config.camera_ratio != 1.0 && (payload["cameraRatio"] = _trim_payload_value(config.camera_ratio))
    config.render_edge_labels != false && (payload["renderEdgeLabels"] = config.render_edge_labels)
    config.hide_edges_on_move != false && (payload["hideEdgesOnMove"] = config.hide_edges_on_move)
    config.label_density != 1.0 && (payload["labelDensity"] = _trim_payload_value(config.label_density))
    config.label_grid_cell_size != 80 && (payload["labelGridCellSize"] = config.label_grid_cell_size)
    config.max_node_size != 16.0 && (payload["maxNodeSize"] = _trim_payload_value(config.max_node_size))
    config.min_node_size != 2.0 && (payload["minNodeSize"] = _trim_payload_value(config.min_node_size))
    payload
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

function _append_payload_attributes!(payload::Dict{String, Any}, attributes)
    for (key, entry) in pairs(attributes)
        payload[string(key)] = _trim_payload_value(entry)
    end
    payload
end

function _trim_payload_value(value)
    value isa AbstractDict && return Dict{String, Any}(string(key) => _trim_payload_value(entry) for (key, entry) in pairs(value))
    value isa NamedTuple && return Dict{String, Any}(string(key) => _trim_payload_value(entry) for (key, entry) in pairs(value))
    value isa AbstractVector && return [_trim_payload_value(entry) for entry in value]
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

function _write_html(io::IO, value::SigmaGraph; runtime=:sigma)
    resolved_runtime = _resolve_display_runtime(runtime)
    graph_id = _escape_html_attribute(value.id)
    payload_id = _escape_html_attribute("$(value.id)-payload")
    payload = _escape_script_data(JSON3.write(_graph_payload(value)))
    bootstrap, invocation = _runtime_bootstrap(resolved_runtime, value.id)
    print(io, """
    <div id="$(graph_id)" class="large-graphs-jl-root" style="width: $(_escape_html_attribute(value.config.width));">
      <div class="large-graphs-jl-stage" style="width: 100%; height: $(_escape_html_attribute(value.config.height)); background: $(_escape_html_attribute(value.config.background));"></div>
    </div>
    <script type="application/json" id="$(payload_id)">$(payload)</script>
    <script>
    $(bootstrap)
    $(invocation)
    </script>
    """)
end

function _write_standalone_html(io::IO, value::SigmaGraph; self_contained=true, runtime=:auto)
    resolved_runtime = _resolve_export_runtime(runtime, value.runtime; self_contained=self_contained)
    print(io, """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>LargeGraphs Demo</title>
    </head>
    <body>
    """)
    _write_html(io, value; runtime=resolved_runtime)
    print(io, """
    </body>
    </html>
    """)
end

function _resolve_display_runtime(runtime)
    normalized = _normalize_runtime(runtime)
    normalized === :auto ? :sigma : normalized
end

function _resolve_export_runtime(runtime, graph_runtime; self_contained::Bool)
    requested_runtime = _normalize_runtime(runtime)
    persisted_runtime = _normalize_runtime(graph_runtime)
    requested_runtime !== :auto && return requested_runtime
    persisted_runtime !== :auto && return persisted_runtime
    self_contained ? :offline_canvas : :sigma
end

const _RUNTIME_ASSETS = Dict{Symbol, String}()

function _runtime_bootstrap(runtime::Symbol, id::String)
    if runtime === :sigma
        return (
            _runtime_asset(:shared) * "\n" * _runtime_asset(:sigma),
            "void window.LargeGraphs.render(\"$(_escape_javascript_string(id))\");",
        )
    end
    if runtime === :webgpu
        return (
            _runtime_asset(:shared) * "\n" * _runtime_asset(:webgpu),
            "void window.LargeGraphsWebGPU.render(\"$(_escape_javascript_string(id))\");",
        )
    end
    runtime === :offline_canvas && return (
        _runtime_asset(:offline_canvas),
        "void window.LargeGraphsOffline.render(\"$(_escape_javascript_string(id))\");",
    )
    error("Unsupported HTML runtime: $(runtime)")
end

function _runtime_asset(runtime::Symbol)
    get!(_RUNTIME_ASSETS, runtime) do
        filename = runtime === :shared ? "runtime-core.js" :
            runtime === :sigma ? "sigma-viewer.js" :
            runtime === :webgpu ? "webgpu-viewer.js" :
            runtime === :offline_canvas ? "offline-viewer.js" :
            error("Unsupported HTML runtime: $(runtime)")
        read(joinpath(pkgdir(@__MODULE__), "assets", filename), String)
    end
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
