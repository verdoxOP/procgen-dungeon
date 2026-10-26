using System.Text.Json;
using System.Text.Json.Serialization;

namespace procgen_csharp;

// The dungeon in the JSON format Godot reads (format_version 2, see the game's test_data/FORMAT.md).
// Same keys, same order and same values as dungeon_json.rs, except "generator".
public static class DungeonJson
{
    public const string GeneratorName = "csharp";

    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = true,
        // Walls as "top", "bottom", "left", "right".
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
    };

    public static string Build(ulong seed, List<Room> rooms, List<Door> doors, List<Spawnable> spawnables, int startRoom, int endRoom)
    {
        var dungeon = new DungeonDto
        {
            FormatVersion = Constants.FormatVersion,
            Seed = seed,
            Generator = GeneratorName,
            Rooms = rooms.Select(r => new RoomDto
            {
                Width = r.Width,
                Height = r.Height,
                X = r.X,
                Y = r.Y,
                Id = r.Id,
            }).ToList(),
            StartRoom = startRoom,
            EndRoom = endRoom,
            Doors = doors.Select(d => new DoorDto
            {
                From = d.RoomA,
                To = d.RoomB,
                FromWall = d.WallA,
                ToWall = d.WallB,
            }).ToList(),
            // Corridors were cut from the project's scope; always an empty list, like in Rust.
            Corridors = new List<object>(),
            Spawnables = spawnables.Select(ToDto).ToList(),
        };

        return JsonSerializer.Serialize(dungeon, Options);
    }

    // "type" first, then x and y, then only the fields of that kind (like serde's tagged enum).
    private static SpawnableDto ToDto(Spawnable spawnable)
    {
        return spawnable switch
        {
            EnemySpawn e => new SpawnableDto { Type = "enemy", X = e.X, Y = e.Y, Enemy = e.Enemy, Behaviour = e.Behaviour },
            HealthSpawn h => new SpawnableDto { Type = "health", X = h.X, Y = h.Y, Amount = h.Amount },
            AmmoSpawn a => new SpawnableDto { Type = "ammo", X = a.X, Y = a.Y, Amount = a.Amount },
            BuffSpawn b => new SpawnableDto { Type = "buff", X = b.X, Y = b.Y, Buff = b.Buff },
            _ => throw new ArgumentException($"Unknown spawnable {spawnable}"),
        };
    }

    // The classes below only describe the JSON shape. Properties are written in declaration order.
    private class DungeonDto
    {
        [JsonPropertyName("format_version")] public int FormatVersion { get; init; }
        [JsonPropertyName("seed")] public ulong Seed { get; init; }
        [JsonPropertyName("generator")] public string Generator { get; init; } = "";
        [JsonPropertyName("rooms")] public List<RoomDto> Rooms { get; init; } = new();
        [JsonPropertyName("start_room")] public int StartRoom { get; init; }
        [JsonPropertyName("end_room")] public int EndRoom { get; init; }
        [JsonPropertyName("doors")] public List<DoorDto> Doors { get; init; } = new();
        [JsonPropertyName("corridors")] public List<object> Corridors { get; init; } = new();
        [JsonPropertyName("spawnables")] public List<SpawnableDto> Spawnables { get; init; } = new();
    }

    // Fields that don't belong to a kind stay null and are left out of the JSON.
    private class SpawnableDto
    {
        [JsonPropertyName("type")] public string Type { get; init; } = "";
        [JsonPropertyName("x")] public int X { get; init; }
        [JsonPropertyName("y")] public int Y { get; init; }
        [JsonPropertyName("enemy"), JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public string? Enemy { get; init; }
        [JsonPropertyName("behaviour"), JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public string? Behaviour { get; init; }
        [JsonPropertyName("amount"), JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public int? Amount { get; init; }
        [JsonPropertyName("buff"), JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public string? Buff { get; init; }
    }

    private class RoomDto
    {
        [JsonPropertyName("width")] public int Width { get; init; }
        [JsonPropertyName("height")] public int Height { get; init; }
        [JsonPropertyName("x")] public int X { get; init; }
        [JsonPropertyName("y")] public int Y { get; init; }
        [JsonPropertyName("id")] public int Id { get; init; }
    }

    private class DoorDto
    {
        [JsonPropertyName("from")] public int From { get; init; }
        [JsonPropertyName("to")] public int To { get; init; }
        [JsonPropertyName("from_wall")] public Wall FromWall { get; init; }
        [JsonPropertyName("to_wall")] public Wall ToWall { get; init; }
    }
}
