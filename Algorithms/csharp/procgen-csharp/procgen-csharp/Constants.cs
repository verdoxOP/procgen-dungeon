namespace procgen_csharp;

// Same values as constants.rs in the Rust generator.
public static class Constants
{
    public const int MinRoomCount = 8;
    public const int MaxRoomCount = 20;
    // How many random rooms we try to place before giving up on one generation.
    public const int MaxPlacementAttempts = 1000;
    // How many times the whole room generation is retried when validation fails.
    public const int MaxGenerationAttempts = 10;

    public const int MinRoomWidth = 8;
    public const int MinRoomHeight = 8;
    public const int MaxRoomWidth = 20;
    public const int MaxRoomHeight = 20;

    public const int MapWidth = 100;
    public const int MapHeight = 100;

    public const int FormatVersion = 2;

    // Population: chance (out of 100) that a normal room is an enemy room or an item room;
    // the rest is empty. 60 / 15 / 25 by default.
    public const int EnemyRoomChance = 60;
    public const int ItemRoomChance = 15;
    // One enemy per this many inside tiles, between 1 and MaxEnemiesPerRoom.
    public const int TilesPerEnemy = 40;
    public const int MaxEnemiesPerRoom = 6;
    // Chance (out of 100) that a spawned enemy is aggressive instead of passive.
    public const int AggressiveChance = 70;
}
