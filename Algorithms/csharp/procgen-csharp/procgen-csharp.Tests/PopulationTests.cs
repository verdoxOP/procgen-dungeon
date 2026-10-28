namespace procgen_csharp.Tests;

// Rust: population.rs tests
public class PopulationTests
{
    // Nothing hostile spawns in the start room (PV-07).
    [Fact]
    public void NoHostilesInStartRoom()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var (rooms, _, spawnables) = TestDungeon.Populated(seed);
            foreach (Spawnable spawnable in spawnables)
            {
                Room? room = Population.RoomAt(rooms, spawnable.X, spawnable.Y);
                Assert.True(room != null, $"seed {seed}: spawn outside every room");
                Assert.False(room.Id == 0 && spawnable.IsHostile, $"seed {seed}");
            }
        }
    }

    // No room has more than MaxEnemiesPerRoom enemies (PV-03).
    [Fact]
    public void MaxEnemiesPerRoom()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var (rooms, _, spawnables) = TestDungeon.Populated(seed);
            foreach (Room room in rooms)
            {
                int enemies = spawnables.Count(s => s.IsHostile && Population.IsInsideRoom(room, s.X, s.Y));
                Assert.True(enemies <= Constants.MaxEnemiesPerRoom, $"seed {seed} room {room.Id}");
            }
        }
    }

    // No two spawnables stand on the same tile (PV-04).
    [Fact]
    public void NoTwoSpawnablesOnSameTile()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var (_, _, spawnables) = TestDungeon.Populated(seed);
            int distinct = spawnables.Select(s => (s.X, s.Y)).Distinct().Count();
            Assert.True(distinct == spawnables.Count, $"seed {seed}");
        }
    }

    // The generated population passes ValidatePopulation.
    [Fact]
    public void GeneratedPopulationIsValid()
    {
        foreach (ulong seed in TestDungeon.Seeds())
        {
            var (rooms, doors, spawnables) = TestDungeon.Populated(seed);
            Assert.True(Population.ValidatePopulation(rooms, doors, spawnables, 0), $"seed {seed}");
        }
    }
}
