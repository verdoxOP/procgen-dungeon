using System.Diagnostics;
using System.Text.Json.Serialization;

namespace procgen_csharp;

// How long every step took in milliseconds and how many tries the rooms needed, so the Rust and C#
// generators can be compared. Written to the JSON as "stats", same keys and order as Stats in dungeon_json.rs.
// TotalMs is the sum of the steps, without the logging Program does between them.
public class GenerationStats
{
    [JsonPropertyName("rooms_ms")] public double RoomsMs { get; init; }
    [JsonPropertyName("edges_ms")] public double EdgesMs { get; init; }
    [JsonPropertyName("tree_ms")] public double TreeMs { get; init; }
    [JsonPropertyName("doors_ms")] public double DoorsMs { get; init; }
    [JsonPropertyName("bfs_ms")] public double BfsMs { get; init; }
    [JsonPropertyName("population_ms")] public double PopulationMs { get; init; }
    [JsonPropertyName("total_ms")] public double TotalMs => RoomsMs + EdgesMs + TreeMs + DoorsMs + BfsMs + PopulationMs;
    [JsonPropertyName("generation_attempts")] public int GenerationAttempts { get; init; }

    // Milliseconds since a Stopwatch.GetTimestamp(), as a double so a fast step doesn't round down to 0.
    public static double ElapsedMs(long start)
    {
        return Stopwatch.GetElapsedTime(start).TotalMilliseconds;
    }
}
