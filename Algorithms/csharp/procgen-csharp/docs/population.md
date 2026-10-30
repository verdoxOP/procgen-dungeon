# Population

[← Documentation home](README.md)

Covers [`Population.cs`](../procgen-csharp/Population.cs) and [`Spawnable.cs`](../procgen-csharp/Spawnable.cs). Port of [`population.rs`](../../../rust/procgen_dungeon/src/population.rs) (Rust commit `5eeafce`).

Population decides **what kind of room every room is** and places **spawnables**: enemies and pickups. It runs after the end room is known, with the same RNG, and its result goes into the `spawnables` array of the JSON.

## Data types

### `RoomKind` ([`Population.cs` L3–10](../procgen-csharp/Population.cs#L3-L10))

| Kind | Who gets it | What spawns |
|---|---|---|
| `Start` | room 0 | nothing (the player starts here) |
| `End` | the end room (BFS) | one boss: `vampire`, always aggressive |
| `Enemy` | random, 60 % | 1–6 enemies, depending on room size |
| `Item` | random, 15 % | one pickup: health, ammo or a buff |
| `Empty` | random, 25 % | nothing |

Room kinds are only used while populating; they are not in the JSON. The game works out what a room is from what's in it.

### `Spawnable` ([`Spawnable.cs`](../procgen-csharp/Spawnable.cs))

An abstract record with `X` and `Y` (tile position), and one record per kind:

| Record | Extra fields | JSON `type` | Rust variant |
|---|---|---|---|
| `EnemySpawn` | `Enemy` (`"skeleton"`, `"skeleton2"`, `"vampire"`), `Behaviour` (`"aggressive"` / `"passive"`) | `"enemy"` | `Spawnable::Enemy` |
| `HealthSpawn` | `Amount` (1) | `"health"` | `Spawnable::Health` |
| `AmmoSpawn` | `Amount` (10) | `"ammo"` | `Spawnable::Ammo` |
| `BuffSpawn` | `Buff` (`"damage_up"`) | `"buff"` | `Spawnable::Buff` |

`IsHostile` is `true` for enemies only: `Spawnable` returns `false` and `EnemySpawn` overrides it. The names are the ones the game knows (see the game's [`FORMAT.md`](../../../../GoDot-Project/dungeon-crawler/test_data/FORMAT.md)). A C# record hierarchy is the natural match for Rust's enum with data per variant; the JSON writer turns each record into `{"type": ..., "x", "y", ...}` with only that kind's fields ([`DungeonJson.cs` L53–63](../procgen-csharp/DungeonJson.cs#L53-L63)), like serde's tagged enum.

## Step 1: room kinds — `ChooseRoomKinds` ([L83–116](../procgen-csharp/Population.cs#L83-L116))

1. In id order: room 0 is `Start`, the end room is `End`, every other room rolls `0..=99` ([`RandomRoomKind`](../procgen-csharp/Population.cs#L183-L195)): below `EnemyRoomChance` (60) → `Enemy`, below 60 + `ItemRoomChance` (15) → `Item`, otherwise `Empty`.
2. **Fallback** ([L103–114](../procgen-csharp/Population.cs#L103-L114)): if no room rolled `Item`, a random normal room (not start or end) becomes an item room, so every run has something to pick up. This happens often: in 164 of the first 1000 seeds.

## Step 2: free tiles per room

- **Inside tiles only** ([`IsInsideRoom`](../procgen-csharp/Population.cs#L221-L224), [`SpawnTiles`](../procgen-csharp/Population.cs#L255-L269)): the outer ring of the room's floor is skipped, so nothing spawns against a wall.
- **Not near a door** ([`IsNearDoor`](../procgen-csharp/Population.cs#L249-L252)): the door tile and the 8 tiles around it are skipped. The door tile is the **middle** of the wall on the room's own outer ring ([`DoorTile`](../procgen-csharp/Population.cs#L127-L136)). See [Known issue](#known-issue-spawns-next-to-doors) below.
- Tiles are listed **row by row** (`y` outer, `x` inner), the same order as Rust. The order matters, because tiles are picked by index.

## Step 3: spawning — `PopulateDungeon` + `PopulateRoom` ([L23–80](../procgen-csharp/Population.cs#L23-L80))

For every room, in id order (`PopulateDungeon` finds the free tiles, `PopulateRoom` fills the room by its kind):

| Kind | Random calls, in order |
|---|---|
| `Start`, `Empty` | none |
| `End` | a tile |
| `Enemy` | for each of `EnemyCount(room)` enemies: a tile, an enemy kind (`0..=2`), a behaviour (`0..=99` < `AggressiveChance` = aggressive) |
| `Item` | a tile, then the item (`0..=2`: health, ammo, buff) |

**`EnemyCount(room)`** ([L119–123](../procgen-csharp/Population.cs#L119-L123)): inside area `(width − 2) · (height − 2)` divided by `TilesPerEnemy` (40), clamped to `1..=MaxEnemiesPerRoom` (6). An 8 × 8 room gets 1 enemy, a 20 × 20 room 6.

**`TakeRandomTile`** ([L205–218](../procgen-csharp/Population.cs#L205-L218)) picks a random index, takes that tile, and moves the **last** tile into the gap, like Rust's `Vec::swap_remove`. This is O(1) and guarantees two spawns never share a tile. A plain `List.RemoveAt(index)` would shift all later tiles instead, so the next pick would land on a different tile than in Rust.

## Step 4: validation — `ValidatePopulation` ([L138–180](../procgen-csharp/Population.cs#L138-L180))

Fails (exit code 1, no retry, same as Rust) when:

| Check | Rule |
|---|---|
| no pickup at all | the run has nothing to collect |
| a spawn is not inside any room | PV-05 (walkable tile) |
| a spawn is on or next to a door | keeps doorways free |
| something hostile in the start room | PV-07 (safe start room) |
| more enemies in a room than `EnemyCount` allows | PV-03 |

Two spawns never share a tile (PV-04) by construction (`TakeRandomTile`), so it isn't checked separately. In the first 1000 seeds validation never fails, in either language: the fallback guarantees a pickup, and every room (at least 8 × 8) has enough free tiles. See [Validation rules](validation-rules.md).

## Known issue: spawns next to doors

`DoorTile` assumes a door is in the **middle** of its wall. The game, however, spreads doors out when a wall has two or more of them (`Dungeon.place_openings` in the game). So the "not near a door" check protects the wrong spot on those walls.

Measured with the Rust output for seeds 0–999 against the door positions the game uses: **304 of 22 349 spawnables (265 of them enemies) are on or next to the tile where the player enters a room, in 260 of the 1000 seeds.** Walls with two or more doors occur 4975 times.

The C# version copies this on purpose, because the output must stay identical to Rust. The fix belongs in both generators: `DoorTile` should place doors the way the game does (offset `length · (i + 1) / (count + 1)` along the wall). Reported to Matt; see [Roadmap](roadmap.md#known-issues).

## Constants

In [`Constants.cs` L23–31](../procgen-csharp/Constants.cs#L23-L31), same values as `constants.rs`:

| Constant | Value | Meaning |
|---|---|---|
| `EnemyRoomChance` | 60 | chance (out of 100) a normal room is an enemy room |
| `ItemRoomChance` | 15 | chance an item room (the rest, 25, is empty) |
| `TilesPerEnemy` | 40 | one enemy per this many inside tiles |
| `MaxEnemiesPerRoom` | 6 | upper limit per room |
| `AggressiveChance` | 70 | chance an enemy is aggressive instead of passive |

The enemy and item names and the amounts (health 1, ammo 10) are private constants in `Population`, as in `population.rs`.
