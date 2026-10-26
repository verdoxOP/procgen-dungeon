use serde::Serialize;
use serde_json::Value;

use crate::constants::FORMAT_VERSION;
use crate::door::Door;
use crate::population::Spawnable;
use crate::room::Room;

//the whole dungeon in one struct so it matches FORMAT.md, godot reads this file
#[derive(Serialize)]
pub struct DungeonJson<'a> {
    pub format_version: i32,
    pub seed: u64,
    pub generator: &'a str,
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
) -> String {
    let dungeon = DungeonJson {
        format_version: FORMAT_VERSION,
        seed,
        generator: "rust",
        rooms,
        start_room,
        end_room,
        doors,
        corridors: Vec::new(),
        spawnables,
    };

    serde_json::to_string_pretty(&dungeon).expect("Failed to turn dungeon into json")
}
