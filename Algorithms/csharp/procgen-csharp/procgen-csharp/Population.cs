namespace procgen_csharp;

public enum RoomKind
{
    Start,
    End,
    Enemy,
    Item,
    Empty,
}

// Decides what kind of room every room is and fills it with enemies and pickups.
// Same steps and same order of random calls as population.rs, so the same seed gives the same spawns.
public static class Population
{
    // Enemy and item names the game knows about (see the game's test_data/FORMAT.md).
    private static readonly string[] EnemyKinds = { "skeleton", "skeleton2", "vampire" };
    private const string BossKind = "vampire";
    private const string BuffName = "damage_up";
    private const int HealthAmount = 1;
    private const int AmmoAmount = 10;

    public static (List<RoomKind> Kinds, List<Spawnable> Spawnables) PopulateDungeon(
        Pcg32 rng, List<Room> rooms, List<Door> doors, int startRoom, int endRoom)
    {
        List<RoomKind> kinds = ChooseRoomKinds(rng, rooms.Count, startRoom, endRoom);
        var spawnables = new List<Spawnable>();

        foreach (Room room in rooms)
        {
            List<(int X, int Y)> doorTiles = DoorTilesOfRoom(room.Id, rooms, doors);
            List<(int X, int Y)> tiles = SpawnTiles(room, doorTiles);
            PopulateRoom(rng, room, kinds[room.Id], tiles, spawnables);
        }

        return (kinds, spawnables);
    }

    // Fills one room according to its kind, taking tiles from `tiles`. Same random calls in the same order as Rust.
    private static void PopulateRoom(Pcg32 rng, Room room, RoomKind roomKind, List<(int X, int Y)> tiles, List<Spawnable> spawnables)
    {
        switch (roomKind)
        {
            case RoomKind.Start:
            case RoomKind.Empty:
                break;

            case RoomKind.End:
                // The boss guards the exit.
                if (TakeRandomTile(rng, tiles) is (int bx, int by))
                {
                    spawnables.Add(new EnemySpawn(bx, by, BossKind, "aggressive"));
                }
                break;

            case RoomKind.Enemy:
                for (int i = 0; i < EnemyCount(room); i++)
                {
                    // Order of random calls: tile, then enemy kind, then behaviour.
                    if (TakeRandomTile(rng, tiles) is (int ex, int ey))
                    {
                        string kind = EnemyKinds[rng.RandomRange(0, EnemyKinds.Length - 1)];
                        spawnables.Add(new EnemySpawn(ex, ey, kind, RandomBehaviour(rng)));
                    }
                }
                break;

            case RoomKind.Item:
                if (TakeRandomTile(rng, tiles) is (int ix, int iy))
                {
                    spawnables.Add(rng.RandomRange(0, 2) switch
                    {
                        0 => new HealthSpawn(ix, iy, HealthAmount),
                        1 => new AmmoSpawn(ix, iy, AmmoAmount),
                        _ => new BuffSpawn(ix, iy, BuffName),
                    });
                }
                break;
        }
    }

    // Start and end room are fixed; every other room rolls Enemy / Item / Empty.
    public static List<RoomKind> ChooseRoomKinds(Pcg32 rng, int roomCount, int startRoom, int endRoom)
    {
        var kinds = new List<RoomKind>();
        for (int room = 0; room < roomCount; room++)
        {
            if (room == startRoom)
            {
                kinds.Add(RoomKind.Start);
            }
            else if (room == endRoom)
            {
                kinds.Add(RoomKind.End);
            }
            else
            {
                kinds.Add(RandomRoomKind(rng));
            }
        }

        // A bad seed could roll no item rooms, then a random normal room becomes one.
        if (!kinds.Contains(RoomKind.Item))
        {
            List<int> normalRooms = Enumerable.Range(0, roomCount)
                .Where(room => kinds[room] != RoomKind.Start && kinds[room] != RoomKind.End)
                .ToList();
            if (normalRooms.Count > 0)
            {
                int room = normalRooms[rng.RandomRange(0, normalRooms.Count - 1)];
                kinds[room] = RoomKind.Item;
            }
        }

        return kinds;
    }

    // A tiny room gets 1 enemy, a big room more, but never more than MaxEnemiesPerRoom.
    public static int EnemyCount(Room room)
    {
        int insideArea = (room.Width - 2) * (room.Height - 2);
        return Math.Clamp(insideArea / Constants.TilesPerEnemy, 1, Constants.MaxEnemiesPerRoom);
    }

    // The door tile used for "keep spawns away from doors": the middle of the wall, on the
    // room's own outer ring (same as door_tile in population.rs).
    public static (int X, int Y) DoorTile(Room room, Wall wall)
    {
        return wall switch
        {
            Wall.Top => (room.X + room.Width / 2, room.Y),
            Wall.Bottom => (room.X + room.Width / 2, room.Y + room.Height - 1),
            Wall.Left => (room.X, room.Y + room.Height / 2),
            _ => (room.X + room.Width - 1, room.Y + room.Height / 2),
        };
    }

