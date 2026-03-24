"""
    LargeGraphs

Render interactive Sigma.js graph visualizations from Julia data structures,
with notebook-friendly HTML output and standalone HTML export.
"""
module LargeGraphs

using Graphs
using JSON3
using LinearAlgebra
using Random
using UUIDs

export EdgeSpec, GraphEvent, InteractionState, NodeSpec, SigmaConfig, SigmaGraph, assemble_graph, circular_layout, clear!, edge_attribute_mapper, force_directed_layout, graph, grid_layout, hierarchy_layout, hovered_node, interaction_events, layout_graph, orthogonal_layout, profile_pipeline, random_layout, recommend_profile, render, savehtml, selected_neighbors, selected_node, spectral_layout, spring_layout, timed_assemble, timed_export, timed_layout, timed_render, tree_layout, vertex_attribute_mapper

include("types.jl")
include("interactions.jl")
include("normalize.jl")
include("layouts.jl")
include("rendering.jl")
include("api.jl")
include("utils.jl")

end
