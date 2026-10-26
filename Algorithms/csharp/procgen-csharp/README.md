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
| Command line (`--seed`, exit codes) | ✅ done | [`Program.cs` L6–12](procgen-csharp/Program.cs#L6-L12) |
| Room generation (random size and position, no overlap) | ✅ done, identical to Rust | [`RoomGeneration.cs`](procgen-csharp/RoomGeneration.cs) |
| Room validation + retry loop | ✅ done, identical to Rust | [`Validation.cs`](procgen-csharp/Validation.cs), [`Program.cs` L14–29](procgen-csharp/Program.cs#L14-L29) |
| Candidate edges (complete graph, random weights) | ✅ done, identical to Rust | [`EdgeGeneration.cs`](procgen-csharp/EdgeGeneration.cs) |
| Backbone with Prim's algorithm | ⏳ next | |
| Doors (wall per connection) | ⏳ planned | |
| BFS: end room | ⏳ planned | |
| JSON export | ⏳ planned | |
| Corridors, population, stats | ⏳ planned (after Rust has them) | |
| Unit tests | ⏳ planned | |

## Requirements

- .NET SDK 8 or newer (the project targets `net8.0`)
- No NuGet packages

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

## How it works

### 1. Seeded RNG ([`Pcg32.cs`](procgen-csharp/Pcg32.cs))

A C# port of `rand_pcg::Pcg32` from the Rust `rand` 0.9 crates, including how it is seeded (`seed_from_u64`) and how a number in a range is picked (`random_range`). Every random choice comes from this one generator, passed through every step. See [Random number generator](docs/rng.md).

### 2. Room generation ([`RoomGeneration.cs`](procgen-csharp/RoomGeneration.cs))

Picks a target room count, then keeps placing random rooms and throws away any that overlap an existing room, up to `MaxPlacementAttempts`. Accepted rooms get `Id = index in the list`. Same steps as `room_generation.rs`. See [Rooms](docs/rooms.md).

### 3. Room validation ([`Validation.cs`](procgen-csharp/Validation.cs))

Checks the room count, minimum sizes and overlap (VR-01 – VR-04). `Program` regenerates the rooms with the same RNG until they are valid, at most `MaxGenerationAttempts` times, and exits with code 1 if they never are.

### 4. Candidate edges ([`EdgeGeneration.cs`](procgen-csharp/EdgeGeneration.cs))

Connects every pair of rooms (a complete graph, `n · (n − 1) / 2` edges) and gives each pair a random weight from 1 to 100, in the same pair order as `edge.rs`. See [Graph and backbone](docs/graph.md).

## Verified against Rust

The C# output is compared with the Rust generator after every step. See [Verification](docs/verification.md).

| What | Result |
|---|---|
| `NextU32` vs the official PCG32 test numbers | identical |
| 505 `RandomRange` calls over 5 seeds vs Rust `rand_pcg` | identical |
| Rooms for seeds 0–29 vs Matt's generator | identical (30/30) |
| Retry loop on a 40×40 test map, seeds 0–199 (167 retries, 28 failures) | identical (200/200) |
| Edges and weights for seeds 0–49 | identical (50/50) |

## Differences from the Rust version

Deliberate, and none of them change the dungeon for a given seed:

| Rust | C# | Why |
|---|---|---|
| seed read from stdin | `--seed <int>` argument | command-line contract with the Godot game |
| logs on stdout | logs on stderr | stdout is reserved for the JSON |
| continues with invalid rooms after all attempts fail | exits with code 1 | contract: exit 1 = generation failed |
| `max_attempts`, unused `mst` | `MaxPlacementAttempts`, no `mst` | clearer name; unused constant left out |

## Project structure

```
procgen-csharp/
├── README.md
├── procgen-csharp.sln
├── docs/                       developer documentation
└── procgen-csharp/
    ├── procgen-csharp.csproj   console app, net8.0
    ├── Program.cs              entry point: arguments, pipeline, exit codes
    ├── Constants.cs            tunable generation parameters
    ├── Pcg32.cs                seeded RNG (port of Rust's Pcg32)
    ├── Room.cs                 Room + overlap check
    ├── RoomGeneration.cs       GenerateRooms / GenerateRoom
    ├── Validation.cs           ValidateRooms
    ├── Edge.cs                 Edge (two room ids + weight)
    └── EdgeGeneration.cs       GenerateEdges (complete graph)
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
| `FormatVersion` | 2 | JSON format version (not used yet) |
| `EdgeGeneration.MinWeight` / `MaxWeight` | 1 / 100 | edge weight range (hard-coded in Rust) |
