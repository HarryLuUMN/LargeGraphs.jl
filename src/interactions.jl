"""
    GraphEvent

Event record captured from notebook graph interactions.
"""
struct GraphEvent
    event_type::Symbol
    node_id::Union{Nothing, String}
    neighbor_ids::Vector{String}
    timestamp::Float64
end

"""
    InteractionState(; id="interaction-...")

State container for notebook interaction events.

Pass this to `render(...; interaction_state=state)` or
`graph(...; interaction_state=state)` to enable Julia-side event updates when
the graph is displayed in IJulia.
"""
mutable struct InteractionState
    id::String
    selected_node::Union{Nothing, String}
    hovered_node::Union{Nothing, String}
    selected_neighbors::Vector{String}
    events::Vector{GraphEvent}
    connected::Bool
end

InteractionState(; id=string("interaction-", uuid4())) = InteractionState(string(id), nothing, nothing, String[], GraphEvent[], false)

const INTERACTION_STATE_REGISTRY = Dict{String, InteractionState}()

"""
    selected_node(state)

Return the currently selected node id, or `nothing`.
"""
selected_node(state::InteractionState) = state.selected_node
"""
    hovered_node(state)

Return the node id currently under the cursor, or `nothing`.
"""
hovered_node(state::InteractionState) = state.hovered_node
"""
    selected_neighbors(state)

Return the ids of the currently selected node's neighbors.
"""
selected_neighbors(state::InteractionState) = copy(state.selected_neighbors)
"""
    interaction_events(state)

Return a copy of the recorded interaction events.
"""
interaction_events(state::InteractionState) = copy(state.events)

"""
    clear!(state)

Clear the interaction state and recorded event log.
"""
function clear!(state::InteractionState)
    state.selected_node = nothing
    state.hovered_node = nothing
    empty!(state.selected_neighbors)
    empty!(state.events)
    state
end

function _register_interaction_state!(state::InteractionState)
    INTERACTION_STATE_REGISTRY[state.id] = state
    state
end

function _receive_interaction_event(session_id, data)
    state = get(INTERACTION_STATE_REGISTRY, string(session_id), nothing)
    isnothing(state) && return nothing
    _apply_interaction_event!(state, data)
end

function Base.show(io::IO, ::MIME"text/plain", state::InteractionState)
    print(
        io,
        "InteractionState(selected=",
        isnothing(state.selected_node) ? "nothing" : repr(state.selected_node),
        ", hovered=",
        isnothing(state.hovered_node) ? "nothing" : repr(state.hovered_node),
        ", neighbors=$(length(state.selected_neighbors)), events=$(length(state.events)), connected=$(state.connected))",
    )
end

function _interaction_payload(state; enable_selection=true, enable_tooltips=true, highlight_neighbors=true)
    payload = Dict{String, Any}(
        "enableSelection" => Bool(enable_selection),
        "enableTooltips" => Bool(enable_tooltips),
        "highlightNeighbors" => Bool(highlight_neighbors),
    )
    if !isnothing(state)
        _register_interaction_state!(state)
        payload["sessionId"] = state.id
        bridge = _interaction_bridge(state)
        !isnothing(bridge) && (payload["bridge"] = bridge)
    end
    payload
end

_interaction_bridge(::Any) = nothing

function _apply_interaction_event!(state::InteractionState, data)
    event_type = _interaction_event_type(data)
    node_id = _interaction_event_node_id(data)
    neighbor_ids = _interaction_event_neighbor_ids(data)
    timestamp = _interaction_event_timestamp(data)

    if event_type === :connected
        state.connected = true
    elseif event_type === :disconnected
        state.connected = false
    elseif event_type === :hover
        state.hovered_node = node_id
    elseif event_type === :leave
        state.hovered_node = nothing
    elseif event_type === :select
        state.selected_node = node_id
        state.selected_neighbors = neighbor_ids
    elseif event_type === :clear_selection
        state.selected_node = nothing
        empty!(state.selected_neighbors)
    end

    push!(state.events, GraphEvent(event_type, node_id, neighbor_ids, timestamp))
    state
end

function _interaction_event_type(data)
    raw = if data isa AbstractDict
        if haskey(data, "eventType")
            data["eventType"]
        elseif haskey(data, :eventType)
            data[:eventType]
        else
            "unknown"
        end
    else
        "unknown"
    end
    Symbol(replace(lowercase(strip(string(raw))), " " => "_"))
end

function _interaction_event_node_id(data)
    if data isa AbstractDict
        if haskey(data, "nodeId")
            return _string_or_nothing(data["nodeId"])
        elseif haskey(data, :nodeId)
            return _string_or_nothing(data[:nodeId])
        end
    end
    nothing
end

function _interaction_event_neighbor_ids(data)
    values = if data isa AbstractDict
        if haskey(data, "neighborIds")
            data["neighborIds"]
        elseif haskey(data, :neighborIds)
            data[:neighborIds]
        else
            String[]
        end
    else
        String[]
    end
    [string(value) for value in values]
end

function _interaction_event_timestamp(data)
    raw = if data isa AbstractDict
        if haskey(data, "timestamp")
            data["timestamp"]
        elseif haskey(data, :timestamp)
            data[:timestamp]
        else
            nothing
        end
    else
        nothing
    end
    isnothing(raw) && return time()
    try
        Float64(raw)
    catch
        time()
    end
end
