using System.Diagnostics;
using procgen_csharp;

// Command-line contract: procgen-csharp --seed <int>
// stdout is reserved for the dungeon JSON, so all logging goes to stderr.
// Exit code 1 = generation failed, 2 = invalid arguments.
if (args.Length != 2 || args[0] != "--seed" || !ulong.TryParse(args[1], out ulong seed))
{
    Console.Error.WriteLine("usage: procgen-csharp --seed <int>");
    return 2;
}

var rng = Pcg32.FromSeed(seed);

// Every step is timed on its own; the logging between the steps is not part of the time.
long roomsStart = Stopwatch.GetTimestamp();

// Rooms: generate, validate, and generate again (with the same rng) until valid or out of attempts.
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
    return 1;
}

Console.Error.WriteLine($"Valid rooms after {roomAttempts} generation attempts");
foreach (Room room in rooms)
{
    Console.Error.WriteLine(room);
}

// Edges: every pair of rooms is a candidate door, with a random weight.
long edgesStart = Stopwatch.GetTimestamp();
List<Edge> edges = EdgeGeneration.GenerateEdges(rng, rooms);
double edgesMs = GenerationStats.ElapsedMs(edgesStart);
Console.Error.WriteLine($"Generated {edges.Count} edges");
foreach (Edge edge in edges)
{
    Console.Error.WriteLine(edge);
}

// Backbone: Prim's spanning tree over the edges. These edges become the doors.
long treeStart = Stopwatch.GetTimestamp();
List<Edge> tree = SpanningTree.BuildTree(edges, rooms.Count);
double treeMs = GenerationStats.ElapsedMs(treeStart);
Console.Error.WriteLine($"Backbone has {tree.Count} edges");
foreach (Edge edge in tree)
{
    Console.Error.WriteLine($"Tree {edge}");
}

// Doors: every backbone edge becomes a door, in a wall that faces the other room.
long doorsStart = Stopwatch.GetTimestamp();
List<Door> doors = DoorGeneration.GenerateDoors(tree, rooms);
double doorsMs = GenerationStats.ElapsedMs(doorsStart);
foreach (Door door in doors)
{
    Console.Error.WriteLine(door);
}

// Start and end room: the start is room 0, the end is the room the most doors away (BFS).
const int startRoom = 0;
long bfsStart = Stopwatch.GetTimestamp();
int[] distances = Bfs.RoomDistances(doors, rooms.Count, startRoom);
int endRoom = Bfs.FurthestRoom(distances);
double bfsMs = GenerationStats.ElapsedMs(bfsStart);
Console.Error.WriteLine($"Start room {startRoom}, end room {endRoom} ({distances[endRoom]} doors away)");

// Population: pick a kind for every room and fill it with enemies and pickups, then validate.
long populationStart = Stopwatch.GetTimestamp();
var (roomKinds, spawnables) = Population.PopulateDungeon(rng, rooms, doors, startRoom, endRoom);
double populationMs = GenerationStats.ElapsedMs(populationStart);
for (int room = 0; room < roomKinds.Count; room++)
{
    Console.Error.WriteLine($"Room {room} is {roomKinds[room]}");
}

long validateStart = Stopwatch.GetTimestamp();
bool populationValid = Population.ValidatePopulation(rooms, doors, spawnables, startRoom);
populationMs += GenerationStats.ElapsedMs(validateStart);

if (!populationValid)
{
    Console.Error.WriteLine("Population is not valid");
    return 1;
}

// The dungeon as JSON on stdout: the only thing the game reads.
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
Console.WriteLine(DungeonJson.Build(seed, rooms, doors, spawnables, startRoom, endRoom, stats));

return 0;
