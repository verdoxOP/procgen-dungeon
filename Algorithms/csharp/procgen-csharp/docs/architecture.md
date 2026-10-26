# Architecture

[← Documentation home](README.md)

## Goal

The C# generator produces the same validated dungeon data as the Rust generator, in the same JSON format, so the Godot game can use either one and the two languages can be compared fairly.

```
C# generator → validated dungeon data → JSON → Godot
```

The requirements, concepts (room, door, corridor, backbone, dungeon) and the planned pipeline are the same as for the Rust generator: see [Rust → Architecture](../../../rust/procgen_dungeon/docs/architecture.md).

## Porting approach

The port is built **class by class, in the same order as the Rust generator was built**:

| # | Rust (commit) | C# | Status |
|---|---|---|---|
| 1 | seeded `Pcg32` (36063ae) | [`Pcg32.cs`](../procgen-csharp/Pcg32.cs) | ✅ |
| 2 | `Room` + `generate_rooms` (36063ae, 7cd5a1c) | [`Room.cs`](../procgen-csharp/Room.cs), [`RoomGeneration.cs`](../procgen-csharp/RoomGeneration.cs) | ✅ |
| 3 | `validate_rooms` + retry loop (8415a9d, 71e3fd3) | [`Validation.cs`](../procgen-csharp/Validation.cs), [`Program.cs`](../procgen-csharp/Program.cs) | ✅ |
| 4 | `generate_edges` (c4279d3) | [`Edge.cs`](../procgen-csharp/Edge.cs), [`EdgeGeneration.cs`](../procgen-csharp/EdgeGeneration.cs) | ✅ |
| 5 | `build_tree` / Prim (c4279d3) | | ⏳ next |
| 6 | doors (b04f021) | | ⏳ |
| 7 | JSON export (997fb86) | | ⏳ |
| 8 | BFS end room (4d0fb94) | | ⏳ |

After each step, the C# output is compared with the Rust output for the same seeds (see [Verification](verification.md)). A step is only done when the output is identical.

The one rule that makes this work: **the random calls must happen in exactly the same order as in Rust.** Every random number depends on all the numbers drawn before it, so one extra, missing or reordered call changes everything after it.

## Pipeline

### Implemented

```mermaid
flowchart LR
    seed[--seed argument] --> rng[Pcg32.FromSeed]
    rng --> gen[RoomGeneration.GenerateRooms]
    gen --> val{Validation.ValidateRooms}
    val -- fail, attempts left --> gen
    val -- fail, no attempts left --> exit1[exit code 1]
    val -- pass --> edges[EdgeGeneration.GenerateEdges]
    edges --> print[print rooms and edges to stderr]
```

### Planned

Same as Rust: rooms → validate → edges → Prim backbone → doors → BFS end room → JSON on stdout. Corridors, population and stats follow once they exist in the Rust version.

## Data flow in `Program`

| Step | Call | Produces | Code |
|---|---|---|---|
| 1 | parse `--seed` | `seed: ulong`, or exit 2 | [L6–10](../procgen-csharp/Program.cs#L6-L10) |
| 2 | `Pcg32.FromSeed(seed)` | `rng: Pcg32` | [L12](../procgen-csharp/Program.cs#L12) |
| 3 | `GenerateRooms` in a retry loop with `ValidateRooms` | `rooms: List<Room>` | [L14–23](../procgen-csharp/Program.cs#L14-L23) |
| 4 | still invalid after all attempts | exit 1 | [L25–29](../procgen-csharp/Program.cs#L25-L29) |
| 5 | print rooms | stderr | [L31–35](../procgen-csharp/Program.cs#L31-L35) |
| 6 | `EdgeGeneration.GenerateEdges(rng, rooms)` | `edges: List<Edge>` (complete graph) | [L38–43](../procgen-csharp/Program.cs#L38-L43) |

The same `rng` object is passed to every random step. C# classes are reference types, so passing `rng` to a method is the same as Rust's `&mut rng`: the method advances the one shared generator.

## Classes

| Class | Responsibility | Public items | Rust equivalent |
|---|---|---|---|
| [`Constants`](../procgen-csharp/Constants.cs) | tunable parameters | all constants | `constants.rs` |
| [`Pcg32`](../procgen-csharp/Pcg32.cs) | seeded RNG | `FromSeed`, `NextU32`, `RandomRange`, `FromStateAndStream` | `rand_pcg::Pcg32` + `rand` (external crates) |
| [`Room`](../procgen-csharp/Room.cs) | room data type | `Id`, `X`, `Y`, `Width`, `Height`, `Overlaps` | `room.rs` |
| [`RoomGeneration`](../procgen-csharp/RoomGeneration.cs) | placing rooms | `GenerateRooms` (`GenerateRoom` is private) | `room_generation.rs` |
| [`Validation`](../procgen-csharp/Validation.cs) | checking a room set | `ValidateRooms` | `validation.rs` |
| [`Edge`](../procgen-csharp/Edge.cs) | candidate connection | `Weight`, `RoomA`, `RoomB` | `Edge` in `edge.rs` |
| [`EdgeGeneration`](../procgen-csharp/EdgeGeneration.cs) | complete graph | `GenerateEdges`, `MinWeight`, `MaxWeight` | `generate_edges` in `edge.rs` |
| `Program` (top-level statements) | entry point and pipeline | | `main.rs` |

Each file has one responsibility, like the Rust modules. `RoomGeneration` and `Validation` are `static` classes because they hold no state, the same as free functions in Rust.

The one class with no Rust file of its own is `Pcg32`: Rust gets its RNG from the `rand` and `rand_pcg` crates, while the C# version has to contain it, because `System.Random` produces different numbers. See [Random number generator](rng.md).

## Class dependencies

```mermaid
flowchart TD
    Program --> Pcg32
    Program --> RoomGeneration
    Program --> Validation
    Program --> Constants
    RoomGeneration --> Pcg32
    RoomGeneration --> Room
    RoomGeneration --> Constants
    Validation --> Room
    Validation --> Constants
    Program --> EdgeGeneration
    EdgeGeneration --> Pcg32
    EdgeGeneration --> Room
    EdgeGeneration --> Edge
```

`Room`, `Edge`, `Pcg32` and `Constants` depend on nothing. Dependencies only point "down", so there are no cycles.

## Core data type

[`Room`](../procgen-csharp/Room.cs#L4-L10):

```csharp
public class Room
{
    public int Id { get; set; }
    public int X { get; init; }
    public int Y { get; init; }
    public int Width { get; init; }
    public int Height { get; init; }
}
```

Position and size can only be set when the room is created (`init`), because they never change afterwards. `Id` has a normal setter because it is assigned when the room is accepted ([`RoomGeneration.cs` L23](../procgen-csharp/RoomGeneration.cs#L23)). `Id` equals the room's index in the list, same as in Rust.

## Complexity (n = number of rooms, max 20)

| Method | Cost | At n = 20 |
|---|---|---|
| [`GenerateRooms`](../procgen-csharp/RoomGeneration.cs#L7-L30) | O(attempts · n) | ≤ 1000 × 20 overlap checks |
| [`ValidateRooms`](../procgen-csharp/Validation.cs#L7-L37) | O(n²) | 190 pair checks |
| [`GenerateEdges`](../procgen-csharp/EdgeGeneration.cs#L10-L27) | O(n²) | 190 edges |

Same as the Rust version, since the algorithm is the same.
