using System.Diagnostics;

namespace procgen_csharp;

// The generation pipeline, used by Program for one dungeon and by the benchmark mode for many.
// Rust: generate_dungeon in main.rs.
public static class DungeonGenerator
{
    // The whole pipeline for one seed. Every step is timed on its own; the logging between the steps is not
    // part of the time. log = false skips that logging (used by the benchmark).
    // Returns null when there are no valid rooms or the population is not valid.
    public static GeneratedDungeon? Generate(ulong seed, bool log)
    {
        var rng = Pcg32.FromSeed(seed);

        // Rooms: generate, validate, and generate again (with the same rng) until valid or out of attempts.
        long roomsStart = Stopwatch.GetTimestamp();
        List<Room> rooms = RoomGeneration.GenerateRooms(rng);
        int roomAttempts = 1;
        bool roomsValid = Validation.ValidateRooms(rooms);
        while (!roomsValid && roomAttempts < Constants.MaxGenerationAttempts)
        {
            roomAttempts++;
            rooms = RoomGeneration.GenerateRooms(rng);
            roomsValid = Validation.ValidateRooms(rooms);
        }
        double roomsMs = GenerationStats.ElapsedMs(roomsStart);

        if (!roomsValid)
        {
            Console.Error.WriteLine($"No valid rooms after {roomAttempts} generation attempts");
            return null;
        }

        if (log)
        {
            LogLines($"Valid rooms after {roomAttempts} generation attempts", rooms);
        }

        // Edges: every pair of rooms is a candidate door, with a random weight.
        long edgesStart = Stopwatch.GetTimestamp();
        List<Edge> edges = EdgeGeneration.GenerateEdges(rng, rooms);
        double edgesMs = GenerationStats.ElapsedMs(edgesStart);
        if (log)
        {
            LogLines($"Generated {edges.Count} edges", edges);
        }

        // Backbone: Prim's spanning tree over the edges. These edges become the doors.
        long treeStart = Stopwatch.GetTimestamp();
        List<Edge> tree = SpanningTree.BuildTree(edges, rooms.Count);
        double treeMs = GenerationStats.ElapsedMs(treeStart);
        if (log)
        {
            LogLines($"Backbone has {tree.Count} edges", tree.Select(edge => $"Tree {edge}"));
        }

        // Doors: every backbone edge becomes a door, in a wall that faces the other room.
        long doorsStart = Stopwatch.GetTimestamp();
        List<Door> doors = DoorGeneration.GenerateDoors(tree, rooms);
        double doorsMs = GenerationStats.ElapsedMs(doorsStart);
        if (log)
        {
            LogLines(null, doors);
        }

        // Start and end room: the start is room 0, the end is the room the most doors away (BFS).
        const int startRoom = 0;
        long bfsStart = Stopwatch.GetTimestamp();
        int[] distances = Bfs.RoomDistances(doors, rooms.Count, startRoom);
        int endRoom = Bfs.FurthestRoom(distances);
        double bfsMs = GenerationStats.ElapsedMs(bfsStart);
        if (log)
        {
            Console.Error.WriteLine($"Start room {startRoom}, end room {endRoom} ({distances[endRoom]} doors away)");
        }

        // Population: pick a kind for every room and fill it with enemies and pickups, then validate.
        long populationStart = Stopwatch.GetTimestamp();
        var (roomKinds, spawnables) = Population.PopulateDungeon(rng, rooms, doors, startRoom, endRoom);
        double populationMs = GenerationStats.ElapsedMs(populationStart);
        if (log)
        {
            LogLines(null, roomKinds.Select((kind, room) => $"Room {room} is {kind}"));
        }

        long validateStart = Stopwatch.GetTimestamp();
        bool populationValid = Population.ValidatePopulation(rooms, doors, spawnables, startRoom);
        populationMs += GenerationStats.ElapsedMs(validateStart);

        if (!populationValid)
        {
            Console.Error.WriteLine("Population is not valid");
            return null;
        }

        var stats = new GenerationStats
        {
            RoomsMs = roomsMs,
            EdgesMs = edgesMs,
            TreeMs = treeMs,
            DoorsMs = doorsMs,
            BfsMs = bfsMs,
            PopulationMs = populationMs,
            GenerationAttempts = roomAttempts,
        };
        return new GeneratedDungeon(rooms, doors, spawnables, startRoom, endRoom, stats);
    }

    // The logging between the steps: an optional header line, then one line per item, to stderr.
    // Kept out of Generate, so that method only shows the steps and their timing.
    private static void LogLines<T>(string? header, IEnumerable<T> items)
    {
        if (header != null)
        {
            Console.Error.WriteLine(header);
        }

        foreach (T item in items)
        {
            Console.Error.WriteLine(item);
        }
    }
}
