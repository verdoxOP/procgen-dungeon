# Dungeon JSON (format_version 2)

What the Rust generator writes and `Scripts/dungeon_loader.gd` reads. Example: `test_dungeon.json`.

Every room is its own screen. Walking into a door loads the room on the other side; there are no hallways.

| Key | Type | Meaning |
|---|---|---|
| `format_version` | int | `2` |
| `seed` | int | seed used to generate this dungeon |
| `generator` | string | e.g. `"rust"` |
| `stats` | object | optional, for the report. `rooms_ms`, `edges_ms`, `tree_ms`, `doors_ms`, `bfs_ms`, `population_ms`: time per step in milliseconds (float). `total_ms`: the sum of those steps, without logging or process start-up. `generation_attempts`: how many times the rooms were generated before they were valid. Godot only shows `total_ms` in the HUD. |
| `rooms` | array | `{ id, x, y, width, height }` in tiles. `x, y` = top-left floor tile. The rectangle is **floor only**; Godot puts a 1-tile wall ring around it. Rooms may touch, they just can't overlap. |
| `start_room` | int | room id the player spawns in (centre of the room) |
| `end_room` | int | room id with the exit (centre of the room) |
| `doors` | array | backbone edges: `{ from, from_wall, to, to_wall, locked?, key_id? }` |
| `corridors` | array | hidden extra edges: `{ id, from, from_wall, to, to_wall }`. Both sides start behind a weak wall; shooting either side opens the passage. |
| `spawnables` | array | `{ type, x, y, ... }`, `x, y` in **map tiles** (inside a room's floor rectangle). Godot finds the room from the position. |

## Walls

`from_wall` / `to_wall` are `"top"`, `"bottom"`, `"left"` or `"right"`: the wall of that room the door is in. Godot doesn't check that they're opposite, so the generator decides what to do with diagonal neighbours.

Godot picks the exact tile itself: one door on a wall sits in the middle, several doors on the same wall are spread out evenly. The player arrives on the floor tile just inside the matching door of the other room.

## Spawnable types

| `type` | Extra fields |
|---|---|
| `enemy` | `enemy`: `"skeleton"`, `"skeleton2"`, `"vampire"` (unknown → skeleton), `behaviour`: `"aggressive"` or `"passive"` |
| `health` | `amount` |
| `ammo` | `amount` |
| `key` | `key_id` (opens doors with the same `key_id`) |
| `buff` | `buff`, e.g. `"damage_up"` |

Picked-up items and killed enemies stay gone when the player comes back to a room.
