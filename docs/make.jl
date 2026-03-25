using Documenter
using LargeGraphs

makedocs(
    sitename = "LargeGraphs.jl",
    modules = [LargeGraphs],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", "false") == "true"),
    pages = [
        "Home" => "index.md",
        "Pipeline Guide" => "pipeline.md",
        "Choose a Layout" => "layout-guide.md",
        "API Reference" => "api.md",
        "Notebook Guide" => "notebooks.md",
        "Troubleshooting" => "troubleshooting.md",
    ],
)

deploydocs(
    repo = "github.com/HarryLuUMN/LargeGraphs.jl.git",
    devbranch = "master",
)
