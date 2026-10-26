# Start, end and JSON output

[← Documentation home](README.md)

Covers [`Bfs.cs`](../procgen-csharp/Bfs.cs), [`DungeonJson.cs`](../procgen-csharp/DungeonJson.cs) and the end of [`Program.cs`](../procgen-csharp/Program.cs). Ports of [`bfs.rs`](../../../rust/procgen_dungeon/src/bfs.rs) and [`dungeon_json.rs`](../../../rust/procgen_dungeon/src/dungeon_json.rs).

## Start and end room

Rooms don't know their own role; the dungeon does (see [Rust → Design decisions → Room design](../../../rust/procgen_dungeon/docs/design-decisions.md#room-design-what-kind-of-room-is-it)).

| Role | Rule | Code |
|---|---|---|
| start room | always room `0` | [`Program.cs` L61](../procgen-csharp/Program.cs#L61) |
| end room | the room the **most doors away** from the start | [`Program.cs` L62–63](../procgen-csharp/Program.cs#L62-L63) |

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

`DungeonJson.Build(...)` ([L19–49](../procgen-csharp/DungeonJson.cs#L19-L49)) turns the dungeon into the JSON the game reads: `format_version` 2, described in the game's [`FORMAT.md`](../../../../GoDot-Project/dungeon-crawler/test_data/FORMAT.md). `Program` prints it to **stdout** ([L80](../procgen-csharp/Program.cs#L80)); that is the only thing on stdout.

| Key | Value | Source |
|---|---|---|
| `format_version` | `2` | `Constants.FormatVersion` |
| `seed` | the seed from the command line | `--seed` |
| `generator` | `"csharp"` | [`GeneratorName`](../procgen-csharp/DungeonJson.cs#L10) (Rust: `"rust"`) |
| `rooms` | `width`, `height`, `x`, `y`, `id` per room | `RoomGeneration` |
| `start_room` | `0` | |
| `end_room` | furthest room | `Bfs` |
| `doors` | `from`, `to`, `from_wall`, `to_wall` per door, in tree order | `DoorGeneration` |
| `corridors` | always `[]` | corridors were cut from scope (see below) |
| `spawnables` | enemies and pickups: `type`, `x`, `y` and the fields of that type | [`Population`](population.md) |

### Same shape as Rust

The keys are written **in the same order** as Rust's `serde_json`: the small classes at the bottom of the file ([`DungeonDto`, `SpawnableDto`, `RoomDto`, `DoorDto`, L65–105](../procgen-csharp/DungeonJson.cs#L65-L105)) list their properties in that order, and `System.Text.Json` writes them in declaration order. `[JsonPropertyName]` gives the exact snake_case keys, and a `JsonStringEnumConverter` with camelCase naming writes the `Wall` enum as `"top"`, `"bottom"`, `"left"`, `"right"` ([L12–17](../procgen-csharp/DungeonJson.cs#L12-L17)). Both use 2-space indentation.

The game reads the JSON by key, so the order doesn't matter to it, but it means the C# and Rust output can be compared as text: for every seed tested (0–999) they are byte-for-byte identical apart from the `generator` name. Spawnables leave out the fields of other kinds (`JsonIgnore` when null), like serde's tagged enum.

The internal classes (`Room`, `Door`) stay free of JSON attributes; only the DTOs know about the format. In Rust the same mapping is done with `#[serde(rename = ...)]` on the structs themselves.

### Corridors cut from scope

Matt cut corridors from the project because of the deadline (commit `e3dc311`, see [Rust → Design decisions → Corridors](../../../rust/procgen_dungeon/docs/design-decisions.md#corridors)). `corridors` is always an empty array in both generators ([L44](../procgen-csharp/DungeonJson.cs#L44)). The game still supports corridors, so a test file with corridors keeps working.

## Running in the game

Publish a single exe and copy it into the game's `generators/` folder (gitignored):

```sh
dotnet publish -c Release -r win-x64 -p:SelfContained=false -p:PublishSingleFile=true -o publish
copy publish\procgen-csharp.exe ..\..\..\..\GoDot-Project\dungeon-crawler\generators\
```

`SelfContained=false` keeps the exe small (about 170 KB) by using the installed .NET runtime instead of bundling it (about 67 MB). The game's menu then lists `procgen-csharp` next to the Rust generator. See [Verification → check 10](verification.md#10-both-generators-in-the-game).
