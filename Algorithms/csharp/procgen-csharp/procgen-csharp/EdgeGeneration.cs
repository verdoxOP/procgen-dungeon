namespace procgen_csharp;

// Connects every pair of rooms (a complete graph): n rooms give n * (n - 1) / 2 edges.
// Same order of pairs and random calls as edge.rs, so the same seed gives the same weights.
public static class EdgeGeneration
{
    public const int MinWeight = 1;
    public const int MaxWeight = 100;

    public static List<Edge> GenerateEdges(Pcg32 rng, List<Room> rooms)
    {
        var edges = new List<Edge>();
        for (int i = 0; i < rooms.Count; i++)
        {
            for (int j = i + 1; j < rooms.Count; j++)
            {
                edges.Add(new Edge
                {
                    Weight = rng.RandomRange(MinWeight, MaxWeight),
                    RoomA = i,
                    RoomB = j,
                });
            }
        }

        return edges;
    }
}
