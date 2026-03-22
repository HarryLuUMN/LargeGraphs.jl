# Smoke Benchmark Summary

Generated from:
- `benchmarks/results/raw/latest.json`
- `benchmarks/results/raw/summary-20260322-121741.json`

## Scenarios

### smoke_erdos_renyi
- Nodes: 120
- Edges: 222
- LargeGraphs
  - Mean: 181.39 ms
  - Artifact size: 63,034 bytes
- GraphMakie
  - Mean: 221.87 ms
  - Artifact size: 445,905 bytes

Observation:
- In this sparse small graph case, LargeGraphs was faster and produced a much smaller artifact.

### smoke_preferential_attachment
- Nodes: 180
- Edges: 885
- LargeGraphs
  - Mean: 403.69 ms
  - Artifact size: 124,534 bytes
- GraphMakie
  - Mean: 276.31 ms
  - Artifact size: 2,736,298 bytes

Observation:
- In this denser small-to-medium graph case, GraphMakie was faster in this first smoke run, while LargeGraphs still produced a much smaller artifact.

## Notes
- This is a smoke benchmark, not a final benchmark campaign.
- It validates that the benchmark scaffold works and produces structured outputs.
- The current benchmark measures end-to-end artifact generation rather than isolating layout time from rendering time.
- Next steps should separate layout and render costs and add larger graph scenarios.
