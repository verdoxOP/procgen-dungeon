# Validation rules

[← Documentation home](README.md)

The rules, their origin in the brainstorm document and the full list (VR, BV, CV, PV) are in [Rust → Validation rules](../../../rust/procgen_dungeon/docs/validation-rules.md). This page only shows what the C# generator implements so far.

## VR: room validation

| Rule | Description | Status | Code |
|---|---|---|---|
| VR-01 | rooms must be at least a minimum size | ✅ | [`Validation.cs` L15–22](../procgen-csharp/Validation.cs#L15-L22) |
| VR-02 | rooms are not allowed to overlap | ✅ | [`Validation.cs` L24–34](../procgen-csharp/Validation.cs#L24-L34), [`Room.Overlaps`](../procgen-csharp/Room.cs#L13-L24) |
| VR-03 | at least N rooms must be successfully generated | ✅ | [`Validation.cs` L9–13](../procgen-csharp/Validation.cs#L9-L13) |
| VR-04 | minimum room width and height must be configurable | ✅ | [`Constants.cs` L13–14](../procgen-csharp/Constants.cs#L13-L14) |

On failure the whole room set is regenerated with the same RNG, up to `MaxGenerationAttempts` times ([`DungeonGenerator.cs` L21–26](../procgen-csharp/DungeonGenerator.cs#L21-L26)). If it is still invalid, the program exits with code 1 ([L29–33](../procgen-csharp/DungeonGenerator.cs#L29-L33)).

The checks run in the same order as in Rust and stop at the first failure. The order doesn't affect the dungeon (validation draws no random numbers), only which reason is printed.

## PV: population validation

Same checks as `validate_population` in Rust ([`Population.ValidatePopulation`](../procgen-csharp/Population.cs#L138-L180)). On failure the program exits with code 1; there is no retry (also as in Rust).

| Rule | Description | Status | How |
|---|---|---|---|
| PV-01 | at least a minimum number of enemies | ❌ not checked | enemy rooms make it likely, but nothing enforces it (same in Rust) |
| PV-02 | at least a minimum of health / pickups | 🟡 at least **one** pickup | the item-room fallback guarantees it; validation checks it |
| PV-03 | at most a maximum of enemies per room | ✅ | no room has more enemies than `EnemyCount` allows |
| PV-04 | spawnables don't share a tile | ✅ by construction | `TakeRandomTile` removes every used tile |
| PV-05 | spawnables on walkable tiles | ✅ | every spawn must be inside a room, not on the outer ring or next to a door |
| PV-06 | important resources reachable from the start | ✅ by construction | every room is on the backbone and there are no locked doors |
| PV-07 | start room safety | ✅ | nothing hostile in the start room |

The door check has a known limitation: see [Population → Known issue](population.md#known-issue-spawns-next-to-doors).

## Other stages

| Prefix | Stage | C# status |
|---|---|---|
| BV | backbone validation | no separate check, in Rust either: the backbone is a spanning tree, so every room is reachable and it has n − 1 edges by construction |
| CV | corridor validation | ❌ cut: corridors were cut from scope (Rust `e3dc311`) |
| PV | population validation | ✅ see above |
