using Documenter
using LargeGraphsJL

makedocs(
    sitename = "LargeGraphsJL.jl",
    modules = [LargeGraphsJL],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", "false") == "true"),
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
        "Notebook Guide" => "notebooks.md",
        "Troubleshooting" => "troubleshooting.md",
    ],
)

deploydocs(
    repo = "github.com/HarryLuUMN/LargeGraphs.jl.git",
    devbranch = "master",
)
