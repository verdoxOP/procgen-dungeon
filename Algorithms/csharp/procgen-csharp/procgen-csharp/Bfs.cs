namespace procgen_csharp;

// Breadth-first search over the doors, used to pick the end room. Same steps as bfs.rs.
public static class Bfs
{
    // Number of doors from the start room to every room. -1 = not reachable.
    public static int[] RoomDistances(List<Door> doors, int roomCount, int startRoom)
    {
        // Neighbours of each room. A door works both ways.
        var neighbours = new List<int>[roomCount];
        for (int i = 0; i < roomCount; i++)
        {
            neighbours[i] = new List<int>();
        }
        foreach (Door door in doors)
        {
            neighbours[door.RoomA].Add(door.RoomB);
            neighbours[door.RoomB].Add(door.RoomA);
        }

        var distances = Enumerable.Repeat(-1, roomCount).ToArray();
        distances[startRoom] = 0;

        var queue = new Queue<int>();
        queue.Enqueue(startRoom);
        while (queue.Count > 0)
        {
            int room = queue.Dequeue();
            foreach (int neighbour in neighbours[room])
            {
                if (distances[neighbour] == -1)
                {
                    distances[neighbour] = distances[room] + 1;
                    queue.Enqueue(neighbour);
                }
            }
        }

        return distances;
    }

    // The room the most doors away from the start. On a tie the lowest id wins, like in Rust.
    public static int FurthestRoom(int[] distances)
    {
        int endRoom = 0;
        for (int room = 0; room < distances.Length; room++)
        {
            if (distances[room] > distances[endRoom])
            {
                endRoom = room;
            }
        }

        return endRoom;
    }
}
