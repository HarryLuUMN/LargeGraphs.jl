# Rendering Benchmark Summary

Generated from:
- `raw/latest.json`
- `raw/summary-20260323-220454.json`

## Overview

| Scenario | Nodes | Edges | Faster backend | Total speedup | Smaller artifact | Size ratio | Largest stage share |
| --- | ---: | ---: | --- | ---: | --- | ---: | --- |
| `smoke_erdos_renyi` | `erdos_renyi` | 120 | 222 | 0.0311 | GraphMakie | 2.94x | LargeGraphs | 7.05x | export_ms (72.0%) |
| `smoke_preferential_attachment` | `preferential_attachment` | 180 | 885 | 0.0549 | GraphMakie | 2.62x | LargeGraphs | 21.97x | export_ms (73.1%) |

## Scenario Details

### smoke_erdos_renyi

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| GraphMakie | 59.9 | 59.54 | 1.3 | 435.5 KiB | `export_ms` 43.13 ms (72.0%), `plot_ms` 16.78 ms (28.0%) |
| LargeGraphs | 176.1 | 176.13 | 0.1 | 61.7 KiB | `assemble_ms` 0.03 ms (0.0%), `export_ms` 2.47 ms (1.4%), `layout_ms` 173.6 ms (98.6%) |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 43.13 | 42.78 | 72.0% | 1.7 |
| `plot_ms` | 16.78 | 16.76 | 28.0% | 0.3 |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.03 | 0.03 | 0.0% | 4.4 |
| `export_ms` | 2.47 | 2.47 | 1.4% | 0.2 |
| `layout_ms` | 173.6 | 173.63 | 98.6% | 0.2 |

`GraphMakie` was faster overall by 2.94x. Its largest timed stage was `export_ms` at 72.0% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 7.05x.

### smoke_preferential_attachment

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| GraphMakie | 158.48 | 157.87 | 0.8 | 2.61 MiB | `export_ms` 115.82 ms (73.1%), `plot_ms` 42.66 ms (26.9%) |
| LargeGraphs | 415.78 | 415.51 | 0.3 | 121.7 KiB | `assemble_ms` 0.05 ms (0.0%), `export_ms` 7.05 ms (1.7%), `layout_ms` 408.68 ms (98.3%) |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 115.82 | 115.15 | 73.1% | 1.0 |
| `plot_ms` | 42.66 | 42.72 | 26.9% | 0.3 |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.05 | 0.05 | 0.0% | 3.0 |
| `export_ms` | 7.05 | 7.07 | 1.7% | 0.7 |
| `layout_ms` | 408.68 | 408.39 | 98.3% | 0.3 |

`GraphMakie` was faster overall by 2.62x. Its largest timed stage was `export_ms` at 73.1% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 21.97x.

## Notes

- Timings are split by backend stage and then summed into `total_ms`.
- `Trimmed mean` drops the fastest and slowest sample when at least three timed samples are available.
- `CV (%)` highlights run-to-run stability; lower values indicate steadier measurements.
- Overview speedups and winners are based on total `trimmed mean` so one noisy sample does not dominate the comparison.
