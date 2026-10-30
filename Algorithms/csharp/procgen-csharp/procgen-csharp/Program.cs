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

GeneratedDungeon? dungeon = DungeonGenerator.Generate(seed, log: true);
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

// Benchmark: generates the seeds firstSeed..firstSeed+runs in one process and prints one line with the
// stats per dungeon. Warmup generates the same seeds that many times first without printing, so the
// measured runs don't include one-time costs (for C# that is the JIT compiling every method the first time).
static void RunBenchmark(ulong firstSeed, ulong runs, ulong warmup)
{
    for (ulong pass = 0; pass < warmup; pass++)
    {
        for (ulong i = 0; i < runs; i++)
        {
            DungeonGenerator.Generate(unchecked(firstSeed + i), log: false);
        }
    }

    for (ulong i = 0; i < runs; i++)
    {
        ulong runSeed = unchecked(firstSeed + i);
        GeneratedDungeon? dungeon = DungeonGenerator.Generate(runSeed, log: false);
        Console.WriteLine(dungeon != null
            ? JsonSerializer.Serialize(new { seed = runSeed, stats = dungeon.Stats })
            : JsonSerializer.Serialize(new { seed = runSeed, failed = true }));
    }
}
