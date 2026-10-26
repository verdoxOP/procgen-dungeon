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
List<Edge> edges = EdgeGeneration.GenerateEdges(rng, rooms);
Console.Error.WriteLine($"Generated {edges.Count} edges");
foreach (Edge edge in edges)
{
    Console.Error.WriteLine(edge);
}

// Backbone: Prim's spanning tree over the edges. These edges become the doors.
List<Edge> tree = SpanningTree.BuildTree(edges, rooms.Count);
Console.Error.WriteLine($"Backbone has {tree.Count} edges");
foreach (Edge edge in tree)
{
    Console.Error.WriteLine($"Tree {edge}");
}

// Doors: every backbone edge becomes a door, in a wall that faces the other room.
List<Door> doors = DoorGeneration.GenerateDoors(tree, rooms);
foreach (Door door in doors)
{
    Console.Error.WriteLine(door);
}

// Start and end room: the start is room 0, the end is the room the most doors away (BFS).
const int startRoom = 0;
int[] distances = Bfs.RoomDistances(doors, rooms.Count, startRoom);
int endRoom = Bfs.FurthestRoom(distances);
Console.Error.WriteLine($"Start room {startRoom}, end room {endRoom} ({distances[endRoom]} doors away)");

// Population: pick a kind for every room and fill it with enemies and pickups, then validate.
var (roomKinds, spawnables) = Population.PopulateDungeon(rng, rooms, doors, startRoom, endRoom);
for (int room = 0; room < roomKinds.Count; room++)
{
    Console.Error.WriteLine($"Room {room} is {roomKinds[room]}");
}

if (!Population.ValidatePopulation(rooms, doors, spawnables, startRoom))
{
    Console.Error.WriteLine("Population is not valid");
    return 1;
}

// The dungeon as JSON on stdout: the only thing the game reads.
Console.WriteLine(DungeonJson.Build(seed, rooms, doors, spawnables, startRoom, endRoom));

return 0;
