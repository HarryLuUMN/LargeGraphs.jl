# Rendering Benchmark Summary

Generated from:
- `raw/latest.json`
- `raw/summary-20260322-152214.json`

## Overview

| Scenario | Nodes | Edges | Faster backend | Speedup | Smaller artifact | Size ratio |
| --- | ---: | ---: | --- | ---: | --- | ---: |
| `smoke_erdos_renyi` | 120 | 222 | GraphMakie | 2.55x | LargeGraphs | 7.05x |
| `smoke_preferential_attachment` | 180 | 885 | GraphMakie | 2.56x | LargeGraphs | 21.97x |

## Scenario Details

### smoke_erdos_renyi

| Backend | Mean (ms) | Trimmed mean (ms) | Median (ms) | Std (ms) | CV (%) | Artifact |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| GraphMakie | 53.04 | 53.05 | 53.05 | 0.18 | 0.3 | 435.5 KiB |
| LargeGraphs | 134.2 | 135.02 | 135.02 | 2.05 | 1.5 | 61.7 KiB |

`GraphMakie` was faster in this scenario by 2.55x, while `LargeGraphs` produced the smaller artifact by 7.05x.

### smoke_preferential_attachment

| Backend | Mean (ms) | Trimmed mean (ms) | Median (ms) | Std (ms) | CV (%) | Artifact |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| GraphMakie | 131.54 | 131.46 | 131.46 | 0.76 | 0.6 | 2.61 MiB |
| LargeGraphs | 337.6 | 336.05 | 336.05 | 2.8 | 0.8 | 121.7 KiB |

`GraphMakie` was faster in this scenario by 2.56x, while `LargeGraphs` produced the smaller artifact by 21.97x.

## Notes

- Timings are end-to-end artifact generation times measured after warmup runs.
- `Trimmed mean` drops the fastest and slowest sample when at least three timed samples are available.
- `CV (%)` highlights run-to-run stability; lower values indicate steadier measurements.
- Overview speedups and winners are based on `trimmed mean` so one noisy sample does not dominate the comparison.
