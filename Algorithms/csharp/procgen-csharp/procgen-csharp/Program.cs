using System.Diagnostics;
using System.Text.Json;
using procgen_csharp;

// Command-line contract: procgen-csharp --seed <int>
// Benchmark: procgen-csharp --seed <int> --runs <n> [--warmup <n>], see RunBenchmark below.
// stdout is reserved for the dungeon JSON, so all logging goes to stderr.
// Exit code 1 = generation failed, 2 = invalid arguments.
if (!TryParseArgs(args, out ulong seed, out ulong runs, out ulong warmup))
{
    Console.Error.WriteLine("usage: procgen-csharp --seed <int> [--runs <n> [--warmup <n>]]");
    return 2;
}

if (runs > 0)
{
    RunBenchmark(seed, runs, warmup);
    return 0;
}

GeneratedDungeon? dungeon = GenerateDungeon(seed, log: true);
if (dungeon == null)
{
    return 1;
}

// The dungeon as JSON on stdout: the only thing the game reads.
Console.WriteLine(DungeonJson.Build(seed, dungeon.Rooms, dungeon.Doors, dungeon.Spawnables, dungeon.StartRoom, dungeon.EndRoom, dungeon.Stats));
return 0;

// Arguments come in pairs: --seed is required, --runs and --warmup are optional (default 0).
static bool TryParseArgs(string[] args, out ulong seed, out ulong runs, out ulong warmup)
{
    seed = 0;
    runs = 0;
    warmup = 0;
    bool hasSeed = false;
    if (args.Length % 2 != 0)
    {
        return false;
    }

    for (int i = 0; i < args.Length; i += 2)
    {
        if (!ulong.TryParse(args[i + 1], out ulong value))
        {
            return false;
        }

        switch (args[i])
        {
            case "--seed":
                seed = value;
                hasSeed = true;
                break;
            case "--runs":
                runs = value;
                break;
            case "--warmup":
                warmup = value;
                break;
            default:
                return false;
        }
    }

    return hasSeed;
}

// The whole pipeline for one seed. Every step is timed on its own; the logging between the steps is not
// part of the time. log = false skips that logging (used by the benchmark).
// Returns null when there are no valid rooms or the population is not valid.
static GeneratedDungeon? GenerateDungeon(ulong seed, bool log)
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
// Kept out of GenerateDungeon, so that function only shows the steps and their timing.
static void LogLines<T>(string? header, IEnumerable<T> items)
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

// Benchmark: generates the seeds firstSeed..firstSeed+runs in one process and prints one line with the
// stats per dungeon. Warmup generates the same seeds that many times first without printing, so the
// measured runs don't include one-time costs (for C# that is the JIT compiling every method the first time).
static void RunBenchmark(ulong firstSeed, ulong runs, ulong warmup)
{
    for (ulong pass = 0; pass < warmup; pass++)
    {
        for (ulong i = 0; i < runs; i++)
        {
            GenerateDungeon(unchecked(firstSeed + i), log: false);
        }
    }

    for (ulong i = 0; i < runs; i++)
    {
        ulong runSeed = unchecked(firstSeed + i);
        GeneratedDungeon? dungeon = GenerateDungeon(runSeed, log: false);
        Console.WriteLine(dungeon != null
            ? JsonSerializer.Serialize(new { seed = runSeed, stats = dungeon.Stats })
            : JsonSerializer.Serialize(new { seed = runSeed, failed = true }));
    }
}
