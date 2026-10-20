using procgen_csharp;

// Command-line contract: procgen-csharp --seed <int>
// stdout is reserved for the dungeon JSON, so all logging goes to stderr.
// Exit code 2 = invalid arguments.
if (args.Length != 2 || args[0] != "--seed" || !ulong.TryParse(args[1], out ulong seed))
{
    Console.Error.WriteLine("usage: procgen-csharp --seed <int>");
    return 2;
}

var rng = Pcg32.FromSeed(seed);

List<Room> rooms = RoomGeneration.GenerateRooms(rng);
foreach (Room room in rooms)
{
    Console.Error.WriteLine(room);
}

return 0;
