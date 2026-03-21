function _normalize_nodes(nodes)
    result = NodeSpec[]
    for item in nodes
        push!(result, _node(item))
    end
    result
end

function _normalize_edges(edges)
    result = EdgeSpec[]
    for item in edges
        push!(result, _edge(item))
    end
    result
end

_node(value::NodeSpec) = value
_edge(value::EdgeSpec) = value

function _node(value::NamedTuple)
    NodeSpec(
        _required_get(value, :id, "Node tuples must define :id");
        x=get(value, :x, 0.0),
        y=get(value, :y, 0.0),
        size=get(value, :size, 1.0),
        label=get(value, :label, nothing),
        color=get(value, :color, nothing),
        attributes=get(value, :attributes, Dict{String, Any}()),
    )
end

function _edge(value::NamedTuple)
    EdgeSpec(
        _required_get(value, :source, "Edge tuples must define :source"),
        _required_get(value, :target, "Edge tuples must define :target");
        id=get(value, :id, nothing),
        size=get(value, :size, 1.0),
        label=get(value, :label, nothing),
        color=get(value, :color, nothing),
        attributes=get(value, :attributes, Dict{String, Any}()),
    )
end

function _node(value::AbstractDict)
    NodeSpec(
        _coalesce_keys(value, "id", :id, "Node dicts must define id");
        x=_coalesce_keys(value, "x", :x, 0.0),
        y=_coalesce_keys(value, "y", :y, 0.0),
        size=_coalesce_keys(value, "size", :size, 1.0),
        label=_coalesce_keys(value, "label", :label, nothing),
        color=_coalesce_keys(value, "color", :color, nothing),
        attributes=_coalesce_keys(value, "attributes", :attributes, Dict{String, Any}()),
    )
end

function _edge(value::AbstractDict)
    EdgeSpec(
        _coalesce_keys(value, "source", :source, "Edge dicts must define source"),
        _coalesce_keys(value, "target", :target, "Edge dicts must define target");
        id=_coalesce_keys(value, "id", :id, nothing),
        size=_coalesce_keys(value, "size", :size, 1.0),
        label=_coalesce_keys(value, "label", :label, nothing),
        color=_coalesce_keys(value, "color", :color, nothing),
        attributes=_coalesce_keys(value, "attributes", :attributes, Dict{String, Any}()),
    )
end

function _node(value::Tuple)
    length(value) >= 3 || error("Tuple nodes must be (id, x, y, ...)")
    NodeSpec(value[1]; x=value[2], y=value[3], size=length(value) >= 4 ? value[4] : 1.0, label=length(value) >= 5 ? value[5] : nothing)
end

function _edge(value::Tuple)
    length(value) >= 2 || error("Tuple edges must be (source, target, ...)")
    EdgeSpec(value[1], value[2]; size=length(value) >= 3 ? value[3] : 1.0, label=length(value) >= 4 ? value[4] : nothing)
end
