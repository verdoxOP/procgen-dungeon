namespace procgen_csharp;

// Something placed in a room, at a tile position. The game finds the room from x and y.
// One record per kind, like the variants of the Spawnable enum in population.rs.
public abstract record Spawnable(int X, int Y)
{
    // Enemies are hostile; pickups are not.
    public bool IsHostile => this is EnemySpawn;
}

public sealed record EnemySpawn(int X, int Y, string Enemy, string Behaviour) : Spawnable(X, Y);

public sealed record HealthSpawn(int X, int Y, int Amount) : Spawnable(X, Y);

public sealed record AmmoSpawn(int X, int Y, int Amount) : Spawnable(X, Y);

public sealed record BuffSpawn(int X, int Y, string Buff) : Spawnable(X, Y);
