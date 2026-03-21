module LargeGraphsIJuliaExt

using IJulia
using LargeGraphs

const INTERACTION_TARGET = "largegraphs_events"
const STATE_REGISTRY = Dict{String, LargeGraphs.InteractionState}()
const TARGET_REGISTERED = Ref(false)

function LargeGraphs._interaction_bridge(state::LargeGraphs.InteractionState)
    _register_target!()
    LargeGraphs._register_interaction_state!(state)
    STATE_REGISTRY[state.id] = state
    return Dict(
        "targetName" => INTERACTION_TARGET,
        "sessionId" => state.id,
    )
end

function _register_target!()
    TARGET_REGISTERED[] && return nothing
    TARGET_REGISTERED[] = true
    nothing
end

function IJulia.CommManager.register_comm(comm::IJulia.Comm{:largegraphs_events}, msg)
    data = get(msg.content, "data", Dict{String, Any}())
    session_id = get(data, "sessionId", nothing)

    comm.on_msg = incoming -> begin
        incoming_data = get(incoming.content, "data", Dict{String, Any}())
        incoming_session_id = get(incoming_data, "sessionId", session_id)
        if !isnothing(incoming_session_id) && haskey(STATE_REGISTRY, incoming_session_id)
            LargeGraphs._apply_interaction_event!(STATE_REGISTRY[incoming_session_id], incoming_data)
        end
        nothing
    end

    comm.on_close = incoming -> begin
        incoming_data = get(incoming.content, "data", Dict{String, Any}())
        incoming_session_id = get(incoming_data, "sessionId", session_id)
        if !isnothing(incoming_session_id) && haskey(STATE_REGISTRY, incoming_session_id)
            LargeGraphs._apply_interaction_event!(
                STATE_REGISTRY[incoming_session_id],
                Dict("eventType" => "disconnected", "timestamp" => time()),
            )
        end
        nothing
    end

    if !isnothing(session_id) && haskey(STATE_REGISTRY, session_id)
        LargeGraphs._apply_interaction_event!(
            STATE_REGISTRY[session_id],
            Dict("eventType" => "connected", "timestamp" => time()),
        )
    end

    nothing
end

end
