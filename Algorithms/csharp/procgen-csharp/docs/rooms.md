# Rooms

[← Documentation home](README.md)

Covers [`Room.cs`](../procgen-csharp/Room.cs), [`RoomGeneration.cs`](../procgen-csharp/RoomGeneration.cs), [`Validation.cs`](../procgen-csharp/Validation.cs) and the retry loop in [`Program.cs`](../procgen-csharp/Program.cs).

The coordinate system is the same as in Rust: tiles, `(0, 0)` top-left, `x` to the right, `y` down, and a room covers `x .. x + Width` by `y .. y + Height` (end exclusive). See [Rust → Rooms → Coordinate system](../../../rust/procgen_dungeon/docs/rooms.md#coordinate-system) for an example.

## `Room` ([`Room.cs` L4–10](../procgen-csharp/Room.cs#L4-L10))

| Property | Type | Meaning |
|---|---|---|
| `Id` | `int` | index of this room in the rooms list |
| `X`, `Y` | `int` | top-left floor tile |
| `Width`, `Height` | `int` | size in tiles, floor only |

Like in Rust, the room has **no type field**: the dungeon decides which room is the start or the end, not the room itself.

Rust uses `usize` for the id; C# uses `int`, the normal type for list indexes.

### `Overlaps(Room other)` ([L13–24](../procgen-csharp/Room.cs#L13-L24))

Returns `true` if the two rooms share at least one tile. Same logic as Rust's `room_overlap_check`: two rectangles don't overlap if one is completely to the left, right, above or below the other; the method returns the negation of that.

| Room A | Room B | Result |
|---|---|---|
| x 0, w 10 | x 10, w 5 | touching → `false` |
| x 0, w 10 | x 9, w 5 | overlap on column 9 → `true` |
| x 0, w 10, y 0, h 10 | x 20, w 5, y 0, h 5 | far apart → `false` |

Rooms that **touch** don't count as overlapping. The game puts its own wall ring around each room, so touching rooms are fine.

### `ToString()` ([L26–29](../procgen-csharp/Room.cs#L26-L29))

`Room 0: x 81, y 33, 18x9`. Used for the log output and by the verification scripts.

## Room generation ([`RoomGeneration.cs`](../procgen-csharp/RoomGeneration.cs))

### `GenerateRoom(rng)` ([L32–44](../procgen-csharp/RoomGeneration.cs#L32-L44), private)

1. `Width` in `MinRoomWidth..=MaxRoomWidth` ([L34](../procgen-csharp/RoomGeneration.cs#L34)),
2. `Height` in `MinRoomHeight..=MaxRoomHeight` ([L35](../procgen-csharp/RoomGeneration.cs#L35)),
3. `X` in `0..=MapWidth − Width` and `Y` in `0..=MapHeight − Height` ([L41–42](../procgen-csharp/RoomGeneration.cs#L41-L42)).

Size first, so the position range guarantees the room fits on the map.

**The order of these four calls is fixed.** It's the same order as in `room_generation.rs`; swapping two of them would give different rooms than Rust for every seed.

### `GenerateRooms(rng)` ([L7–30](../procgen-csharp/RoomGeneration.cs#L7-L30))

1. Pick a target room count in `MinRoomCount..=MaxRoomCount` ([L9](../procgen-csharp/RoomGeneration.cs#L9)).
2. While there are fewer rooms than the target and fewer than `MaxPlacementAttempts` attempts ([L13](../procgen-csharp/RoomGeneration.cs#L13)):
   - generate a room,
   - throw it away if it overlaps any accepted room ([L18](../procgen-csharp/RoomGeneration.cs#L18)),
   - otherwise set `Id = rooms.Count` and add it ([L20–25](../procgen-csharp/RoomGeneration.cs#L20-L25)).
3. Log the number of rooms and attempts to stderr and return the list.

This is **rejection sampling**: generate randomly, keep what passes the rule. It can return fewer rooms than the target if the map fills up, which is why the result is validated afterwards.

`rooms.Any(...)` (LINQ) stops at the first overlap, the same as Rust's `iter().any(...)`. It doesn't draw random numbers, so it has no effect on determinism.

## Validation ([`Validation.cs`](../procgen-csharp/Validation.cs))

### `ValidateRooms(rooms)` ([L7–37](../procgen-csharp/Validation.cs#L7-L37))

Checks in order and returns `false` at the first failure, with the reason on stderr:

| Check | Rule | Fails when | Code |
|---|---|---|---|
| count | VR-03 | `rooms.Count < MinRoomCount` | [L9–13](../procgen-csharp/Validation.cs#L9-L13) |
| size | VR-01, VR-04 | a room below `MinRoomWidth` or `MinRoomHeight` | [L15–22](../procgen-csharp/Validation.cs#L15-L22) |
| overlap | VR-02 | any pair overlaps | [L24–34](../procgen-csharp/Validation.cs#L24-L34) |

The overlap loop checks every **pair** once (`j` starts at `i + 1`).

As in Rust, `GenerateRooms` can't produce rooms that are too small or overlap, so in practice only the count check can fail. The other checks are a safety net in case generation changes later. See [Validation rules](validation-rules.md).

## Retry loop ([`Program.cs` L18–34](../procgen-csharp/Program.cs#L18-L34))

```
rooms = GenerateRooms(rng)
attempts = 1
while rooms invalid and attempts < MaxGenerationAttempts:
    attempts += 1
    rooms = GenerateRooms(rng)
if still invalid: exit 1
```

Each retry draws **new** numbers from the **same** RNG, so retries are deterministic per seed and match Rust's retries number for number.

When all attempts fail, C# exits with code 1, as the command-line contract requires. The Rust generator does the same since commit `5eeafce`; before that it continued with the invalid rooms.

### How often does it retry?

With the default settings: practically never. In seeds 0–2999 the Rust generator needed a second attempt **zero** times, because 8 rooms almost always fit on a 100 × 100 map. To test the retry path, both generators were run on a 40 × 40 map instead (see [Verification](verification.md)).

For the comparison between languages this means the "attempts" for the room stage will almost always be 1 with the current settings.
