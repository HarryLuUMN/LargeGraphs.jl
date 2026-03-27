# LargeGraphs Gallery

The `gallery/` area is the package showcase for standalone, browseable output.
It complements `examples/`, which remains focused on tutorial and workflow
walkthroughs.

## What lives here

- `src/` contains gallery case definitions and the static site stylesheet.
- `scripts/build_gallery.jl` builds the static gallery site.
- `build/` contains generated HTML ready for static hosting or repository browsing.

## Build the gallery

From the repository root:

```bash
julia --project=. gallery/scripts/build_gallery.jl
```

The build writes a static index plus standalone case exports under
`gallery/build/`.

## Deploy the gallery

Publish the contents of `gallery/build/` with any static file host or artifact
deployment flow. The gallery build is intentionally separate from
`docs/make.jl`, so documentation publishing can link to the gallery without
needing to generate it.

## Current status

This first gallery pass includes curated cases for:

- built-in layout styles
- styling and presentation-oriented configuration
- client-side interaction affordances
- a larger `Graphs.jl` rendering case

The structure is intentionally small so new showcase cases can be added by
editing one source file and rerunning the build script.
