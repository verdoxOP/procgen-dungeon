# Configuration

[← Documentation home](README.md)

All tunable values are in [`constants.rs`](../src/constants.rs). VR-04 ("minimum room height and width must be configurable") is met by keeping these here instead of hard-coding them.

| Constant | Type | Value | Used in | Meaning |
|---|---|---|---|---|
| [`min_room_count`](../src/constants.rs#L1) | `usize` | 8 | [`generate_rooms`](../src/room_generation.rs#L25), [`validate_rooms`](../src/validation.rs#L5) | lowest target room count, and the minimum for a valid dungeon |
| [`max_room_count`](../src/constants.rs#L2) | `usize` | 20 | [`generate_rooms`](../src/room_generation.rs#L25) | highest target room count |
| [`mst`](../src/constants.rs#L3) | `i32` | 5 | — | unused |
| [`max_attempts`](../src/constants.rs#L4) | `i32` | 1000 | [`generate_rooms`](../src/room_generation.rs#L29) | room placement attempts per generation |
| [`MAX_GENERATION_ATTEMPTS`](../src/constants.rs#L5) | `i32` | 10 | [`main`](../src/main.rs#L58) | full regenerations before giving up |
| [`MIN_ROOM_WIDTH`](../src/constants.rs#L6) | `i32` | 8 | [`generate_room`](../src/room_generation.rs#L12), [`validate_rooms`](../src/validation.rs#L14) | minimum room width |
| [`MIN_ROOM_HEIGHT`](../src/constants.rs#L7) | `i32` | 8 | [`generate_room`](../src/room_generation.rs#L13), [`validate_rooms`](../src/validation.rs#L14) | minimum room height |
| [`MAX_ROOM_WIDTH`](../src/constants.rs#L8) | `i32` | 20 | [`generate_room`](../src/room_generation.rs#L12) | maximum room width |
| [`MAX_ROOM_HEIGHT`](../src/constants.rs#L9) | `i32` | 20 | [`generate_room`](../src/room_generation.rs#L13) | maximum room height |
| [`MAP_WIDTH`](../src/constants.rs#L10) | `i32` | 100 | [`generate_room`](../src/room_generation.rs#L19), [`main`](../src/main.rs#L83) | map width in tiles |
| [`MAP_HEIGHT`](../src/constants.rs#L11) | `i32` | 100 | [`generate_room`](../src/room_generation.rs#L20), [`main`](../src/main.rs#L83) | map height in tiles |
| `ENEMY_ROOM_CHANCE` | `i32` | 60 | [`population::random_room_kind`](../src/population.rs#L134-L143) | chance (out of 100) a non-start/end room becomes an enemy room |
| `ITEM_ROOM_CHANCE` | `i32` | 15 | [`population::random_room_kind`](../src/population.rs#L134-L143) | chance (out of 100) a non-start/end room becomes an item room; the rest become empty |
| `TILES_PER_ENEMY` | `i32` | 40 | [`population::enemy_count`](../src/population.rs#L127-L131) | floor tiles per enemy when sizing a room's enemy count |
| `MAX_ENEMIES_PER_ROOM` | `usize` | 6 | [`population::enemy_count`](../src/population.rs#L127-L131) | hard cap on enemies in one room (PV-03) |
| `AGGRESSIVE_CHANCE` | `i32` | 70 | [`population::random_behaviour`](../src/population.rs#L185-L191) | chance (out of 100) a spawned enemy is aggressive instead of passive |

Hard-coded elsewhere:

| Value | Where | Meaning |
|---|---|---|
| `1..=100` | [`edge.rs` L17](../src/edge.rs#L17) | edge weight range |
| `101` | [`tree.rs` L11](../src/tree.rs#L11) | starting "cheapest weight"; must stay above the max edge weight |

## Effects of changing values

| Change | Effect |
|---|---|
| Raise `max_room_count` a lot | map fills up, more rejected placements, may need more `max_attempts` |
| Raise `MIN_ROOM_*` / `MAX_ROOM_*` | bigger rooms, fewer fit, validation fails more often |
| Raise `MAP_WIDTH` / `MAP_HEIGHT` | more space, fewer rejections; the ASCII grid gets wider |
| Raise `min_room_count` | more generation attempts fail the count check |
| `MAX_ROOM_*` > `MAP_*` | `generate_room` panics: empty position range |
| `min_room_count` > `max_room_count` | `generate_rooms` panics: empty count range |
| Change the edge weight range | must also update the `101` in `build_tree` |
| `max_room_count` > 36 | ASCII grid symbols start repeating |

A rough way to check if the numbers fit: average room area × target rooms should stay well below map area. With the defaults: about 14 × 14 × 20 ≈ 3900 tiles out of 10 000, so there's enough space most of the time.

## Planned parameters

`MAX_ENEMIES_PER_ROOM` (PV-03) and the start-room-safety check (PV-07) are now implemented (see above and [`population.rs`](../src/population.rs)). Still not in the code as explicit numbers:

| Parameter | Rule |
|---|---|
| `min_enemies` | PV-01 (currently only "at least one non-hostile pickup exists" is checked) |
| `min_health` | PV-02 |
