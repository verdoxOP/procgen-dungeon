# Code size: Rust vs C#

Static program analysis of both generators, counted by `benchmark/code-size.mjs` on 2026-10-30.

- **code:** lines that are not empty and not only a comment
- **logic:** code lines that are not only brackets. C# puts `{` on its own line, Rust doesn't, so compare this column.

## Per step

| Step | Rust files | Rust code | Rust logic | C# files | C# code | C# logic | C# / Rust (logic) |
|---|---|---|---|---|---|---|---|
| RNG (Pcg32) | *(crates `rand`, `rand_pcg`)* | 0 | 0 | `Pcg32.cs` | 68 | 44 | – |
| Rooms | `room.rs`, `room_generation.rs` | 58 | 49 | `Room.cs`, `RoomGeneration.cs` | 59 | 41 | 0.84× |
| Room validation | `validation.rs` | 28 | 20 | `Validation.cs` | 32 | 16 | 0.80× |
| Edges | `edge.rs` | 23 | 18 | `Edge.cs`, `EdgeGeneration.cs` | 34 | 20 | 1.11× |
| Spanning tree (Prim) | `tree.rs` | 26 | 20 | `SpanningTree.cs` | 30 | 18 | 0.90× |
| Doors | `door.rs` | 58 | 49 | `Door.cs`, `DoorGeneration.cs` | 64 | 42 | 0.86× |
| BFS end room | `bfs.rs` | 31 | 23 | `Bfs.cs` | 46 | 26 | 1.13× |
| Population + validation | `population.rs` | 262 | 202 | `Spawnable.cs`, `Population.cs` | 234 | 138 | 0.68× |
| JSON + stats | `dungeon_json.rs` | 53 | 49 | `DungeonJson.cs`, `GenerationStats.cs` | 109 | 83 | 1.69× |
| Constants | `constants.rs` | 17 | 17 | `Constants.cs` | 20 | 18 | 1.06× |
| Main (arguments, pipeline, benchmark mode) | `main.rs` | 209 | 171 | `Program.cs`, `GeneratedDungeon.cs` | 171 | 119 | 0.70× |
| **Total** | | **765** | **618** | | **867** | **565** | **0.91×** |
| Total without the RNG | | 765 | 618 | | 799 | 521 | 0.84× |

Comment lines: Rust 46, C# 100.

Not counted above: Rust's debug output (`grid.rs`, `tree_visualization.rs`, 73 code lines), which C# doesn't have.

## Tests

| | Tests | Code lines | Where |
|---|---|---|---|
| Rust | 26 | 351 | `#[cfg(test)] mod tests` at the bottom of each file |
| C# | 26 | 383 | separate xUnit project `procgen-csharp.Tests` |

## Dependencies and build

| | Rust | C# |
|---|---|---|
| Libraries | `rand`, `rand_pcg`, `serde`, `serde_json` (crates.io) | none, only .NET's own library (`System.Text.Json`, `System.Diagnostics`) |
| RNG | from the `rand_pcg` crate | written by hand (`Pcg32.cs`, 44 logic lines) to give the same numbers as Rust |
| JSON | `#[derive(Serialize)]` on the structs | separate DTO classes with `[JsonPropertyName]` |
| Program in `generators/` | 1472 KB, native, runs on its own | 188 KB, needs the .NET 8 runtime installed |
