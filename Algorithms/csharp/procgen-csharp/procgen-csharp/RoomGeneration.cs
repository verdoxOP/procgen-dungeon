namespace procgen_csharp;

// Places random rooms on the map, skipping any that overlap a room already placed.
// Same steps and same order of random calls as room_generation.rs, so the same seed gives the same rooms.
public static class RoomGeneration
{
    public static List<Room> GenerateRooms(Pcg32 rng)
    {
        int roomCount = rng.RandomRange(Constants.MinRoomCount, Constants.MaxRoomCount);
        var rooms = new List<Room>();
        int attempts = 0;

        while (rooms.Count < roomCount && attempts < Constants.MaxPlacementAttempts)
        {
            attempts++;

            Room newRoom = GenerateRoom(rng);
            bool overlaps = rooms.Any(existing => newRoom.Overlaps(existing));

            if (!overlaps)
            {
                // The id is the room's index, so other steps can look rooms up directly.
                newRoom.Id = rooms.Count;
                rooms.Add(newRoom);
            }
        }

        Console.Error.WriteLine($"Generated {rooms.Count} rooms in {attempts} attempts");
        return rooms;
    }

    private static Room GenerateRoom(Pcg32 rng)
    {
        int width = rng.RandomRange(Constants.MinRoomWidth, Constants.MaxRoomWidth);
        int height = rng.RandomRange(Constants.MinRoomHeight, Constants.MaxRoomHeight);

        return new Room
        {
            Width = width,
            Height = height,
            X = rng.RandomRange(0, Constants.MapWidth - width),
            Y = rng.RandomRange(0, Constants.MapHeight - height),
        };
    }
}
