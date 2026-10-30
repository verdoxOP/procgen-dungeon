# Benchmark: Rust vs C#

Compares the speed of the two generators. Both produce exactly the same dungeon for the same seed (checked for seeds 0–999), so they do the same work and only the language differs.

## Running

1. Build the generators from the repository root (`build-generators.ps1` or `build-generators.sh`). The benchmark uses the same release builds as the game, from `GoDot-Project/dungeon-crawler/generators/`.
2. Run, with [Node.js](https://nodejs.org) 18 or newer:

```sh
node benchmark/benchmark.mjs
```

| Option | Default | Meaning |
|---|---|---|
| `--seeds` | 1000 | seeds 0 to n − 1 |
| `--warmup` | 3 | warm: passes over the seeds before measuring |
| `--warm-repeats` | 3 | warm: how many times the whole warm measurement is repeated |
| `--out` | `benchmark/results` | where the results go |
| `--generators` | the game's `generators/` folder | where the programs are |

With the defaults it takes a few minutes. Close other heavy programs while it runs.

## What is measured

Every generator times its own steps and writes them to the `stats` in its output (see the game's `test_data/FORMAT.md`):

| Key | Step |
|---|---|
| `rooms_ms` | generate rooms + validate, including retries |
| `edges_ms` | complete graph with random weights |
| `tree_ms` | Prim's spanning tree |
| `doors_ms` | doors from the tree edges |
| `bfs_ms` | distances from the start room + end room |
| `population_ms` | enemies and pickups + population validation |
| `total_ms` | sum of the six steps |

Only the steps are timed: not the logging between them, not process start-up and not writing the JSON. Rust uses `std::time::Instant`, C# uses `Stopwatch`.

The benchmark measures two situations:

| | How | What it shows |
|---|---|---|
| **cold** | one process per seed: `<generator> --seed <n>`. Rust and C# take turns per seed. Also measures `process_ms`, the whole process timed from outside. | the speed the game sees: one dungeon per run, start-up and (for C#) JIT compilation included |
| **warm** | one process for all seeds: `<generator> --seed 0 --runs 1000 --warmup 3`. The warmup passes generate the same seeds first without measuring. | the speed of the algorithm itself, after the JIT has compiled and optimised everything |

The script also checks that both generators needed the same number of room generation attempts for every seed, as a check that they did the same work.

## Output

| File | Content |
|---|---|
| `results/summary.md` | machine, date, and per metric the median, mean and 95th percentile for both languages, plus C# / Rust |
| `results/cold.csv` | one row per generator per seed |
| `results/warm.csv` | one row per generator per repeat per seed |

## Results

The latest run is in [results/summary.md](results/summary.md). Medians for seeds 0–999:

| | Rust | C# | C# / Rust |
|---|---|---|---|
| cold `total_ms` | 0.070 ms | 9.5 ms | 136× |
| cold `process_ms` | 12.3 ms | 110 ms | 8.9× |
| warm `total_ms` | 0.024 ms | 0.069 ms | 2.9× |

Cold, C# loses mostly to JIT compilation and .NET start-up. Warm, the gap is much smaller. C# is even faster at rooms and BFS, and slower mainly in population.

## Code size

```sh
node benchmark/code-size.mjs
```

Counts the lines of code per pipeline step in both generators, tests separately, and lists dependencies and program size. Writes [results/code-size.md](results/code-size.md). Compare the **logic** column (code lines without lines that are only brackets): C# puts `{` on its own line and Rust doesn't.

Both generators were written by a different person, so code size also reflects personal style, not only the language.

## Limitations

- The fastest steps take a few hundred nanoseconds. That is close to the resolution of the timers (about 100 ns on Windows), so `doors_ms` and `edges_ms` on their own say little. `total_ms` is more reliable.
- One log line per room generation (`Generated 18 rooms in 35 attempts`) is written to stderr inside `rooms_ms` in both languages. The benchmark discards stderr, but the write itself is timed.
- C# is a framework-dependent single-file build on .NET 8 (the same build the game uses). Native AOT or a newer runtime would give different cold numbers.
- Results depend on the machine. Compare Rust and C# from the same run, not numbers from different machines.
