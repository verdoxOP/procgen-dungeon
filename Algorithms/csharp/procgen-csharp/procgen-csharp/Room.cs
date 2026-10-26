namespace procgen_csharp;

// A room in tiles: x, y is the top-left floor tile, width and height are floor only.
public class Room
{
    public int Id { get; set; }
    public int X { get; init; }
    public int Y { get; init; }
    public int Width { get; init; }
    public int Height { get; init; }

    // True when the two rooms share at least one tile. Rooms that only touch don't overlap.
    public bool Overlaps(Room other)
    {
        int right = X + Width;
        int bottom = Y + Height;
        int otherRight = other.X + other.Width;
        int otherBottom = other.Y + other.Height;

        return !(X >= otherRight
                 || right <= other.X
                 || Y >= otherBottom
                 || bottom <= other.Y);
    }

    public override string ToString()
    {
        return $"Room {Id}: x {X}, y {Y}, {Width}x{Height}";
    }
}
