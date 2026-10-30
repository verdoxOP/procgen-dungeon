namespace procgen_csharp;

// Everything one generated dungeon needs for the JSON. Rust: GeneratedDungeon in main.rs.
public record GeneratedDungeon(
    List<Room> Rooms,
    List<Door> Doors,
    List<Spawnable> Spawnables,
    int StartRoom,
    int EndRoom,
    GenerationStats Stats);
