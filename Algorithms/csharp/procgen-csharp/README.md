# procgen-csharp (C#)

The C# half of the procedural dungeon generator for a 2D roguelike in the style of *The Binding of Isaac* and *Enter the Gungeon*. It is a port of the Rust generator (`Algorithms/rust/procgen_dungeon/`), built so both implementations can be compared in the report. Gameplay and rendering live in the Godot project (`GoDot-Project/`).

The port follows the Rust pipeline **step by step, in the same order of random calls**. With the same seed, both generators produce exactly the same dungeon, so the comparison measures the language, not a different algorithm or different luck.

```
C# generator → validated dungeon data → JSON → Godot
```

📖 **Full documentation:** [docs/](docs/README.md): architecture, the RNG port, rooms, validation, verification against Rust, design decisions and roadmap.

## Contents

- [Current status](#current-status)
- [Requirements](#requirements)
- [Running](#running)
- [How it works](#how-it-works)
- [Verified against Rust](#verified-against-rust)
- [Differences from the Rust version](#differences-from-the-rust-version)
- [Project structure](#project-structure)
- [Configuration](#configuration)

## Current status

| Stage | Status | Code |
|---|---|---|
| Seeded, deterministic RNG (port of Rust's `Pcg32`) | ✅ done, identical to Rust | [`Pcg32.cs`](procgen-csharp/Pcg32.cs) |
| Command line (`--seed`, exit codes) | ✅ done | [`Program.cs` L9–19](procgen-csharp/Program.cs#L9-L19) |
| Room generation (random size and position, no overlap) | ✅ done, identical to Rust | [`RoomGeneration.cs`](procgen-csharp/RoomGeneration.cs) |
| Room validation + retry loop | ✅ done, identical to Rust | [`Validation.cs`](procgen-csharp/Validation.cs), [`Program.cs` L77–94](procgen-csharp/Program.cs#L77-L94) |
| Candidate edges (complete graph, random weights) | ✅ done, identical to Rust | [`EdgeGeneration.cs`](procgen-csharp/EdgeGeneration.cs) |
| Backbone with Prim's algorithm | ✅ done, identical to Rust | [`SpanningTree.cs`](procgen-csharp/SpanningTree.cs) |
| Doors (wall per connection) | ✅ done, identical to Rust | [`DoorGeneration.cs`](procgen-csharp/DoorGeneration.cs) |
| BFS: end room | ✅ done, identical to Rust | [`Bfs.cs`](procgen-csharp/Bfs.cs) |
| JSON export to stdout | ✅ done, identical to Rust | [`DungeonJson.cs`](procgen-csharp/DungeonJson.cs) |
| Runs in the Godot game | ✅ done | see [Output](docs/output.md#running-in-the-game) |
| Population + population validation | ✅ done, identical to Rust | [`Population.cs`](procgen-csharp/Population.cs) |
| `stats` (time per step and attempts) | ✅ done, same keys as Rust | [`GenerationStats.cs`](procgen-csharp/GenerationStats.cs), see [Output](docs/output.md#stats-time-per-step) |
| Corridors | ❌ cut from scope (also in Rust) | |
| Unit tests (same 26 tests as Rust) | ✅ done, all pass | [`procgen-csharp.Tests`](procgen-csharp.Tests), see [Test plan](docs/test-plan.md) |

## Requirements

- .NET SDK 8 or newer (the project targets `net8.0`)
- No NuGet packages in the generator. The test project uses xUnit (restored automatically by `dotnet test`).

## Running

From `Algorithms/csharp/procgen-csharp/procgen-csharp/`:

```sh
dotnet run -- --seed 42
```

The seed is a command-line argument, following the contract the Godot game uses (see [Getting started](docs/getting-started.md)). All log output goes to **stderr**; stdout is kept free for the dungeon JSON.

| Exit code | Meaning |
|---|---|
| 0 | success |
| 1 | generation failed (no valid rooms after `MaxGenerationAttempts`) |
| 2 | invalid arguments |

### Benchmark mode

```sh
dotnet run -c Release -- --seed 0 --runs 1000 --warmup 3
```

Generates many dungeons in one process and prints only their `stats`, one line each. Same options as the Rust generator; used by `benchmark/benchmark.mjs`. See [Getting started → Benchmark mode](docs/getting-started.md#benchmark-mode).

### Unit tests

From `Algorithms/csharp/procgen-csharp/`:

```sh
dotnet test
```

Runs the 26 unit tests in `procgen-csharp.Tests`, the same tests as `cargo test` in the Rust generator. See [Test plan](docs/test-plan.md) and [Test report](docs/test-report.md).

## How it works

### 1. Seeded RNG ([`Pcg32.cs`](procgen-csharp/Pcg32.cs))

A C# port of `rand_pcg::Pcg32` from the Rust `rand` 0.9 crates, including how it is seeded (`seed_from_u64`) and how a number in a range is picked (`random_range`). Every random choice comes from this one generator, passed through every step. See [Random number generator](docs/rng.md).

### 2. Room generation ([`RoomGeneration.cs`](procgen-csharp/RoomGeneration.cs))

Picks a target room count, then keeps placing random rooms and throws away any that overlap an existing room, up to `MaxPlacementAttempts`. Accepted rooms get `Id = index in the list`. Same steps as `room_generation.rs`. See [Rooms](docs/rooms.md).

### 3. Room validation ([`Validation.cs`](procgen-csharp/Validation.cs))

Checks the room count, minimum sizes and overlap (VR-01 – VR-04). `Program` regenerates the rooms with the same RNG until they are valid, at most `MaxGenerationAttempts` times, and exits with code 1 if they never are.

### 4. Candidate edges ([`EdgeGeneration.cs`](procgen-csharp/EdgeGeneration.cs))

Connects every pair of rooms (a complete graph, `n · (n − 1) / 2` edges) and gives each pair a random weight from 1 to 100, in the same pair order as `edge.rs`. See [Graph and backbone](docs/graph.md).

### 5. Backbone: Prim's algorithm ([`SpanningTree.cs`](procgen-csharp/SpanningTree.cs))

Starting from room 0, repeatedly adds the cheapest edge from a connected room to a new room, until every room is connected: a spanning tree with `n − 1` edges, which become the doors. On equal weights the first edge in the list wins, like in `tree.rs`.

### 6. Doors ([`DoorGeneration.cs`](procgen-csharp/DoorGeneration.cs))

Every tree edge becomes a door. The bigger difference between the two room centres decides the wall: left/right if the rooms are mostly side by side (also on a tie), top/bottom otherwise. The other room gets the opposite wall. Same rule as `door.rs`.

### 7. Start, end and JSON ([`Bfs.cs`](procgen-csharp/Bfs.cs), [`DungeonJson.cs`](procgen-csharp/DungeonJson.cs))

The start is room 0; BFS over the doors finds the end room, the one the most doors away. The dungeon is then printed to stdout as JSON in format version 2, with the same keys in the same order as the Rust generator. See [Start, end and JSON output](docs/output.md).

### 8. Population ([`Population.cs`](procgen-csharp/Population.cs))

Every room gets a kind (start, end, enemy, item or empty). Enemy rooms get 1–6 enemies depending on size, item rooms one pickup, the end room a boss. Spawns go on free inside tiles away from doors, and are validated afterwards (PV rules). See [Population](docs/population.md).

## Verified against Rust

The C# output is compared with the Rust generator after every step. See [Verification](docs/verification.md).

| What | Result |
|---|---|
| `NextU32` vs the official PCG32 test numbers | identical |
| 505 `RandomRange` calls over 5 seeds vs Rust `rand_pcg` | identical |
| Rooms for seeds 0–29 vs Matt's generator | identical (30/30) |
| Retry loop on a 40×40 test map, seeds 0–199 (167 retries, 28 failures) | identical (200/200) |
| Edges and weights for seeds 0–49 | identical (50/50) |
| Prim backbone vs Rust `tree.dot`, seeds 0–99 | identical (100/100) |
| Rooms, edges and backbone again vs Rust **5eeafce** (26 Oct), seeds 0–99 | identical (100/100 each) |
| Doors and their walls vs Rust 5eeafce, seeds 0–299 (3839 doors, 36 ties) | identical (300/300) |
| Full JSON vs Rust e3dc311 (except `generator` and `spawnables`), seeds 0–299 | identical (300/300) |
| Full JSON **including spawnables** vs Rust e3dc311, seeds 0–999 | identical, byte for byte (1000/1000) |
| Both generators in the Godot game (load, play, same dungeon and spawnables) | 13/13 checks passed |

## Differences from the Rust version

Deliberate, and none of them change the dungeon for a given seed. (The command-line differences are gone: since commit `5eeafce` the Rust generator also takes `--seed`, logs to stderr, prints the JSON to stdout and exits with code 1 when generation fails.)

| Rust | C# | Why |
|---|---|---|
| `max_attempts`, unused `mst` | `MaxPlacementAttempts`, no `mst` | clearer name; unused constant left out |
| `build_tree` with a `101` start weight and a loop that runs once | `BuildTree` without either | same tree, simpler code (see [Graph and backbone](docs/graph.md#differences-from-treers-same-result)) |

## Project structure

```
procgen-csharp/
├── README.md
├── procgen-csharp.sln
├── docs/                       developer documentation
├── procgen-csharp.Tests/       xUnit tests, one class per Rust test module
└── procgen-csharp/
    ├── procgen-csharp.csproj   console app, net8.0
    ├── Program.cs              entry point: arguments, pipeline, exit codes
    ├── Constants.cs            tunable generation parameters
    ├── Pcg32.cs                seeded RNG (port of Rust's Pcg32)
    ├── Room.cs                 Room + overlap check
    ├── RoomGeneration.cs       GenerateRooms / GenerateRoom
    ├── Validation.cs           ValidateRooms
    ├── Edge.cs                 Edge (two room ids + weight)
    ├── EdgeGeneration.cs       GenerateEdges (complete graph)
    ├── SpanningTree.cs         BuildTree (Prim's algorithm)
    ├── Door.cs                 Wall enum + Door
    ├── DoorGeneration.cs       GenerateDoors / EdgeToDoor (wall per side)
    ├── Bfs.cs                  RoomDistances / FurthestRoom (end room)
    ├── Spawnable.cs            Spawnable records (enemy, health, ammo, buff)
    ├── Population.cs           room kinds, spawning, population validation
    ├── GenerationStats.cs      time per step + generation attempts ("stats" in the JSON)
    ├── GeneratedDungeon.cs     everything one generated dungeon needs for the JSON
    └── DungeonJson.cs          Build: the dungeon as JSON (format version 2)
```

## Configuration

All values are in [`Constants.cs`](procgen-csharp/Constants.cs) and match `constants.rs`. Details: [Configuration](docs/configuration.md).

| Constant | Value | Meaning |
|---|---|---|
| `MinRoomCount` | 8 | minimum rooms in a valid dungeon |
| `MaxRoomCount` | 20 | maximum rooms that will be attempted |
| `MaxPlacementAttempts` | 1000 | placement attempts per generation |
| `MaxGenerationAttempts` | 10 | full regenerations before giving up |
| `MinRoomWidth` / `MinRoomHeight` | 8 | minimum room size |
| `MaxRoomWidth` / `MaxRoomHeight` | 20 | maximum room size |
| `MapWidth` / `MapHeight` | 100 | map size in tiles |
| `FormatVersion` | 2 | JSON format version |
| `EdgeGeneration.MinWeight` / `MaxWeight` | 1 / 100 | edge weight range (hard-coded in Rust) |
| `EnemyRoomChance` / `ItemRoomChance` | 60 / 15 | chance (of 100) a normal room is an enemy / item room |
| `TilesPerEnemy` / `MaxEnemiesPerRoom` | 40 / 6 | enemies per room by size |
| `AggressiveChance` | 70 | chance an enemy is aggressive |
