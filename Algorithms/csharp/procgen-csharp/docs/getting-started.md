# Getting started

[← Documentation home](README.md)

## Requirements

| Tool | Needed for | Required? |
|---|---|---|
| .NET SDK 8 or newer | building and running | yes |
| Rust + Cargo | building the Rust generator to compare output (see [Verification](verification.md)) | optional |

The project targets `net8.0` ([`procgen-csharp.csproj`](../procgen-csharp/procgen-csharp.csproj)) and has no NuGet dependencies.

## Build and run

From `Algorithms/csharp/procgen-csharp/procgen-csharp/`:

```sh
dotnet build
dotnet run -- --seed 42
```

The `--` separates `dotnet run`'s own options from the program's arguments.

The seed must be a whole number that fits in a `ulong` (0 to 18446744073709551615). Anything else prints a usage line and exits with code 2 ([`Program.cs` L6–10](../procgen-csharp/Program.cs#L6-L10)).

To build a single exe for the game's `generators/` folder, see [Start, end and JSON output → Running in the game](output.md#running-in-the-game).

## Command-line contract

The generator follows the same contract as every generator the Godot game can run:

| Rule | C# |
|---|---|
| arguments | `--seed <int>` |
| same seed | same dungeon (and the same dungeon as the Rust generator) |
| stdout | only the dungeon JSON (see [Start, end and JSON output](output.md)) |
| stderr | all logs |
| exit 0 | success |
| exit 1 | generation failed ([`Program.cs` L25–29](../procgen-csharp/Program.cs#L25-L29)) |
| exit 2 | invalid arguments ([`Program.cs` L6–10](../procgen-csharp/Program.cs#L6-L10)) |

## Reading the output

Everything below is printed to **stderr**, in order:

| # | Output | Printed by |
|---|---|---|
| 1 | `Generated 18 rooms in 35 attempts` (once per generation attempt) | [`RoomGeneration.cs` L28](../procgen-csharp/RoomGeneration.cs#L28) |
| 2 | the reason, if a room set fails validation | [`Validation.cs`](../procgen-csharp/Validation.cs) |
| 3 | `Valid rooms after N generation attempts` | [`Program.cs` L31](../procgen-csharp/Program.cs#L31) |
| 4 | every room: id, position, size | [`Program.cs` L32–35](../procgen-csharp/Program.cs#L32-L35), [`Room.ToString`](../procgen-csharp/Room.cs#L26-L29) |
| 5 | `Generated 153 edges`, then every edge with its weight | [`Program.cs` L39–43](../procgen-csharp/Program.cs#L39-L43), [`Edge.ToString`](../procgen-csharp/Edge.cs#L11-L14) |
| 6 | `Backbone has 17 edges`, then every tree edge | [`Program.cs` L47–51](../procgen-csharp/Program.cs#L47-L51) |
| 7 | every door with its walls, e.g. `Door 0-15: bottom/top` | [`Program.cs` L55–58](../procgen-csharp/Program.cs#L55-L58), [`Door.ToString`](../procgen-csharp/Door.cs#L21-L24) |
| 8 | `Start room 0, end room 6 (12 doors away)` | [`Program.cs` L64](../procgen-csharp/Program.cs#L64) |

On **stdout** comes only the dungeon JSON. To see just the JSON, or just the logs:

```sh
dotnet run -- --seed 42 2> NUL     # only the JSON (Windows)
dotnet run -- --seed 42 > NUL      # only the logs
```

Example (seed `42`):

```
Generated 18 rooms in 35 attempts
Valid rooms after 1 generation attempts
Room 0: x 81, y 33, 18x9
Room 1: x 27, y 76, 16x18
Room 2: x 45, y 33, 11x9
...
Room 17: x 8, y 35, 18x9
Generated 153 edges
Edge 0-1: weight 63
Edge 0-2: weight 27
...
Backbone has 17 edges
Tree Edge 0-15: weight 7
Tree Edge 7-15: weight 10
...
Door 0-15: bottom/top
Door 7-15: bottom/top
...
Start room 0, end room 6 (12 doors away)
```

These are exactly the rooms the Rust generator produces for seed 42.

## Determinism check

Run the same seed twice and compare:

```sh
dotnet run -- --seed 42 2> a.txt
dotnet run -- --seed 42 2> b.txt
diff a.txt b.txt
```

No diff means generation is deterministic for that seed. This works because:

- every random value comes from one `Pcg32` seeded with the argument,
- that RNG object is passed through every step, in a fixed order,
- rooms are kept in a `List<Room>`, which always iterates in insertion order.

To check that the output is also the same as the **Rust** generator, see [Verification](verification.md).
