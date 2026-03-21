"""
    LargeGraphs

Render interactive Sigma.js graph visualizations from Julia data structures,
with notebook-friendly HTML output and standalone HTML export.
"""
module LargeGraphs

using JSON3
using LinearAlgebra
using Random
using UUIDs

export EdgeSpec, NodeSpec, SigmaConfig, SigmaGraph, circular_layout, force_directed_layout, graph, grid_layout, random_layout, render, savehtml, spectral_layout, spring_layout, tree_layout

include("types.jl")
include("normalize.jl")
include("layouts.jl")
include("rendering.jl")
include("api.jl")
include("utils.jl")

end
