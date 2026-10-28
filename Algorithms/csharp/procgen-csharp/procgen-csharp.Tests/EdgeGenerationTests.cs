namespace procgen_csharp.Tests;

// Rust: edge.rs tests
public class EdgeGenerationTests
{
    // n rooms give n*(n-1)/2 edges, no self-loops and no duplicate pairs.
    [Fact]
    public void EdgesFormCompleteGraph()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var rng = Pcg32.FromSeed(seed);
            List<Room> rooms = RoomGeneration.GenerateRooms(rng);
            List<Edge> edges = EdgeGeneration.GenerateEdges(rng, rooms);
            int n = rooms.Count;
            Assert.True(edges.Count == n * (n - 1) / 2, $"seed {seed}");

            var pairs = new List<(int, int)>();
            foreach (Edge edge in edges)
            {
                Assert.True(edge.RoomA != edge.RoomB, $"seed {seed}");
                var pair = (Math.Min(edge.RoomA, edge.RoomB), Math.Max(edge.RoomA, edge.RoomB));
                Assert.False(pairs.Contains(pair), $"seed {seed}");
                pairs.Add(pair);
            }
        }
    }
}
