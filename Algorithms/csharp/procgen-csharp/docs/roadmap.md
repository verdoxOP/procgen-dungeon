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
| Candidate edges (complete graph) | ⏳ next | | |
| Backbone with Prim | ⏳ planned | | |
| Doors (wall per connection) | ⏳ planned | | |
| JSON export to stdout | ⏳ planned | | |
| BFS: end room | ⏳ planned | | |
| `stats` (time and attempts per stage) | ⏳ planned | | |
| Corridors, population, locked doors | ⏳ after Rust has them | | |
| Unit tests | ⏳ planned | | |
| Copy into the game's `generators/` folder | ⏳ planned | | |

## Known issues

None in the C# code so far.

Differences from Rust that are deliberate (not bugs) are listed in [Design decisions](design-decisions.md). Known issues in the Rust generator that the port does **not** copy:

| Rust issue | C# |
|---|---|
| continues with invalid rooms when all generation attempts fail | exits with code 1 |
| unused `mst` constant | not ported |

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
