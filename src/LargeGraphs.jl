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

export EdgeSpec, GraphEvent, InteractionState, NodeSpec, SigmaConfig, SigmaGraph, assemble_graph, circular_layout, clear!, force_directed_layout, graph, grid_layout, hovered_node, interaction_events, layout_graph, orthogonal_layout, random_layout, render, savehtml, selected_neighbors, selected_node, spectral_layout, spring_layout, tree_layout

include("types.jl")
include("interactions.jl")
include("normalize.jl")
include("layouts.jl")
include("rendering.jl")
include("api.jl")
include("utils.jl")

end
