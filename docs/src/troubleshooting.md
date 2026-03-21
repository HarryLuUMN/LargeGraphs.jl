# Troubleshooting

## Package import problems

If `using LargeGraphsJL` fails in a notebook, the notebook kernel is probably
running a different environment than the one where the package was installed.
Activate the intended environment explicitly in the notebook.

## Blank or partial output

The viewer is bootstrapped in the browser. Check the browser developer console
for JavaScript errors and failed network requests.

## Exported HTML does not render offline

Standalone HTML export still loads Sigma.js and Graphology from a CDN. Offline
viewing or restrictive network policies can prevent the graph from rendering.

## Graph quality issues

This package does not compute graph layouts. If nodes overlap or cluster poorly,
improve the input coordinates before rendering.

## Large-graph performance

Browser memory and GPU performance remain the main limits. Reducing labels and
keeping node sizes modest usually helps more than increasing canvas size.
