namespace procgen_csharp.Tests;

// Runs the pipeline the same way Program.cs does, for tests that need a whole dungeon.
// Rust repeats this in tree.rs and population.rs; here both test classes share it.
public static class TestDungeon
{
    // The fixed seeds 0..200 that every seed-based test runs over, like the Rust tests.
    public static IEnumerable<ulong> Seeds()
    {
        for (ulong seed = 0; seed < 200; seed++)
        {
            yield return seed;
        }
    }

    public static (Pcg32 Rng, List<Room> Rooms) ValidRooms(ulong seed)
    {
        var rng = Pcg32.FromSeed(seed);
        List<Room> rooms = RoomGeneration.GenerateRooms(rng);
        int generationAttempts = 1;
        while (!Validation.ValidateRooms(rooms) && generationAttempts < Constants.MaxGenerationAttempts)
        {
            generationAttempts++;
            rooms = RoomGeneration.GenerateRooms(rng);
        }

        Assert.True(Validation.ValidateRooms(rooms), $"seed {seed} has no valid rooms");
        return (rng, rooms);
    }

    public static (List<Room> Rooms, List<Edge> Edges, List<Edge> Tree) Tree(ulong seed)
    {
        var (rng, rooms) = ValidRooms(seed);
        List<Edge> edges = EdgeGeneration.GenerateEdges(rng, rooms);
        List<Edge> tree = SpanningTree.BuildTree(edges, rooms.Count);
        return (rooms, edges, tree);
    }

    public static (List<Room> Rooms, List<Door> Doors, List<Spawnable> Spawnables) Populated(ulong seed)
    {
        var (rng, rooms) = ValidRooms(seed);
        List<Edge> edges = EdgeGeneration.GenerateEdges(rng, rooms);
        List<Edge> tree = SpanningTree.BuildTree(edges, rooms.Count);
        List<Door> doors = DoorGeneration.GenerateDoors(tree, rooms);
        int[] distances = Bfs.RoomDistances(doors, rooms.Count, 0);
        int endRoom = Bfs.FurthestRoom(distances);
        var (_, spawnables) = Population.PopulateDungeon(rng, rooms, doors, 0, endRoom);
        return (rooms, doors, spawnables);
    }
}
