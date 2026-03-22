# Rendering Benchmark Summary

Generated from:
- `raw/latest.json`
- `raw/summary-20260322-153844.json`

## Overview

| Scenario | Nodes | Edges | Faster backend | Total speedup | Smaller artifact | Size ratio | Largest stage share |
| --- | ---: | ---: | --- | ---: | --- | ---: | --- |
| `smoke_erdos_renyi` | 120 | 222 | GraphMakie | 2.61x | LargeGraphs | 7.05x | export_ms (79.1%) |
| `smoke_preferential_attachment` | 180 | 885 | GraphMakie | 2.5x | LargeGraphs | 21.97x | export_ms (79.8%) |

## Scenario Details

### smoke_erdos_renyi

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| GraphMakie | 55.05 | 55.36 | 1.7 | 435.5 KiB | `export_ms` 43.54 ms (79.1%), `plot_ms` 11.8 ms (21.4%) |
| LargeGraphs | 143.81 | 148.13 | 5.8 | 61.7 KiB | `assemble_ms` 0.03 ms (0.0%), `export_ms` 2.1 ms (1.5%), `layout_ms` 141.75 ms (98.6%) |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 43.54 | 43.65 | 79.1% | 2.1 |
| `plot_ms` | 11.8 | 11.7 | 21.4% | 1.5 |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.03 | 0.03 | 0.0% | 13.6 |
| `export_ms` | 2.1 | 2.59 | 1.5% | 34.9 |
| `layout_ms` | 141.75 | 145.51 | 98.6% | 5.2 |

`GraphMakie` was faster overall by 2.61x. Its largest timed stage was `export_ms` at 79.1% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 7.05x.

### smoke_preferential_attachment

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| GraphMakie | 137.35 | 136.91 | 1.2 | 2.61 MiB | `export_ms` 109.67 ms (79.8%), `plot_ms` 27.68 ms (20.2%) |
| LargeGraphs | 343.92 | 342.63 | 1.4 | 121.7 KiB | `assemble_ms` 0.05 ms (0.0%), `export_ms` 5.49 ms (1.6%), `layout_ms` 336.99 ms (98.0%) |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 109.67 | 109.18 | 79.8% | 1.2 |
| `plot_ms` | 27.68 | 27.73 | 20.2% | 1.2 |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.05 | 0.05 | 0.0% | 6.4 |
| `export_ms` | 5.49 | 5.94 | 1.6% | 13.6 |
| `layout_ms` | 336.99 | 336.63 | 98.0% | 1.4 |

`GraphMakie` was faster overall by 2.5x. Its largest timed stage was `export_ms` at 79.8% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 21.97x.

## Notes

- Timings are split by backend stage and then summed into `total_ms`.
- `Trimmed mean` drops the fastest and slowest sample when at least three timed samples are available.
- `CV (%)` highlights run-to-run stability; lower values indicate steadier measurements.
- Overview speedups and winners are based on total `trimmed mean` so one noisy sample does not dominate the comparison.
