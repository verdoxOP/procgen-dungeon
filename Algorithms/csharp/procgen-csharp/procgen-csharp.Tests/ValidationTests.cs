namespace procgen_csharp.Tests;

// Rust: validation.rs tests
public class ValidationTests
{
    // Rooms 25 tiles apart on one row, so they never overlap.
    private static List<Room> RoomsInARow(int count, int width, int height)
    {
        var rooms = new List<Room>();
        for (int i = 0; i < count; i++)
        {
            rooms.Add(new Room { Width = width, Height = height, X = i * 25, Y = 0, Id = i });
        }
        return rooms;
    }

    // Enough rooms of a good size that don't overlap are valid.
    [Fact]
    public void ValidRoomsPass()
    {
        List<Room> rooms = RoomsInARow(Constants.MinRoomCount, Constants.MinRoomWidth, Constants.MinRoomHeight);
        Assert.True(Validation.ValidateRooms(rooms));
    }

    // One room less than the minimum is rejected (VR-03).
    [Fact]
    public void TooFewRoomsFail()
    {
        List<Room> rooms = RoomsInARow(Constants.MinRoomCount - 1, Constants.MinRoomWidth, Constants.MinRoomHeight);
        Assert.False(Validation.ValidateRooms(rooms));
    }

    // A room that is too narrow or too low is rejected (VR-01).
    // Room sizes are init-only in C#, so the room is replaced instead of changed.
    [Fact]
    public void TooSmallRoomsFail()
    {
        List<Room> rooms = RoomsInARow(Constants.MinRoomCount, Constants.MinRoomWidth, Constants.MinRoomHeight);
        rooms[3] = new Room { Width = Constants.MinRoomWidth - 1, Height = rooms[3].Height, X = rooms[3].X, Y = rooms[3].Y, Id = 3 };
        Assert.False(Validation.ValidateRooms(rooms));

        rooms = RoomsInARow(Constants.MinRoomCount, Constants.MinRoomWidth, Constants.MinRoomHeight);
        rooms[3] = new Room { Width = rooms[3].Width, Height = Constants.MinRoomHeight - 1, X = rooms[3].X, Y = rooms[3].Y, Id = 3 };
        Assert.False(Validation.ValidateRooms(rooms));
    }

    // Two overlapping rooms are rejected (VR-02).
    [Fact]
    public void OverlappingRoomsFail()
    {
        List<Room> rooms = RoomsInARow(Constants.MinRoomCount, Constants.MinRoomWidth, Constants.MinRoomHeight);
        rooms[1] = new Room { Width = rooms[1].Width, Height = rooms[1].Height, X = rooms[0].X + 2, Y = rooms[1].Y, Id = 1 };
        Assert.False(Validation.ValidateRooms(rooms));
    }
}
