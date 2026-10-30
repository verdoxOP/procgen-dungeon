# Start, end and JSON output

[← Documentation home](README.md)

Covers [`Bfs.cs`](../procgen-csharp/Bfs.cs), [`DungeonJson.cs`](../procgen-csharp/DungeonJson.cs) and the end of [`Program.cs`](../procgen-csharp/Program.cs). Ports of [`bfs.rs`](../../../rust/procgen_dungeon/src/bfs.rs) and [`dungeon_json.rs`](../../../rust/procgen_dungeon/src/dungeon_json.rs).

## Start and end room

Rooms don't know their own role; the dungeon does (see [Rust → Design decisions → Room design](../../../rust/procgen_dungeon/docs/design-decisions.md#room-design-what-kind-of-room-is-it)).

| Role | Rule | Code |
|---|---|---|
| start room | always room `0` | [`Program.cs` L144](../procgen-csharp/Program.cs#L144) |
| end room | the room the **most doors away** from the start | [`Program.cs` L146–147](../procgen-csharp/Program.cs#L146-L147) |

"Most doors away" means the player has to cross the most rooms to reach the exit. Since the backbone is a tree, there is exactly one route, so this distance is fixed.

### `Bfs.RoomDistances(doors, roomCount, startRoom)` ([`Bfs.cs` L7–40](../procgen-csharp/Bfs.cs#L7-L40))

Breadth-first search over the doors:

1. Build a **neighbour list** per room from the doors, both ways, because a door works in both directions ([L10–19](../procgen-csharp/Bfs.cs#L10-L19)).
2. Set every distance to `-1` ("not reached"), and the start room to `0` ([L21–22](../procgen-csharp/Bfs.cs#L21-L22)).
3. Take rooms from a queue in order; every neighbour that hasn't been reached gets the room's distance + 1 and joins the queue ([L26–37](../procgen-csharp/Bfs.cs#L26-L37)).

BFS visits rooms layer by layer, so the first time a room is reached is always via the fewest doors. On the backbone every room is reached, so no distance stays `-1`.

### `Bfs.FurthestRoom(distances)` ([L43–55](../procgen-csharp/Bfs.cs#L43-L55))

Returns the room with the highest distance. Only a strictly higher distance (`>`) replaces the current choice ([L48](../procgen-csharp/Bfs.cs#L48)), so on a tie the **lowest room id wins**, as in Rust.

Seed 42: the end room is room 6, 12 doors away from room 0.

Neither function draws random numbers.

## JSON output ([`DungeonJson.cs`](../procgen-csharp/DungeonJson.cs))

`DungeonJson.Build(...)` ([L19–50](../procgen-csharp/DungeonJson.cs#L19-L50)) turns the dungeon into the JSON the game reads: `format_version` 2, described in the game's [`FORMAT.md`](../../../../GoDot-Project/dungeon-crawler/test_data/FORMAT.md). `Program` prints it to **stdout** ([L28](../procgen-csharp/Program.cs#L28)); that is the only thing on stdout.

| Key | Value | Source |
|---|---|---|
| `format_version` | `2` | `Constants.FormatVersion` |
| `seed` | the seed from the command line | `--seed` |
| `generator` | `"csharp"` | [`GeneratorName`](../procgen-csharp/DungeonJson.cs#L10) (Rust: `"rust"`) |
| `stats` | time per step and generation attempts | [`GenerationStats`](../procgen-csharp/GenerationStats.cs), see below |
| `rooms` | `width`, `height`, `x`, `y`, `id` per room | `RoomGeneration` |
| `start_room` | `0` | |
| `end_room` | furthest room | `Bfs` |
| `doors` | `from`, `to`, `from_wall`, `to_wall` per door, in tree order | `DoorGeneration` |
| `corridors` | always `[]` | corridors were cut from scope (see below) |
| `spawnables` | enemies and pickups: `type`, `x`, `y` and the fields of that type | [`Population`](population.md) |

### Same shape as Rust

The keys are written **in the same order** as Rust's `serde_json`: the small classes at the bottom of the file ([`DungeonDto`, `SpawnableDto`, `RoomDto`, `DoorDto`, L66–107](../procgen-csharp/DungeonJson.cs#L66-L107)) list their properties in that order, and `System.Text.Json` writes them in declaration order. `[JsonPropertyName]` gives the exact snake_case keys, and a `JsonStringEnumConverter` with camelCase naming writes the `Wall` enum as `"top"`, `"bottom"`, `"left"`, `"right"` ([L12–17](../procgen-csharp/DungeonJson.cs#L12-L17)). Both use 2-space indentation.

The game reads the JSON by key, so the order doesn't matter to it, but it means the C# and Rust output can be compared as text: for every seed tested (0–999) they are byte-for-byte identical apart from the `generator` name. Spawnables leave out the fields of other kinds (`JsonIgnore` when null), like serde's tagged enum.

The internal classes (`Room`, `Door`) stay free of JSON attributes; only the DTOs know about the format. In Rust the same mapping is done with `#[serde(rename = ...)]` on the structs themselves.

### Corridors cut from scope

Matt cut corridors from the project because of the deadline (commit `e3dc311`, see [Rust → Design decisions → Corridors](../../../rust/procgen_dungeon/docs/design-decisions.md#corridors)). `corridors` is always an empty array in both generators ([L45](../procgen-csharp/DungeonJson.cs#L45)). The game still supports corridors, so a test file with corridors keeps working.

## Stats: time per step

`stats` is there for the comparison between the languages. Matt and I added it to both generators at the same time, with the same keys in the same order ([`GenerationStats.cs`](../procgen-csharp/GenerationStats.cs), Rust: `Stats` in `dungeon_json.rs`):

| Key | What is timed |
|---|---|
| `rooms_ms` | `GenerateRooms` + `ValidateRooms`, including every retry |
| `edges_ms` | `GenerateEdges` |
| `tree_ms` | `BuildTree` |
| `doors_ms` | `GenerateDoors` |
| `bfs_ms` | `RoomDistances` + `FurthestRoom` |
| `population_ms` | `PopulateDungeon` + `ValidatePopulation` |
| `total_ms` | the sum of the six steps above |
| `generation_attempts` | how many times the rooms were generated (same number in both languages) |

How it is measured:

- `Stopwatch.GetTimestamp()` before a step, `Stopwatch.GetElapsedTime(start).TotalMilliseconds` after it, as a `double` so a fast step doesn't round down to 0. Rust uses `Instant::now()` and `elapsed().as_secs_f64() * 1000.0`.
- Only the step itself is timed. The logging `Program` does between the steps (every room, edge and door to stderr) is **not** part of the time, because logging speed differs per language and isn't the algorithm. `total_ms` is the sum of the steps for the same reason, not one timer around everything.
- The few log lines *inside* the steps (`Generated 18 rooms in 35 attempts`, validation messages) are timed, in both languages.
- Process start-up and building the JSON are not timed. The game measures the whole process separately ("process ms").

Results of the benchmark (`benchmark/` in the repository root, seeds 0–999, medians):

| | Rust | C# | C# / Rust |
|---|---|---|---|
| cold `total_ms`: one dungeon per process, like the game | 0.070 ms | 9.5 ms | 136× |
| cold `process_ms`: the whole process | 12.3 ms | 110 ms | 8.9× |
| warm `total_ms`: one process, after 3 warmup passes | 0.024 ms | 0.069 ms | 2.9× |

Cold, most of the C# time is JIT compilation: every method is compiled the first time it is called, and in a new process that happens inside the timed steps. Warm, that is gone and the algorithms themselves are compared: C# is faster at rooms and BFS, and slower mainly in population (4.3×). See [Design decisions → Target framework](design-decisions.md#target-framework) and the full tables in `benchmark/results/summary.md`.

## Running in the game

The easiest way: run `build-generators.ps1` (Windows) or `build-generators.sh` (Linux/macOS) from the repository root. It builds **both** generators, copies them into the game's `generators/` folder and tests each once (see the [root README](../../../../README.md#getting-started-after-cloning)).

By hand, for the C# generator only: publish a single exe and copy it into the game's `generators/` folder (gitignored):

```sh
dotnet publish -c Release -r win-x64 -p:SelfContained=false -p:PublishSingleFile=true -o publish
copy publish\procgen-csharp.exe ..\..\..\..\GoDot-Project\dungeon-crawler\generators\
```

`SelfContained=false` keeps the exe small (about 170 KB) by using the installed .NET runtime instead of bundling it (about 67 MB). The game's menu then lists `procgen-csharp` next to the Rust generator. See [Verification → check 10](verification.md#10-both-generators-in-the-game).
