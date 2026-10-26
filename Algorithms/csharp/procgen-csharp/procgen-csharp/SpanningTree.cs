namespace procgen_csharp;

// The backbone of the dungeon: a spanning tree over the rooms, built with Prim's algorithm.
// Every room is reachable, there are no cycles, and n rooms give n - 1 edges (the doors).
// Same steps as tree.rs, including the tie-break, so the same edges give the same tree.
public static class SpanningTree
{
    public static List<Edge> BuildTree(List<Edge> edges, int roomCount)
    {
        var visited = new bool[roomCount];
        visited[0] = true;

        var tree = new List<Edge>();
        while (tree.Count < roomCount - 1)
        {
            // The cheapest edge from a visited room to a room that isn't visited yet.
            // On equal weights the first one in the list wins, like in Rust.
            Edge? cheapest = null;
            foreach (Edge edge in edges)
            {
                bool crossesBoundary = visited[edge.RoomA] ^ visited[edge.RoomB];
                if (crossesBoundary && (cheapest == null || edge.Weight < cheapest.Weight))
                {
                    cheapest = edge;
                }
            }

            // Can't happen on a complete graph, but would mean some rooms can't be reached.
            if (cheapest == null)
            {
                throw new InvalidOperationException("No edge left to reach the remaining rooms");
            }

            visited[cheapest.RoomA] = true;
            visited[cheapest.RoomB] = true;
            tree.Add(cheapest);
        }

        return tree;
    }
}
