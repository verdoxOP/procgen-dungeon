namespace procgen_csharp.Tests;

// Rust: room.rs tests
public class RoomTests
{
    private static Room MakeRoom(int x, int y, int width, int height)
    {
        return new Room { X = x, Y = y, Width = width, Height = height, Id = 0 };
    }

    // Two rooms that share a tile overlap.
    [Fact]
    public void OverlappingRoomsOverlap()
    {
        Room a = MakeRoom(0, 0, 10, 10);
        Room b = MakeRoom(5, 5, 10, 10);
        Assert.True(a.Overlaps(b));
        Assert.True(b.Overlaps(a));
    }

    // Rooms that only touch on a side do not overlap.
    [Fact]
    public void TouchingRoomsDoNotOverlap()
    {
        Room a = MakeRoom(0, 0, 10, 10);
        Room right = MakeRoom(10, 0, 10, 10);
        Room below = MakeRoom(0, 10, 10, 10);
        Assert.False(a.Overlaps(right));
        Assert.False(a.Overlaps(below));
        Assert.False(right.Overlaps(a));
        Assert.False(below.Overlaps(a));
    }
}