    public static bool ValidatePopulation(List<Room> rooms, List<Door> doors, List<Spawnable> spawnables, int startRoom)
    {
        // At least one pickup, so a run always has something to collect.
        if (!spawnables.Any(s => !s.IsHostile))
        {
            Console.Error.WriteLine("No item room, the run has nothing to pick up");
            return false;
        }

        foreach (Spawnable spawnable in spawnables)
        {
            Room? room = RoomAt(rooms, spawnable.X, spawnable.Y);
            if (room == null)
            {
                Console.Error.WriteLine($"Spawn at ({spawnable.X}, {spawnable.Y}) is not inside any room");
                return false;
            }

            if (IsNearDoor(DoorTilesOfRoom(room.Id, rooms, doors), spawnable.X, spawnable.Y))
            {
                Console.Error.WriteLine($"Spawn at ({spawnable.X}, {spawnable.Y}) is on or next to a door in room {room.Id}");
                return false;
            }

            if (room.Id == startRoom && spawnable.IsHostile)
            {
                Console.Error.WriteLine($"Start room has something hostile in it at ({spawnable.X}, {spawnable.Y})");
                return false;
            }
        }

        foreach (Room room in rooms)
        {
            int enemies = spawnables.Count(s => s is EnemySpawn && RoomAt(rooms, s.X, s.Y)?.Id == room.Id);
            if (enemies > EnemyCount(room))
            {
                Console.Error.WriteLine($"Room {room.Id} has {enemies} enemies but its size only allows {EnemyCount(room)}");
                return false;
            }
        }

        return true;
    }

    // 60 enemy, 15 item, 25 empty with the default chances.
    private static RoomKind RandomRoomKind(Pcg32 rng)
    {
        int roll = rng.RandomRange(0, 99);
        if (roll < Constants.EnemyRoomChance)
        {
            return RoomKind.Enemy;
        }
        if (roll < Constants.EnemyRoomChance + Constants.ItemRoomChance)
        {
            return RoomKind.Item;
        }
        return RoomKind.Empty;
    }

    private static string RandomBehaviour(Pcg32 rng)
    {
        return rng.RandomRange(0, 99) < Constants.AggressiveChance ? "aggressive" : "passive";
    }

    // Takes a random free tile out of the list, so two spawns never share a tile.
    // Like Rust's swap_remove: the last tile moves into the gap. That keeps the order of the
    // remaining tiles the same as in Rust, which the next random pick depends on.
    private static (int X, int Y)? TakeRandomTile(Pcg32 rng, List<(int X, int Y)> tiles)
    {
        if (tiles.Count == 0)
        {
            return null;
        }

        int index = rng.RandomRange(0, tiles.Count - 1);
        (int X, int Y) tile = tiles[index];
        int last = tiles.Count - 1;
        tiles[index] = tiles[last];
        tiles.RemoveAt(last);
        return tile;
    }

    // The outer ring of a room is treated as wall, so spawns only go on the tiles inside it.
    internal static bool IsInsideRoom(Room room, int x, int y)
    {
        return x > room.X && x < room.X + room.Width - 1 && y > room.Y && y < room.Y + room.Height - 1;
    }

    internal static Room? RoomAt(List<Room> rooms, int x, int y)
    {
        return rooms.FirstOrDefault(room => IsInsideRoom(room, x, y));
    }

    private static List<(int X, int Y)> DoorTilesOfRoom(int roomId, List<Room> rooms, List<Door> doors)
    {
        var tiles = new List<(int X, int Y)>();
        foreach (Door door in doors)
        {
            if (door.RoomA == roomId)
            {
                tiles.Add(DoorTile(rooms[roomId], door.WallA));
            }
            if (door.RoomB == roomId)
            {
                tiles.Add(DoorTile(rooms[roomId], door.WallB));
            }
        }
        return tiles;
    }

    // On the door tile or one of the 8 tiles around it.
    private static bool IsNearDoor(List<(int X, int Y)> doorTiles, int x, int y)
    {
        return doorTiles.Any(d => Math.Abs(x - d.X) <= 1 && Math.Abs(y - d.Y) <= 1);
    }

    // Every tile in a room where something may spawn, row by row (same order as Rust).
    private static List<(int X, int Y)> SpawnTiles(Room room, List<(int X, int Y)> doorTiles)
    {
        var tiles = new List<(int X, int Y)>();
        for (int y = room.Y + 1; y < room.Y + room.Height - 1; y++)
        {
            for (int x = room.X + 1; x < room.X + room.Width - 1; x++)
            {
                if (!IsNearDoor(doorTiles, x, y))
                {
                    tiles.Add((x, y));
                }
            }
        }
        return tiles;
    }
}
