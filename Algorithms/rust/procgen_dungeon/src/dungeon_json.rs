use serde::Serialize;
use serde_json::Value;

use crate::constants::FORMAT_VERSION;
use crate::door::Door;
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
    //corridors and spawnables dont exist yet so they stay empty lists
    pub corridors: Vec<Value>,
    pub spawnables: Vec<Value>,
}

//write the dungeon to a json file for godot
pub fn write_dungeon_json(
    seed: u64,
    rooms: &[Room],
    doors: &[Door],
    start_room: usize,
    end_room: usize,
) {
    let dungeon = DungeonJson {
        format_version: FORMAT_VERSION,
        seed,
        generator: "rust",
        rooms,
        start_room,
        end_room,
        doors,
        corridors: Vec::new(),
        spawnables: Vec::new(),
    };

    let json = serde_json::to_string_pretty(&dungeon).expect("Failed to turn dungeon into json");
    std::fs::write("dungeon.json", &json).expect("Failed to write dungeon.json");
    println!("Dungeon written to dungeon.json");
}
