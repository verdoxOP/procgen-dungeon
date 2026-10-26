namespace procgen_csharp;

// A candidate connection between two rooms, with a random weight for Prim's algorithm.
// RoomA and RoomB are room ids (= indexes in the rooms list). An edge works both ways.
public class Edge
{
    public int Weight { get; init; }
    public int RoomA { get; init; }
    public int RoomB { get; init; }

    public override string ToString()
    {
        return $"Edge {RoomA}-{RoomB}: weight {Weight}";
    }
}
