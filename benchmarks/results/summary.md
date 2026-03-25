# Rendering Benchmark Summary

Generated from:
- `raw/latest.json`
- `raw/summary-20260324-211548.json`

## Overview

| Scenario | Nodes | Edges | Faster backend | Total speedup | Smaller artifact | Size ratio | Largest stage share |
| --- | ---: | ---: | --- | ---: | --- | ---: | --- |
| `smoke_erdos_renyi` | `erdos_renyi` | 120 | 222 | 0.0311 | GraphMakie | 2.54x | LargeGraphs | 12.91x | export_ms (78.4%) |
| `smoke_preferential_attachment` | `preferential_attachment` | 180 | 885 | 0.0549 | GraphMakie | 2.27x | LargeGraphs | 28.53x | export_ms (79.9%) |

## Scenario Details

### smoke_erdos_renyi

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| GraphMakie | 53.86 | 53.83 | 0.6 | 435.5 KiB | `export_ms` 42.2 ms (78.4%), `plot_ms` 11.75 ms (21.8%) |
| LargeGraphs | 136.65 | 136.5 | 0.9 | 33.7 KiB | `assemble_ms` 0.03 ms (0.0%), `export_ms` 2.56 ms (1.9%), `layout_ms` 134.37 ms (98.3%) |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 42.2 | 42.12 | 78.4% | 0.8 |
| `plot_ms` | 11.75 | 11.71 | 21.8% | 2.0 |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.03 | 0.03 | 0.0% | 13.1 |
| `export_ms` | 2.56 | 2.67 | 1.9% | 18.0 |
| `layout_ms` | 134.37 | 133.8 | 98.3% | 0.8 |

`GraphMakie` was faster overall by 2.54x. Its largest timed stage was `export_ms` at 78.4% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 12.91x.

### smoke_preferential_attachment

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| GraphMakie | 137.5 | 154.62 | 19.3 | 2.61 MiB | `export_ms` 109.83 ms (79.9%), `plot_ms` 28.6 ms (20.8%) |
| LargeGraphs | 311.94 | 312.85 | 0.7 | 93.7 KiB | `assemble_ms` 0.05 ms (0.0%), `export_ms` 6.28 ms (2.0%), `layout_ms` 305.35 ms (97.9%) |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 109.83 | 116.7 | 79.9% | 11.1 |
| `plot_ms` | 28.6 | 37.92 | 20.8% | 44.7 |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.05 | 0.05 | 0.0% | 10.7 |
| `export_ms` | 6.28 | 6.26 | 2.0% | 4.7 |
| `layout_ms` | 305.35 | 306.54 | 97.9% | 0.7 |

`GraphMakie` was faster overall by 2.27x. Its largest timed stage was `export_ms` at 79.9% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 28.53x.

## Notes

- Timings are split by backend stage and then summed into `total_ms`.
- `Trimmed mean` drops the fastest and slowest sample when at least three timed samples are available.
- `CV (%)` highlights run-to-run stability; lower values indicate steadier measurements.
- Overview speedups and winners are based on total `trimmed mean` so one noisy sample does not dominate the comparison.
