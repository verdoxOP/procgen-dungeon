namespace procgen_csharp.Tests;

// Rust: bfs.rs tests
public class BfsTests
{
    // The walls don't matter for BFS, only which rooms a door connects.
    private static Door MakeDoor(int roomA, int roomB)
    {
        return new Door { RoomA = roomA, RoomB = roomB, WallA = Wall.Right, WallB = Wall.Left };
    }

    // On a line 0-1-2-3 the start is 0 doors away and room 3 is furthest.
    [Fact]
    public void DistancesOnALine()
    {
        var doors = new List<Door> { MakeDoor(0, 1), MakeDoor(1, 2), MakeDoor(2, 3) };
        int[] distances = Bfs.RoomDistances(doors, 4, 0);
        Assert.Equal([0, 1, 2, 3], distances);
        Assert.Equal(3, Bfs.FurthestRoom(distances));
    }

    // Doors work both ways, so a door stored as 1->0 still reaches room 1 from 0.
    [Fact]
    public void DoorsGoBothWays()
    {
        var doors = new List<Door> { MakeDoor(1, 0), MakeDoor(2, 1) };
        int[] distances = Bfs.RoomDistances(doors, 3, 0);
        Assert.Equal([0, 1, 2], distances);
    }

    // On a tie between two furthest rooms the lowest id wins.
    [Fact]
    public void TieLowestIdWins()
    {
        var doors = new List<Door> { MakeDoor(0, 1), MakeDoor(1, 2), MakeDoor(0, 3), MakeDoor(3, 4) };
        int[] distances = Bfs.RoomDistances(doors, 5, 0);
        Assert.Equal([0, 1, 2, 1, 2], distances);
        Assert.Equal(2, Bfs.FurthestRoom(distances));
    }
}
