namespace procgen_csharp;

// Which wall of a room a door is in. Written to the JSON in lowercase ("top", "right", ...).
public enum Wall
{
    Top,
    Bottom,
    Left,
    Right,
}

// A door between two rooms: one edge of the backbone, with the wall it sits in on each side.
// Room A's door is in WallA, room B's door in WallB (always the opposite wall).
public class Door
{
    public int RoomA { get; init; }
    public int RoomB { get; init; }
    public Wall WallA { get; init; }
    public Wall WallB { get; init; }

    public override string ToString()
    {
        return $"Door {RoomA}-{RoomB}: {WallA.ToString().ToLowerInvariant()}/{WallB.ToString().ToLowerInvariant()}";
    }
}
