# Validation rules

[← Documentation home](README.md)

Every generation stage is validated before the next stage runs. If validation fails, that stage is retried, with a maximum number of attempts. These rules come from the brainstorm document.

Rule prefixes:

| Prefix | Stage |
|---|---|
| **VR** | room validation |
| **BV** | backbone validation (rules still to be written) |
| **CV** | corridor validation |
| **PV** | population validation |

## VR: room validation

| Rule | Description | Status | Code |
|---|---|---|---|
| VR-01 | rooms must be at least a minimum size (depends on the map tile size) | ✅ | [`validation.rs` L13–18](../src/validation.rs#L13-L18) |
| VR-02 | rooms are not allowed to overlap | ✅ | [`validation.rs` L20–29](../src/validation.rs#L20-L29), [`room.rs` L11–21](../src/room.rs#L11-L21) |
| VR-03 | at least N rooms must be successfully generated | ✅ | [`validation.rs` L5–11](../src/validation.rs#L5-L11) |
| VR-04 | minimum room width and height must be configurable | ✅ | [`constants.rs` L6–7](../src/constants.rs#L6-L7) |

On failure the whole room set is regenerated, up to `MAX_GENERATION_ATTEMPTS` times ([`main.rs` L55–61](../src/main.rs#L55-L61)).

Touching rooms pass VR-02; only rooms that share a tile fail. See [Rooms](rooms.md).

### Removed rule: VR-05

The brainstorm first had:

> ~~VR-05: a minimum amount of item X must be spawned in the whole level (ammo, health, enemies, etc.)~~

**Why removed:** this is about spawnables, not rooms. Rooms are validated before anything is spawned, so this check belongs in population validation. It became PV-01 and PV-02.

An idea that was dropped along the way: spawning a random number of aggressive and passive spawnables and spreading them **evenly** across rooms. Equal distribution doesn't work well with randomised rooms, so it was replaced by the per-room and per-dungeon limits below.

## PV: population validation

| Rule | Description | Status |
|---|---|---|
| PV-01 | the dungeon must contain at least `min_enemies` enemies | ⏳ planned |
| PV-02 | the dungeon must contain at least `min_health` health pickups | ⏳ planned |
| PV-03 | a room may not exceed `max_enemies_per_room` | ⏳ planned |
| PV-04 | spawnables may not occupy the same tile | ⏳ planned |
| PV-05 | spawnables must be placed on walkable tiles | ⏳ planned |
| PV-06 | important resources must be reachable from the starting room | ⏳ planned |
| PV-07 | the starting room must meet its configured safety rules | ⏳ planned |

PV-06 depends on the graph: "reachable" means there is a path of doors from the start room. On the backbone that's always true; it only becomes a real check once locked doors exist.

## CV: corridor validation

| Rule | Description | Status |
|---|---|---|
| CV | corridors may not skip the majority of the stage. Example: connecting room 1 to room 5 is not allowed; room 4 to room 6 or room 1 to room 3 is | ⏳ planned |

Still open: how "skipping" is measured. Room ids don't say anything about position in the dungeon, so the most likely measure is the BFS distance (number of doors) between the two rooms on the backbone. See [Roadmap → open questions](roadmap.md#open-questions).

## BV: backbone validation

Not written yet. Things the backbone has to guarantee (from the brainstorm):

- every room is reachable from the start room,
- the tree has exactly `n − 1` edges,
- if locked doors are added (nice-to-have): the key for a locked door may never be behind that same locked door.

## Measurable parameters

Feedback from Patrick (12 Oct): define the parameters the algorithm has to meet, so progress becomes measurable. The validation rules above are the starting point; turning them into numbers that are checked and reported per run is still open (see [Roadmap](roadmap.md#open-questions)).
