using procgen_csharp;

// Command-line contract: procgen-csharp --seed <int>
// Exit code 2 = invalid arguments.
if (args.Length != 2 || args[0] != "--seed" || !ulong.TryParse(args[1], out ulong seed))
{
    Console.Error.WriteLine("usage: procgen-csharp --seed <int>");
    return 2;
}

var rng = Pcg32.FromSeed(seed);

// For now: show that the seed works. The next steps replace this with the generator.
for (int i = 0; i < 5; i++)
{
    Console.Error.WriteLine($"random_range(8..=20): {rng.RandomRange(8, 20)}");
}

return 0;
