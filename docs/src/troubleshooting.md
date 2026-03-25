# Troubleshooting

## Package import problems

If `using LargeGraphs` fails in a notebook, the notebook kernel is probably
running a different environment than the one where the package was installed.
Activate the intended environment explicitly in the notebook.

## Blank or partial output

The viewer is bootstrapped in the browser. Check the browser developer console
for JavaScript errors and failed network requests.

## Exported HTML does not render offline

Standalone HTML export still loads Sigma.js and Graphology from a CDN. Offline
viewing or restrictive network policies can prevent the graph from rendering.

## Graph quality issues

Try one of the built-in layouts first:

- `layout=:random` for a quick spread
- `layout=:circular` for small ordered graphs
- `layout=:grid` for regular overviews
- `layout=:tree` for rooted trees and forests
- `layout=:spring` for Fruchterman-Reingold structure-aware layouts
- `layout=:force_directed` with `algorithm=:sfdp` as the first fast structure-aware option
- `layout=:force_directed` with `algorithm=:kamada_kawai` or `:forceatlas2` for alternative legacy structure-aware layouts

If the result is still poor, provide explicit coordinates or a custom layout
callable before rendering.

## Large-graph performance

Browser memory and GPU performance remain the main limits. Reducing labels and
keeping node sizes modest usually helps more than increasing canvas size.
Force-directed algorithms also have a quadratic repulsion step, so they scale
much worse than `:random`, `:circular`, or `:grid`.
