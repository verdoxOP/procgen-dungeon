# Benchmark results

- **Date:** 2026-10-28 13:20 UTC
- **Machine:** AMD Ryzen 7 8845HS w/ Radeon 780M Graphics, 16 logical cores, 31 GB RAM
- **OS:** Windows_NT 10.0.26200 (x64), Node v24.14.0
- **Seeds:** 0–999
- **Same work check:** 0 seeds where the generation attempts differ between Rust and C# (should be 0)

All times in milliseconds. `total_ms` is the sum of the six steps, measured inside the generator.

## Cold: one process per dungeon (like the game)

One run per seed, 1000 dungeons per generator. `process_ms` is the whole process measured from outside (start-up, generation, JSON, exit).

| Metric | Rust median | Rust mean | Rust p95 | C# median | C# mean | C# p95 | C# / Rust (median) |
|---|---|---|---|---|---|---|---|
| `process_ms` | 12.335 | 12.834 | 14.975 | 109.7 | 110.8 | 120.7 | 8.9× |
| `rooms_ms` | 0.0391 | 0.0394 | 0.0534 | 3.776 | 3.852 | 4.771 | 96.6× |
| `edges_ms` | 0.0014 | 0.0017 | 0.0042 | 0.1060 | 0.1151 | 0.1566 | 75.7× |
| `tree_ms` | 0.0031 | 0.0036 | 0.0067 | 0.1551 | 0.1622 | 0.2265 | 50.0× |
| `doors_ms` | 0.0006 | 0.0006 | 0.0010 | 0.7086 | 0.7416 | 0.9010 | 1181.0× |
| `bfs_ms` | 0.0017 | 0.0019 | 0.0037 | 1.339 | 1.383 | 1.640 | 787.5× |
| `population_ms` | 0.0227 | 0.0244 | 0.0399 | 3.353 | 3.397 | 3.936 | 147.7× |
| `total_ms` | 0.0701 | 0.0717 | 0.1003 | 9.517 | 9.651 | 11.020 | 135.8× |

## Warm: all seeds in one process

`--runs 1000 --warmup 3`, repeated 3 times: 3000 dungeons per generator. Only the generation steps, after the warmup passes.

| Metric | Rust median | Rust mean | Rust p95 | C# median | C# mean | C# p95 | C# / Rust (median) |
|---|---|---|---|---|---|---|---|
| `rooms_ms` | 0.0059 | 0.0062 | 0.0078 | 0.0035 | 0.0043 | 0.0088 | 0.6× |
| `edges_ms` | 0.0005 | 0.0005 | 0.0009 | 0.0008 | 0.0009 | 0.0016 | 1.6× |
| `tree_ms` | 0.0024 | 0.0028 | 0.0060 | 0.0038 | 0.0044 | 0.0095 | 1.6× |
| `doors_ms` | 0.0002 | 0.0002 | 0.0003 | 0.0003 | 0.0004 | 0.0007 | 1.5× |
| `bfs_ms` | 0.0009 | 0.0009 | 0.0013 | 0.0005 | 0.0005 | 0.0009 | 0.6× |
| `population_ms` | 0.0138 | 0.0145 | 0.0230 | 0.0593 | 0.0673 | 0.1297 | 4.3× |
| `total_ms` | 0.0238 | 0.0251 | 0.0385 | 0.0692 | 0.0778 | 0.1467 | 2.9× |

Raw data: `cold.csv`, `warm.csv`.
