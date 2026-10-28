namespace procgen_csharp.Tests;

// Rust: door.rs tests
public class DoorGenerationTests
{
    private static Room MakeRoom(int x, int y, int id)
    {
        return new Room { Width = 10, Height = 10, X = x, Y = y, Id = id };
    }

    // Room 0 sits at (50, 50); room 1 at the given position.
    private static Door DoorFrom0To1(int otherX, int otherY)
    {
        var rooms = new List<Room> { MakeRoom(50, 50, 0), MakeRoom(otherX, otherY, 1) };
        var edge = new Edge { Weight = 1, RoomA = 0, RoomB = 1 };
        return DoorGeneration.EdgeToDoor(edge, rooms);
    }

    // Room b to the right gets a right door in a and a left door in b.
    [Fact]
    public void DoorRight()
    {
        Door door = DoorFrom0To1(70, 50);
        Assert.Equal(Wall.Right, door.WallA);
        Assert.Equal(Wall.Left, door.WallB);
    }

    // Room b to the left gets a left door in a and a right door in b.
    [Fact]
    public void DoorLeft()
    {
        Door door = DoorFrom0To1(30, 50);
        Assert.Equal(Wall.Left, door.WallA);
        Assert.Equal(Wall.Right, door.WallB);
    }

    // Room b below gets a bottom door in a and a top door in b.
    [Fact]
    public void DoorBottom()
    {
        Door door = DoorFrom0To1(50, 70);
        Assert.Equal(Wall.Bottom, door.WallA);
        Assert.Equal(Wall.Top, door.WallB);
    }

    // Room b above gets a top door in a and a bottom door in b.
    [Fact]
    public void DoorTop()
    {
        Door door = DoorFrom0To1(50, 30);
        Assert.Equal(Wall.Top, door.WallA);
        Assert.Equal(Wall.Bottom, door.WallB);
    }

    // On a diagonal tie |dx| == |dy| the door goes on the left or right wall.
    [Fact]
    public void DiagonalTieGoesLeftOrRight()
    {
        Assert.Equal(Wall.Right, DoorFrom0To1(70, 70).WallA);
        Assert.Equal(Wall.Left, DoorFrom0To1(30, 30).WallA);
        Assert.Equal(Wall.Right, DoorFrom0To1(70, 30).WallA);
        Assert.Equal(Wall.Left, DoorFrom0To1(30, 70).WallA);
    }

    // WallB is always the opposite of WallA.
    [Fact]
    public void WallBIsOppositeOfWallA()
    {
        (int, int)[] positions = [(70, 50), (30, 50), (50, 70), (50, 30), (70, 70), (30, 30), (65, 80), (20, 55)];
        foreach (var (x, y) in positions)
        {
            Door door = DoorFrom0To1(x, y);
            Assert.Equal(DoorGeneration.OppositeWall(door.WallA), door.WallB);
        }
    }
}
