# Verification against Rust

[← Documentation home](README.md)

The C# generator is meant to produce **exactly** the same dungeon as the Rust generator for every seed. This page describes how that is checked after each porting step, and the results so far.

## Why check it

- **Fair comparison:** if both generators produce the same dungeon, they do the same amount of work, so differences in speed come from the language and runtime, not from the algorithm or random luck.
- **Correctness:** any difference means a bug in the port (a missing, extra or reordered random call, an off-by-one in a range, a different comparison).

## Setup

| Tool | Version used |
|---|---|
| .NET SDK | 9.0 / 10.0 (project targets `net8.0`) |
| Rust | 1.99.1, toolchain `stable-x86_64-pc-windows-gnu` |
| Rust crates | `rand 0.9`, `rand_pcg 0.9` (same as the Rust generator) |

On this Windows machine the GNU toolchain needs one extra flag to build the Rust generator, because `getrandom` (a dependency of `rand`) otherwise needs a full MinGW install:

```powershell
$env:RUSTFLAGS='--cfg getrandom_backend="windows_legacy"'; cargo build --release
```

The flag only changes where `rand` gets *system* randomness from. The generator never uses system randomness (everything comes from the seed), so the output is unaffected.

## Checks and results

### 1. PCG core vs the official test numbers

`Pcg32.FromStateAndStream(42, 54)` must give the numbers from the official PCG32 demo (the same test `rand_pcg` uses):

```
a15c02b7 7b47f409 ba1d3330 83d2f293 bfa4784b cbed606e
```

**Result: identical.**

### 2. Seeding and ranges vs Rust's `rand_pcg`

Two small programs, one in Rust (`rand 0.9` + `rand_pcg 0.9`) and one in C# (`Pcg32.cs`), print the same sequence for seeds `0, 1, 42, 123456789` and `18446744073709551615` (the largest `u64`):

- one `next_u32`,
- one `usize` in `8..=20` (like the room count),
- 20 rounds of five `i32` ranges: `8..=20`, `0..=92`, `1..=100`, `0..=2_000_000_000`, `-5..=5`.

The large range triggers `rand`'s second-sample bias correction (see [Random number generator](rng.md)), the negative range checks signed results.

**Result: all 115 output lines identical** (505 `RandomRange` calls).

### 3. Rooms vs Matt's generator

For seeds 0–29: run the Rust generator, read the rooms from its `dungeon.json`, run the C# generator and compare the room lines (`Room id: x, y, WxH`).

**Result: 30/30 identical** (same count, ids, positions and sizes). Seed 42 gives 18 rooms in 35 placement attempts in both.

### 4. Retry loop on a small map

The retry loop never runs with the default settings (0 retries in seeds 0–2999). To test it anyway, both generators were copied and rebuilt with a **40 × 40** map, where room validation often fails. For seeds 0–199 the number of generation attempts, success or failure, and the rooms were compared.

**Result: 200/200 identical.** 167 of those seeds needed at least one retry, 28 failed all 10 attempts (Rust then continues with invalid rooms; C# exits with code 1, as designed).

These copies were temporary and are not part of the repository.

## How to repeat a check

For one seed, by hand:

```sh
# Rust (from Algorithms/rust/procgen_dungeon/) — writes dungeon.json
echo 42 | cargo run --release

# C# (from Algorithms/csharp/procgen-csharp/procgen-csharp/)
dotnet run -c Release -- --seed 42
```

Compare the `rooms` in `dungeon.json` with the `Room …` lines the C# generator prints. Once the C# generator writes JSON too, the two JSON files can be compared directly (apart from the `generator` field).

## Still to do

- Turn these checks into unit tests (see [Roadmap](roadmap.md#test-ideas)).
- Repeat check 3 for every new step: edges, Prim, doors, BFS, JSON.
