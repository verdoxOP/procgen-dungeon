# Configuration

[← Documentation home](README.md)

All tunable values are in [`Constants.cs`](../procgen-csharp/Constants.cs). They have the **same values** as [`constants.rs`](../../../rust/procgen_dungeon/src/constants.rs) in the Rust generator; that is required for both generators to produce the same dungeon.

| Constant | Value | Used in | Meaning | Rust name |
|---|---|---|---|---|
| [`MinRoomCount`](../procgen-csharp/Constants.cs#L6) | 8 | [`GenerateRooms`](../procgen-csharp/RoomGeneration.cs#L9), [`ValidateRooms`](../procgen-csharp/Validation.cs#L9) | lowest target room count, and the minimum for a valid dungeon | `min_room_count` |
| [`MaxRoomCount`](../procgen-csharp/Constants.cs#L7) | 20 | [`GenerateRooms`](../procgen-csharp/RoomGeneration.cs#L9) | highest target room count | `max_room_count` |
| [`MaxPlacementAttempts`](../procgen-csharp/Constants.cs#L9) | 1000 | [`GenerateRooms`](../procgen-csharp/RoomGeneration.cs#L13) | room placement attempts per generation | `max_attempts` |
| [`MaxGenerationAttempts`](../procgen-csharp/Constants.cs#L11) | 10 | [`Program`](../procgen-csharp/Program.cs#L18) | full regenerations before giving up | `MAX_GENERATION_ATTEMPTS` |
| [`MinRoomWidth`](../procgen-csharp/Constants.cs#L13) | 8 | [`GenerateRoom`](../procgen-csharp/RoomGeneration.cs#L34), [`ValidateRooms`](../procgen-csharp/Validation.cs#L17) | minimum room width | `MIN_ROOM_WIDTH` |
| [`MinRoomHeight`](../procgen-csharp/Constants.cs#L14) | 8 | [`GenerateRoom`](../procgen-csharp/RoomGeneration.cs#L35), [`ValidateRooms`](../procgen-csharp/Validation.cs#L17) | minimum room height | `MIN_ROOM_HEIGHT` |
| [`MaxRoomWidth`](../procgen-csharp/Constants.cs#L15) | 20 | [`GenerateRoom`](../procgen-csharp/RoomGeneration.cs#L34) | maximum room width | `MAX_ROOM_WIDTH` |
| [`MaxRoomHeight`](../procgen-csharp/Constants.cs#L16) | 20 | [`GenerateRoom`](../procgen-csharp/RoomGeneration.cs#L35) | maximum room height | `MAX_ROOM_HEIGHT` |
| [`MapWidth`](../procgen-csharp/Constants.cs#L18) | 100 | [`GenerateRoom`](../procgen-csharp/RoomGeneration.cs#L41) | map width in tiles | `MAP_WIDTH` |
| [`MapHeight`](../procgen-csharp/Constants.cs#L19) | 100 | [`GenerateRoom`](../procgen-csharp/RoomGeneration.cs#L42) | map height in tiles | `MAP_HEIGHT` |
| [`FormatVersion`](../procgen-csharp/Constants.cs#L21) | 2 | not used yet (JSON export) | JSON format version | `FORMAT_VERSION` |

Rust's `mst` constant is not ported: it is unused in Rust.

C# naming: constants use PascalCase, the normal .NET convention, instead of Rust's `SCREAMING_CASE`. `max_attempts` became `MaxPlacementAttempts` to make clear it counts room placements, not generation attempts.

## Keep both generators in sync

If a value changes in one generator, it has to change in the other too, otherwise the same seed gives different dungeons and the comparison is no longer fair. A quick check after changing anything: run the [verification](verification.md) for a few seeds.

## Effects of changing values

The same as in Rust, see [Rust → Configuration → Effects of changing values](../../../rust/procgen_dungeon/docs/configuration.md#effects-of-changing-values). The C#-specific differences:

| Change | Rust | C# |
|---|---|---|
| `MaxRoomWidth` > `MapWidth` | panics (empty range) | `ArgumentException` from `RandomRange` |
| `MinRoomCount` > `MaxRoomCount` | panics | `ArgumentException` from `RandomRange` |
| smaller map, e.g. 40 × 40 | room validation fails more often, retries happen | same, and exit code 1 if all attempts fail |
