namespace procgen_csharp.Tests;

// Rust: room_generation.rs tests
public class RoomGenerationTests
{
    // Every generated room fits inside the map.
    [Fact]
    public void RoomsFitInsideMap()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var rng = Pcg32.FromSeed(seed);
            foreach (Room room in RoomGeneration.GenerateRooms(rng))
            {
                Assert.True(room.X >= 0 && room.Y >= 0, $"seed {seed}");
                Assert.True(room.X + room.Width <= Constants.MapWidth, $"seed {seed}");
                Assert.True(room.Y + room.Height <= Constants.MapHeight, $"seed {seed}");
            }
        }
    }

    // No two generated rooms overlap (VR-02).
    [Fact]
    public void RoomsDoNotOverlap()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var rng = Pcg32.FromSeed(seed);
            List<Room> rooms = RoomGeneration.GenerateRooms(rng);
            for (int i = 0; i < rooms.Count; i++)
            {
                for (int j = i + 1; j < rooms.Count; j++)
                {
                    Assert.False(rooms[i].Overlaps(rooms[j]), $"seed {seed}");
                }
            }
        }
    }

    // The id of every room is its index in the list.
    [Fact]
    public void RoomIdIsIndex()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var rng = Pcg32.FromSeed(seed);
            List<Room> rooms = RoomGeneration.GenerateRooms(rng);
            for (int index = 0; index < rooms.Count; index++)
            {
                Assert.True(rooms[index].Id == index, $"seed {seed}");
            }
        }
    }
}
