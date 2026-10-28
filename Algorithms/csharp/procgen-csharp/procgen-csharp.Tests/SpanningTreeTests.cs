namespace procgen_csharp.Tests;

// Rust: tree.rs tests
public class SpanningTreeTests
{
    private static List<(int, int, int, int, int)> RoomValues(List<Room> rooms)
    {
        return rooms.Select(r => (r.X, r.Y, r.Width, r.Height, r.Id)).ToList();
    }

    private static List<(int, int, int)> EdgeValues(List<Edge> edges)
    {
        return edges.Select(e => (e.Weight, e.RoomA, e.RoomB)).ToList();
    }

    // The tree has n-1 edges and every room can be reached from room 0.
    [Fact]
    public void TreeHasNMinus1EdgesAndReachesEveryRoom()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var (rooms, _, tree) = TestDungeon.Tree(seed);
            Assert.True(tree.Count == rooms.Count - 1, $"seed {seed}");

            var reached = new bool[rooms.Count];
            reached[0] = true;
            bool changed = true;
            while (changed)
            {
                changed = false;
                foreach (Edge edge in tree)
                {
                    if (reached[edge.RoomA] != reached[edge.RoomB])
                    {
                        reached[edge.RoomA] = true;
                        reached[edge.RoomB] = true;
                        changed = true;
                    }
                }
            }
            Assert.True(reached.All(r => r), $"seed {seed}");
        }
    }

    // The same seed twice gives the same rooms, edges and tree.
    [Fact]
    public void SameSeedSameDungeon()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var (rooms1, edges1, tree1) = TestDungeon.Tree(seed);
            var (rooms2, edges2, tree2) = TestDungeon.Tree(seed);
            Assert.True(RoomValues(rooms1).SequenceEqual(RoomValues(rooms2)), $"seed {seed}");
            Assert.True(EdgeValues(edges1).SequenceEqual(EdgeValues(edges2)), $"seed {seed}");
            Assert.True(EdgeValues(tree1).SequenceEqual(EdgeValues(tree2)), $"seed {seed}");
        }
    }

    // Two different seeds give a different tree.
    [Fact]
    public void DifferentSeedDifferentTree()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var (_, _, tree1) = TestDungeon.Tree(seed);
            var (_, _, tree2) = TestDungeon.Tree(seed + 1);
            Assert.False(EdgeValues(tree1).SequenceEqual(EdgeValues(tree2)), $"seed {seed}");
        }
    }
}
