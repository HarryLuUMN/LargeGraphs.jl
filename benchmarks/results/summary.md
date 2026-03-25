# Rendering Benchmark Summary

Generated from:
- `raw/latest.json`
- `raw/summary-20260324-212200.json`

## Overview

| Scenario | Nodes | Edges | Faster backend | Total speedup | Smaller artifact | Size ratio | Largest stage share |
| --- | ---: | ---: | --- | ---: | --- | ---: | --- |
| `smoke_erdos_renyi` | `erdos_renyi` | 120 | 222 | 0.0311 | LargeGraphs | 6.06x | LargeGraphs | 12.92x | layout_ms (66.4%) |
| `smoke_preferential_attachment` | `preferential_attachment` | 180 | 885 | 0.0549 | LargeGraphs | 6.21x | LargeGraphs | 28.53x | layout_ms (73.9%) |

## Scenario Details

### smoke_erdos_renyi

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| LargeGraphs | 8.49 | 8.22 | 6.6 | 33.7 KiB | `assemble_ms` 0.02 ms (0.2%), `export_ms` 2.78 ms (32.8%), `layout_ms` 5.64 ms (66.4%) |
| GraphMakie | 51.44 | 51.67 | 2.1 | 435.5 KiB | `export_ms` 40.56 ms (78.8%), `plot_ms` 10.95 ms (21.3%) |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.02 | 0.02 | 0.2% | 2.2 |
| `export_ms` | 2.78 | 2.55 | 32.8% | 20.3 |
| `layout_ms` | 5.64 | 5.65 | 66.4% | 0.6 |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 40.56 | 40.73 | 78.8% | 2.7 |
| `plot_ms` | 10.95 | 10.94 | 21.3% | 0.5 |

`LargeGraphs` was faster overall by 6.06x. Its largest timed stage was `layout_ms` at 66.4% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 12.92x.

### smoke_preferential_attachment

| Backend | Total trimmed mean (ms) | Total mean (ms) | CV (%) | Artifact | Stage breakdown |
| --- | ---: | ---: | ---: | ---: | --- |
| LargeGraphs | 21.0 | 21.14 | 3.5 | 93.6 KiB | `assemble_ms` 0.04 ms (0.2%), `export_ms` 5.33 ms (25.4%), `layout_ms` 15.52 ms (73.9%) |
| GraphMakie | 130.41 | 134.54 | 6.4 | 2.61 MiB | `export_ms` 103.27 ms (79.2%), `plot_ms` 27.14 ms (20.8%) |

#### LargeGraphs stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `assemble_ms` | 0.04 | 0.04 | 0.2% | 3.1 |
| `export_ms` | 5.33 | 5.68 | 25.4% | 10.9 |
| `layout_ms` | 15.52 | 15.43 | 73.9% | 1.7 |

#### GraphMakie stage details

| Stage | Trimmed mean (ms) | Mean (ms) | Share of total | CV (%) |
| --- | ---: | ---: | ---: | ---: |
| `export_ms` | 103.27 | 107.63 | 79.2% | 7.6 |
| `plot_ms` | 27.14 | 26.91 | 20.8% | 1.9 |

`LargeGraphs` was faster overall by 6.21x. Its largest timed stage was `layout_ms` at 73.9% of total trimmed mean, while `LargeGraphs` produced the smaller artifact by 28.53x.

## Notes

- Timings are split by backend stage and then summed into `total_ms`.
- `Trimmed mean` drops the fastest and slowest sample when at least three timed samples are available.
- `CV (%)` highlights run-to-run stability; lower values indicate steadier measurements.
- Overview speedups and winners are based on total `trimmed mean` so one noisy sample does not dominate the comparison.
