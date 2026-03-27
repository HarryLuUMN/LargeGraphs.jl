using Dates
using LargeGraphs

const GALLERY_ROOT = normpath(joinpath(@__DIR__, ".."))
const BUILD_DIR = joinpath(GALLERY_ROOT, "build")
const BUILD_CASES_DIR = joinpath(BUILD_DIR, "cases")
const BUILD_ASSETS_DIR = joinpath(BUILD_DIR, "assets")

include(joinpath(GALLERY_ROOT, "src", "GalleryCases.jl"))

function build_gallery(; clean=true)
    clean && isdir(BUILD_DIR) && rm(BUILD_DIR; recursive=true, force=true)
    mkpath(BUILD_CASES_DIR)
    mkpath(BUILD_ASSETS_DIR)
    cp(joinpath(GALLERY_ROOT, "src", "index.css"), joinpath(BUILD_ASSETS_DIR, "index.css"); force=true)

    built_cases = NamedTuple[]
    for case in gallery_cases()
        output_name = string(case.slug, ".html")
        output_path = joinpath(BUILD_CASES_DIR, output_name)
        savehtml(output_path, case.build(); self_contained=true)
        push!(built_cases, merge(case, (href=joinpath("cases", output_name),)))
    end

    write(joinpath(BUILD_DIR, "index.html"), gallery_index_html(built_cases))
    BUILD_DIR
end

function gallery_index_html(cases)
    cards = join([
        """
        <article class="card">
          <div class="tag">$(_escape_html(case.category))</div>
          <h2>$(_escape_html(case.title))</h2>
          <p>$(_escape_html(case.description))</p>
          <div class="actions">
            <a class="button primary" href="$(_escape_html(case.href))">Open case</a>
            <a class="button secondary" href="#build-notes">Build notes</a>
          </div>
        </article>
        """
        for case in cases
    ], "\n")

    generated_at = Dates.format(now(), dateformat"yyyy-mm-dd HH:MM")

    """
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>LargeGraphs Gallery</title>
      <link rel="stylesheet" href="assets/index.css" />
    </head>
    <body>
      <main class="page">
        <section class="hero">
          <p class="eyebrow">LargeGraphs.jl gallery</p>
          <h1>Static showcase outputs built outside the docs pipeline.</h1>
          <p>
            This gallery is a lightweight static site generated from the package's existing
            rendering APIs. It is meant for browseable exports and deployment, while
            <code>examples/</code> remains tutorial-focused.
          </p>
          <div class="meta">
            <span>Build output: <code>gallery/build/</code></span>
            <span>Cases: <code>$(length(cases))</code></span>
            <span>Generated: <code>$(_escape_html(generated_at))</code></span>
          </div>
        </section>

        <h2 class="section-title">Curated cases</h2>
        <section class="cards">
          $(cards)
        </section>

        <p class="footer" id="build-notes">
          Rebuild from the repository root with <code>julia --project=. gallery/scripts/build_gallery.jl</code>.
          Publish the contents of <code>gallery/build/</code> with any static host.
          For repository-level guidance, see <code>gallery/README.md</code> and the docs/README links in the project root.
        </p>
      </main>
    </body>
    </html>
    """
end

function _escape_html(value)
    escaped = replace(string(value), "&" => "&amp;")
    escaped = replace(escaped, "<" => "&lt;")
    escaped = replace(escaped, ">" => "&gt;")
    replace(escaped, "\"" => "&quot;")
end

if abspath(PROGRAM_FILE) == @__FILE__
    println(build_gallery())
end
