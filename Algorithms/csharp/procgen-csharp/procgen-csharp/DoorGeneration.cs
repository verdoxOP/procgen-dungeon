namespace procgen_csharp;

// Turns every backbone edge into a door and decides which wall it is in, same rules as door.rs.
public static class DoorGeneration
{
    public static List<Door> GenerateDoors(List<Edge> tree, List<Room> rooms)
    {
        return tree.Select(edge => EdgeToDoor(edge, rooms)).ToList();
    }

    // The bigger difference between the two room centres picks the axis: if room B is mostly
    // to the right of room A, the door is in A's right wall and B's left wall.
    // On a tie the door goes in a left or right wall, like in Rust.
    public static Door EdgeToDoor(Edge edge, List<Room> rooms)
    {
        // Ids equal list indexes, so the rooms can be looked up directly.
        Room roomA = rooms[edge.RoomA];
        Room roomB = rooms[edge.RoomB];

        // Integer division, same as Rust's i32 division (all values are positive here).
        int centerAX = roomA.X + roomA.Width / 2;
        int centerAY = roomA.Y + roomA.Height / 2;
        int centerBX = roomB.X + roomB.Width / 2;
        int centerBY = roomB.Y + roomB.Height / 2;

        int dx = centerBX - centerAX;
        int dy = centerBY - centerAY;

        Wall wallA;
        if (Math.Abs(dx) >= Math.Abs(dy))
        {
            wallA = dx > 0 ? Wall.Right : Wall.Left;
        }
        else
        {
            // y grows downwards, so a positive dy means room B is below room A.
            wallA = dy > 0 ? Wall.Bottom : Wall.Top;
        }

        return new Door
        {
            RoomA = edge.RoomA,
            RoomB = edge.RoomB,
            WallA = wallA,
            WallB = OppositeWall(wallA),
        };
    }

    public static Wall OppositeWall(Wall wall)
    {
        return wall switch
        {
            Wall.Top => Wall.Bottom,
            Wall.Bottom => Wall.Top,
            Wall.Left => Wall.Right,
            _ => Wall.Left,
        };
    }
}
