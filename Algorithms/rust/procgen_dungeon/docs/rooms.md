# Rooms

[← Documentation home](README.md)

Covers [`room.rs`](../src/room.rs), [`room_generation.rs`](../src/room_generation.rs) and [`validation.rs`](../src/validation.rs).

## Coordinate system

The generator uses a **tile-based** coordinate system. Rooms are positioned on a 2D grid with `x` and `y`, and `width` and `height` are in tiles, not pixels. Godot is responsible for translating tile coordinates into the actual game world.

- `(0, 0)` is the top-left of the map. `x` grows to the right, `y` grows downwards.
- A room covers the tiles `x .. x + width` and `y .. y + height` (end exclusive).
- The map is `MAP_WIDTH × MAP_HEIGHT` tiles ([`constants.rs` L10–11](../src/constants.rs#L10-L11)).

Example from the brainstorm: a room with `x = 10, y = 12, width = 5, height = 4` covers:

```
x →    10 11 12 13 14
y  12   #  #  #  #  #
↓  13   #  #  #  #  #
   14   #  #  #  #  #
   15   #  #  #  #  #
```

## `Room` ([`room.rs` L1–8](../src/room.rs#L1-L8))

| Field | Type | Meaning |
|---|---|---|
| `width`, `height` | `i32` | size in tiles |
| `x`, `y` | `i32` | top-left corner in tiles |
| `id` | `usize` | index of this room in the rooms `Vec` |

`#[derive(Debug)]` lets `main` print rooms with `{:?}`.

The room has **no type field**. Whether a room is the start, the end, a treasure room, etc. is not stored in the room. See [Design decisions → Room design](design-decisions.md#room-design-what-kind-of-room-is-it).

### `room_overlap_check(&self, other: &Room) -> bool` ([L11–21](../src/room.rs#L11-L21))

Returns `true` if two rooms share at least one tile.

It first computes the right and bottom edges of both rooms ([L12–15](../src/room.rs#L12-L15)). Two rectangles **don't** overlap if one is completely on one side of the other ([L17–20](../src/room.rs#L17-L20)):

| Condition | Meaning |
|---|---|
| `self.x >= other_right` | self is fully to the right of other |
| `self_right <= other.x` | self is fully to the left of other |
| `self.y >= other_bottom` | self is fully below other |
| `self_bottom <= other.y` | self is fully above other |

If none of these is true, they overlap. The function returns the negation of "any of these is true".

Because the comparisons use `>=` / `<=`, two rooms that **touch** (share an edge but no tile) do not count as overlapping. That is intended: touching rooms are allowed.

| Room A | Room B | Result |
|---|---|---|
| x 0, w 10 | x 10, w 5 | touching → `false` |
| x 0, w 10 | x 9, w 5 | overlap on column 9 → `true` |
| x 0, w 10, y 0, h 10 | x 20, w 5, y 0, h 5 | far apart → `false` |

## Room generation ([`room_generation.rs`](../src/room_generation.rs))

### `generate_room(rng) -> Room` ([L11–22](../src/room_generation.rs#L11-L22), private)

1. Pick `width` in `MIN_ROOM_WIDTH..=MAX_ROOM_WIDTH` ([L12](../src/room_generation.rs#L12)).
2. Pick `height` in `MIN_ROOM_HEIGHT..=MAX_ROOM_HEIGHT` ([L13](../src/room_generation.rs#L13)).
3. Pick `x` in `0..=MAP_WIDTH - width` and `y` in `0..=MAP_HEIGHT - height` ([L19–20](../src/room_generation.rs#L19-L20)).

Size is picked first so the position range can guarantee the room always fits on the map. The returned room has `id: 0`; the real id is assigned when the room is accepted.

### `generate_rooms(rng) -> Vec<Room>` ([L24–47](../src/room_generation.rs#L24-L47))

1. Pick a target `room_count` in `min_room_count..=max_room_count` ([L25](../src/room_generation.rs#L25)).
2. While there are fewer rooms than the target **and** fewer than `max_attempts` attempts ([L29](../src/room_generation.rs#L29)):
   - generate a room,
   - if it overlaps any accepted room, throw it away ([L34–36](../src/room_generation.rs#L34-L36)),
   - otherwise set `id = rooms.len()` and push it ([L38–42](../src/room_generation.rs#L38-L42)).
3. Print the number of rooms and attempts, and return the rooms.

This technique is **rejection sampling**: generate randomly, keep only what passes the rule.

It can return fewer rooms than the target if the map fills up and `max_attempts` runs out. That is why the result is validated afterwards.

Because `id` is set to `rooms.len()` right before the push, ids are always `0, 1, 2, …` with no gaps, and `rooms[i].id == i`.

## Validation ([`validation.rs`](../src/validation.rs))

### `validate_rooms(rooms: &[Room]) -> bool` ([L4–32](../src/validation.rs#L4-L32))

Checks, in order, and returns `false` at the first failure:

| Check | Rule | Fails when | Code |
|---|---|---|---|
| count | VR-03 | `rooms.len() < min_room_count` | [L5–11](../src/validation.rs#L5-L11) |
| size | VR-01, VR-04 | any room below `MIN_ROOM_WIDTH` or `MIN_ROOM_HEIGHT` | [L13–18](../src/validation.rs#L13-L18) |
| overlap | VR-02 | any pair overlaps | [L20–29](../src/validation.rs#L20-L29) |

All rules: [Validation rules](validation-rules.md).

The overlap check loops over every **pair** once (`j` starts at `i + 1`), so it doesn't compare a room with itself or check the same pair twice. The same pair loop is used in [`generate_edges`](../src/edge.rs#L14-L15).

`generate_rooms` already rejects overlaps and can't generate rooms that are too small, so in normal runs only the count check can fail. The other checks are a safety net: validation should not trust the generator, because the generator may change later.

### Retry loop ([`main.rs` L55–61](../src/main.rs#L55-L61))

```
rooms = generate_rooms
attempts = 1
while rooms invalid and attempts < MAX_GENERATION_ATTEMPTS:
    attempts += 1
    rooms = generate_rooms
```

Each retry draws new numbers from the same RNG, so retries are still deterministic per seed.

If all attempts fail, the program currently continues with the last (invalid) room set. See [known issues](roadmap.md#known-issues).

### Manual test

[`main.rs` L32–53](../src/main.rs#L32-L53) holds a commented-out manual test: two rooms in the same position, which should make `validate_rooms` report an overlap (with `min_room_count` temporarily set to 2). This is a good candidate to turn into a real `#[test]`.
