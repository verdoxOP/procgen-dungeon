# Roadmap and known issues

[← Documentation home](README.md)

## Progress

Port order follows the Rust generator (see [Architecture → Porting approach](architecture.md#porting-approach)).

| Stage | Status | Code | Verified against Rust |
|---|---|---|---|
| Seeded RNG (`Pcg32`) | ✅ done | [`Pcg32.cs`](../procgen-csharp/Pcg32.cs) | ✅ identical |
| Command line (`--seed`, exit codes) | ✅ done | [`Program.cs`](../procgen-csharp/Program.cs) | n/a |
| Room generation | ✅ done | [`RoomGeneration.cs`](../procgen-csharp/RoomGeneration.cs) | ✅ seeds 0–29 |
| Room validation + retry loop | ✅ done | [`Validation.cs`](../procgen-csharp/Validation.cs) | ✅ 40 × 40 map, seeds 0–199 |
| Candidate edges (complete graph) | ✅ done | [`EdgeGeneration.cs`](../procgen-csharp/EdgeGeneration.cs) | ✅ seeds 0–49 |
| Backbone with Prim | ✅ done | [`SpanningTree.cs`](../procgen-csharp/SpanningTree.cs) | ✅ seeds 0–99 |
| Doors (wall per connection) | ✅ done | [`DoorGeneration.cs`](../procgen-csharp/DoorGeneration.cs) | ✅ seeds 0–299 |
| JSON export to stdout | ✅ done | [`DungeonJson.cs`](../procgen-csharp/DungeonJson.cs) | ✅ seeds 0–299 |
| BFS: end room | ✅ done | [`Bfs.cs`](../procgen-csharp/Bfs.cs) | ✅ seeds 0–299 |
| Population + population validation | ✅ done | [`Population.cs`](../procgen-csharp/Population.cs) | ✅ seeds 0–999, byte-identical JSON |
| `stats` (time and attempts per stage) | ⏳ next (not in Rust yet either) | | |
| Corridors | ❌ cut from scope (also in Rust, `e3dc311`) | | |
| Locked doors and keys | ⏳ only if Rust adds them | | |
| Unit tests | ✅ done: Matt's 26 Rust tests translated one to one, all pass | [`procgen-csharp.Tests`](../procgen-csharp.Tests), [Test plan](test-plan.md), [Test report](test-report.md) | same tests as Rust |
| Runs in the game's `generators/` folder | ✅ done | [Output](output.md#running-in-the-game) | ✅ same dungeon as Rust in the game |

## Known issues

| Issue | Where | Status |
|---|---|---|
| Spawns can end up next to a door on walls with 2+ doors, because `DoorTile` assumes the door is in the middle while the game spreads doors out. 304 spawns (265 enemies) in 260 of seeds 0–999. | both generators (`population.rs` / `Population.DoorTile`) | reported to Matt; fix both together so the output stays identical, see [Population](population.md#known-issue-spawns-next-to-doors) |

No other issues in the C# code so far.

Differences from Rust that are deliberate (not bugs) are listed in [Design decisions](design-decisions.md). Known issues in the Rust generator that the port does **not** copy:

| Rust issue | C# |
|---|---|
| continued with invalid rooms when all generation attempts failed (fixed in Rust in `5eeafce`) | exits with code 1 |
| unused `mst` constant | not ported |
| `build_tree`: starting weight `101`, a loop that runs once, edge 0 pushed again if nothing is found | none of these, same tree (see [Graph and backbone](graph.md#differences-from-treers-same-result)) |

## Test ideas

Matt's 26 Rust tests are now translated to xUnit (see [Test plan](test-plan.md)). They already cover determinism, rooms in the map, overlap, room ids, `ValidateRooms`, the complete graph, the spanning tree, door walls and the tie, BFS, and PV-03 / PV-04 / PV-07.

Still open: C#-specific tests and the checks that are only done by hand in [Verification](verification.md):

| Test | Checks |
|---|---|
| `FromStateAndStream(42, 54)` gives the official PCG32 numbers | PCG core |
| `FromSeed` + `RandomRange` give the recorded Rust numbers for a few seeds | seeding and range sampling |
| `RandomRange(low, high)` stays within `low..=high` | range |
| seed 42 gives the same 18 rooms as Rust | regression against Rust |
| every weight is within `MinWeight..=MaxWeight` | `GenerateEdges` |
| on equal weights the first edge in the list is chosen | `BuildTree` tie-break |
| a small hand-made graph gives the known minimum spanning tree | `BuildTree` |
| one door per tree edge, in tree order | `GenerateDoors` |
| the JSON has the keys of `FORMAT.md` in Rust's order; walls are lowercase | `DungeonJson` |
| seed 42 JSON equals a stored Rust JSON (except `generator`) | regression against Rust |
| `EnemyCount`: 8 × 8 → 1, 20 × 20 → 6 | `Population` |
| start room and empty rooms get no spawnables; the end room gets exactly one aggressive vampire | `PopulateDungeon` |
| all spawnables inside a room and away from doors | PV-05 |
| `ValidatePopulation` rejects: no pickup, a spawn outside a room, an enemy in the start room, too many enemies | `ValidatePopulation` |
