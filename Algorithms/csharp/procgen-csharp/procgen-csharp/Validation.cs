namespace procgen_csharp;

// Room validation rules, same checks as validation.rs.
public static class Validation 
{
    // VR-03: enough rooms. VR-01/VR-04: every room at least the minimum size. VR-02: no overlap.
    public static bool ValidateRooms(List<Room> rooms)
    {
        if (rooms.Count < Constants.MinRoomCount)
        {
            Console.Error.WriteLine($"Not enough rooms: {rooms.Count}, need at least {Constants.MinRoomCount}");
            return false;
        }

        foreach (Room room in rooms)
        {
            if (room.Width < Constants.MinRoomWidth || room.Height < Constants.MinRoomHeight)
            {
                Console.Error.WriteLine($"Room {room.Id} is too small: {room.Width}x{room.Height}");
                return false;
            }
        }

        for (int i = 0; i < rooms.Count; i++)
        {
            for (int j = i + 1; j < rooms.Count; j++)
            {
                if (rooms[i].Overlaps(rooms[j]))
                {
                    Console.Error.WriteLine($"Rooms {rooms[i].Id} and {rooms[j].Id} overlap");
                    return false;
                }
            }
        }

        return true;
    }
}
