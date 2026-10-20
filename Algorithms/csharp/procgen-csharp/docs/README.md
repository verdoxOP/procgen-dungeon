# procgen-csharp documentation

Developer documentation for the C# dungeon generator. For a quick overview and how to run it, see the [project README](../README.md).

All code references link to the exact lines in [`procgen-csharp/`](../procgen-csharp/). The C# generator is a port of the Rust generator, so many concepts (graph theory, the validation rules, most design decisions) are explained in the [Rust documentation](../../../rust/procgen_dungeon/docs/README.md) and linked from here instead of repeated.

## Pages

| Page | What's in it |
|---|---|
| [Getting started](getting-started.md) | Build, run, read the output, exit codes, determinism check |
| [Architecture](architecture.md) | Pipeline, data flow, classes and dependencies, mapping to the Rust modules |
| [Random number generator](rng.md) | How the Pcg32 port works and why it gives the same numbers as Rust |
| [Rooms](rooms.md) | `Room`, overlap check, room generation, validation and the retry loop |
| [Configuration](configuration.md) | Every constant and what changing it does |
| [Validation rules](validation-rules.md) | VR rules implemented so far, with code |
| [Verification](verification.md) | How the C# output is compared with Rust, and the results |
| [Design decisions](design-decisions.md) | C#-specific decisions and the differences from the Rust version |
| [Roadmap and known issues](roadmap.md) | Progress, next steps, test ideas |

## Code at a glance

| File | Responsibility | Main items |
|---|---|---|
| [`Program.cs`](../procgen-csharp/Program.cs) | entry point and pipeline | arguments, retry loop, exit codes |
| [`Constants.cs`](../procgen-csharp/Constants.cs) | tunable parameters | all constants |
| [`Pcg32.cs`](../procgen-csharp/Pcg32.cs) | seeded RNG | [`FromSeed`](../procgen-csharp/Pcg32.cs#L27-L42), [`NextU32`](../procgen-csharp/Pcg32.cs#L44-L49), [`RandomRange`](../procgen-csharp/Pcg32.cs#L52-L76) |
| [`Room.cs`](../procgen-csharp/Room.cs) | room data type | [`Room`](../procgen-csharp/Room.cs#L4-L10), [`Overlaps`](../procgen-csharp/Room.cs#L13-L24) |
| [`RoomGeneration.cs`](../procgen-csharp/RoomGeneration.cs) | placing rooms | [`GenerateRooms`](../procgen-csharp/RoomGeneration.cs#L7-L30), [`GenerateRoom`](../procgen-csharp/RoomGeneration.cs#L32-L44) |
| [`Validation.cs`](../procgen-csharp/Validation.cs) | checking rooms | [`ValidateRooms`](../procgen-csharp/Validation.cs#L7-L37) |
