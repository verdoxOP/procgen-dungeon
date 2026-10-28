use serde::Serialize;
use serde_json::Value;

use crate::constants::FORMAT_VERSION;
use crate::door::Door;
use crate::population::Spawnable;
use crate::room::Room;

//how long every step took in milliseconds and how many tries the rooms needed,
//so the rust and c# generators can be compared. total_ms is the sum of the steps, without the logging in main
#[derive(Serialize)]
pub struct Stats {
    pub rooms_ms: f64,
    pub edges_ms: f64,
    pub tree_ms: f64,
    pub doors_ms: f64,
    pub bfs_ms: f64,
    pub population_ms: f64,
    pub total_ms: f64,
    pub generation_attempts: i32,
}

//the whole dungeon in one struct so it matches FORMAT.md, godot reads this file
#[derive(Serialize)]
pub struct DungeonJson<'a> {
    pub format_version: i32,
    pub seed: u64,
    pub generator: &'a str,
    pub stats: &'a Stats,
    pub rooms: &'a [Room],
    pub start_room: usize,
    pub end_room: usize,
    pub doors: &'a [Door],
    //corridors dont exist yet so they stay an empty list
    pub corridors: Vec<Value>,
    pub spawnables: &'a [Spawnable],
}

//builds the dungeon json, godot's generator contract wants it printed to stdout, not written to a file
pub fn build_dungeon_json(
    seed: u64,
    rooms: &[Room],
    doors: &[Door],
    spawnables: &[Spawnable],
    start_room: usize,
    end_room: usize,
    stats: &Stats,
) -> String {
    let dungeon = DungeonJson {
        format_version: FORMAT_VERSION,
        seed,
        generator: "rust",
        stats,
        rooms,
        start_room,
        end_room,
        doors,
        corridors: Vec::new(),
        spawnables,
    };

    serde_json::to_string_pretty(&dungeon).expect("Failed to turn dungeon into json")
}
