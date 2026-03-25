# Rendering Benchmark Summary

Generated from:
- `raw/latest.json`
- `raw/summary-20260324-083632.json`

## Overview

| Scenario | Nodes | Edges | Faster backend | Total speedup | Smaller artifact | Size ratio | Largest stage share |
| --- | ---: | ---: | --- | ---: | --- | ---: | --- |
| `smoke_erdos_renyi` | `erdos_renyi` | 120 | 222 | 0.0311 | GraphMakie | 2.82x | LargeGraphs | 7.05x | export_ms (71.9%) |
| `smoke_preferential_attachment` | `preferential_attachment` | 180 | 885 | 0.0549 | GraphMakie | 2.55x | LargeGraphs | 21.97x | export_ms (73.1%) |

## Scenario Details

### smoke_erdos_renyi

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| GraphMakie | 60.23 | 60.23 | 0.2 | 435.5 KiB | `export_ms` 43.32 ms (71.9%), `plot_ms` 16.87 ms (28.0%) |
| LargeGraphs | 169.61 | 170.59 | 1.3 | 61.7 KiB | `assemble_ms` 0.03 ms (0.0%), `export_ms` 3.63 ms (2.1%), `layout_ms` 166.51 ms (98.2%) |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 43.32 | 43.36 | 71.9% | 0.2 |
| `plot_ms` | 16.87 | 16.86 | 28.0% | 0.3 |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.03 | 0.03 | 0.0% | 5.9 |
| `export_ms` | 3.63 | 3.38 | 2.1% | 24.9 |
| `layout_ms` | 166.51 | 167.19 | 98.2% | 1.0 |

`GraphMakie` was faster overall by 2.82x. Its largest timed stage was `export_ms` at 71.9% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 7.05x.

### smoke_preferential_attachment

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| GraphMakie | 159.25 | 159.18 | 0.1 | 2.61 MiB | `export_ms` 116.36 ms (73.1%), `plot_ms` 42.77 ms (26.9%) |
| LargeGraphs | 405.72 | 405.18 | 0.3 | 121.7 KiB | `assemble_ms` 0.06 ms (0.0%), `export_ms` 7.04 ms (1.7%), `layout_ms` 397.89 ms (98.1%) |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 116.36 | 116.37 | 73.1% | 0.2 |
| `plot_ms` | 42.77 | 42.8 | 26.9% | 0.2 |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.06 | 0.06 | 0.0% | 2.0 |
| `export_ms` | 7.04 | 7.27 | 1.7% | 6.0 |
| `layout_ms` | 397.89 | 397.85 | 98.1% | 0.3 |

`GraphMakie` was faster overall by 2.55x. Its largest timed stage was `export_ms` at 73.1% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 21.97x.

## Notes

- Timings are split by backend stage and then summed into `total_ms`.
- `Trimmed mean` drops the fastest and slowest sample when at least three timed samples are available.
- `CV (%)` highlights run-to-run stability; lower values indicate steadier measurements.
- Overview speedups and winners are based on total `trimmed mean` so one noisy sample does not dominate the comparison.
