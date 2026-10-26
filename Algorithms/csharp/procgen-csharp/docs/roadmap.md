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
| JSON export to stdout | ⏳ next | | |
| BFS: end room | ⏳ planned | | |
| `stats` (time and attempts per stage) | ⏳ planned | | |
| Population + population validation (in Rust since `5eeafce`) | ⏳ planned | | |
| Corridors, locked doors | ⏳ after Rust has them | | |
| Unit tests | ⏳ planned | | |
| Copy into the game's `generators/` folder | ⏳ planned | | |

## Known issues

None in the C# code so far.

Differences from Rust that are deliberate (not bugs) are listed in [Design decisions](design-decisions.md). Known issues in the Rust generator that the port does **not** copy:

| Rust issue | C# |
|---|---|
| continued with invalid rooms when all generation attempts failed (fixed in Rust in `5eeafce`) | exits with code 1 |
| unused `mst` constant | not ported |
| `build_tree`: starting weight `101`, a loop that runs once, edge 0 pushed again if nothing is found | none of these, same tree (see [Graph and backbone](graph.md#differences-from-treers-same-result)) |

## Test ideas

Things to turn into unit tests (e.g. xUnit), most of them already checked by hand in [Verification](verification.md):

| Test | Checks |
|---|---|
| `FromStateAndStream(42, 54)` gives the official PCG32 numbers | PCG core |
| `FromSeed` + `RandomRange` give the recorded Rust numbers for a few seeds | seeding and range sampling |
| `RandomRange(low, high)` stays within `low..=high` | range |
| same seed twice → same rooms | determinism |
| every room fits inside the map | room generation |
| no two rooms overlap | VR-02 |
| touching rooms don't count as overlap | `Room.Overlaps` |
| room ids equal their index | `GenerateRooms` |
| `ValidateRooms` rejects too few rooms, a too-small room, and two overlapping rooms | VR-01 – VR-03 |
| seed 42 gives the same 18 rooms as Rust | regression against Rust |
| n rooms give n · (n − 1) / 2 edges, each pair once, no self-loops | `GenerateEdges` |
| every weight is within `MinWeight..=MaxWeight` | `GenerateEdges` |
| the tree has n − 1 edges and reaches every room | `BuildTree` |
| on equal weights the first edge in the list is chosen | `BuildTree` tie-break |
| a small hand-made graph gives the known minimum spanning tree | `BuildTree` |
| room B right of / left of / below / above room A gives right / left / bottom / top for A and the opposite for B | `EdgeToDoor` |
| `\|dx\| = \|dy\|` gives a left/right door | `EdgeToDoor` tie |
| one door per tree edge, in tree order | `GenerateDoors` |
