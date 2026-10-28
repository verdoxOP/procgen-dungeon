use rand::Rng;
use rand_pcg::Pcg32;
use serde::Serialize;

use crate::constants::{
    AGGRESSIVE_CHANCE, ENEMY_ROOM_CHANCE, ITEM_ROOM_CHANCE, MAX_ENEMIES_PER_ROOM, TILES_PER_ENEMY,
};
use crate::door::{Door, Wall};
use crate::room::Room;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum RoomKind {
    Start,
    End,
    Enemy,
    Item,
    Empty,
}

//enemy/item kinds godot knows about, see GoDot-Project/dungeon-crawler/test_data/FORMAT.md
const ENEMY_KINDS: [&str; 3] = ["skeleton", "skeleton2", "vampire"];
const BOSS_KIND: &str = "vampire";
const BUFF_NAME: &str = "damage_up";
const HEALTH_AMOUNT: i32 = 1;
const AMMO_AMOUNT: i32 = 10;

#[derive(Debug, Serialize)]
pub struct EnemySpawn {
    pub x: i32,
    pub y: i32,
    pub enemy: &'static str,
    pub behaviour: &'static str,
}

#[derive(Debug, Serialize)]
pub struct AmountSpawn {
    pub x: i32,
    pub y: i32,
    pub amount: i32,
}

#[derive(Debug, Serialize)]
pub struct BuffSpawn {
    pub x: i32,
    pub y: i32,
    pub buff: &'static str,
}

//the type tag ends up in the json so godot knows what to spawn, godot finds the
//room itself from x/y so no room id is stored here
#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "lowercase")]
pub enum Spawnable {
    Enemy(EnemySpawn),
    Health(AmountSpawn),
    Ammo(AmountSpawn),
    Buff(BuffSpawn),
}

impl Spawnable {
    pub fn position(&self) -> (i32, i32) {
        match self {
            Spawnable::Enemy(enemy) => (enemy.x, enemy.y),
            Spawnable::Health(spawn) | Spawnable::Ammo(spawn) => (spawn.x, spawn.y),
            Spawnable::Buff(buff) => (buff.x, buff.y),
        }
    }

    pub fn is_hostile(&self) -> bool {
        matches!(self, Spawnable::Enemy(_))
    }
}

//the outer ring of a room is wall, so spawns only go on the tiles inside it
fn is_inside_room(room: &Room, x: i32, y: i32) -> bool {
    x > room.x && x < room.x + room.width - 1 && y > room.y && y < room.y + room.height - 1
}

fn room_at<'a>(rooms: &'a [Room], x: i32, y: i32) -> Option<&'a Room> {
    rooms.iter().find(|room| is_inside_room(room, x, y))
}

//a door sits in the middle of its wall, godot has to place it on the same tile
pub fn door_tile(room: &Room, wall: Wall) -> (i32, i32) {
    match wall {
        Wall::Top => (room.x + room.width / 2, room.y),
        Wall::Bottom => (room.x + room.width / 2, room.y + room.height - 1),
        Wall::Left => (room.x, room.y + room.height / 2),
        Wall::Right => (room.x + room.width - 1, room.y + room.height / 2),
    }
}

fn door_tiles_of_room(room_id: usize, rooms: &[Room], doors: &[Door]) -> Vec<(i32, i32)> {
    let mut tiles: Vec<(i32, i32)> = Vec::new();
    for door in doors {
        if door.room_a == room_id {
            tiles.push(door_tile(&rooms[room_id], door.wall_a));
        }
        if door.room_b == room_id {
            tiles.push(door_tile(&rooms[room_id], door.wall_b));
        }
    }
    tiles
}

//on the door or one of the 8 tiles around it
fn is_near_door(door_tiles: &[(i32, i32)], x: i32, y: i32) -> bool {
    door_tiles
        .iter()
        .any(|&(door_x, door_y)| (x - door_x).abs() <= 1 && (y - door_y).abs() <= 1)
}

//every tile in a room where something is allowed to spawn
fn spawn_tiles(room: &Room, door_tiles: &[(i32, i32)]) -> Vec<(i32, i32)> {
    let mut tiles: Vec<(i32, i32)> = Vec::new();
    for y in (room.y + 1)..(room.y + room.height - 1) {
        for x in (room.x + 1)..(room.x + room.width - 1) {
            if !is_near_door(door_tiles, x, y) {
                tiles.push((x, y));
            }
        }
    }
    tiles
}

//a tiny room gets 1 enemy, a big room gets more but never more than the max
pub fn enemy_count(room: &Room) -> usize {
    let inside_area = (room.width - 2) * (room.height - 2);
    let count = (inside_area / TILES_PER_ENEMY) as usize;
    count.clamp(1, MAX_ENEMIES_PER_ROOM)
}

//60 enemy, 15 item, 25 empty with the default chances
fn random_room_kind(rng: &mut Pcg32) -> RoomKind {
    let roll = rng.random_range(0..100);
    if roll < ENEMY_ROOM_CHANCE {
        RoomKind::Enemy
    } else if roll < ENEMY_ROOM_CHANCE + ITEM_ROOM_CHANCE {
        RoomKind::Item
    } else {
        RoomKind::Empty
    }
}

pub fn choose_room_kinds(
    rng: &mut Pcg32,
    room_count: usize,
    start_room: usize,
    end_room: usize,
) -> Vec<RoomKind> {
    let mut kinds: Vec<RoomKind> = Vec::new();
    for room in 0..room_count {
        if room == start_room {
            kinds.push(RoomKind::Start);
        } else if room == end_room {
            kinds.push(RoomKind::End);
        } else {
            kinds.push(random_room_kind(rng));
        }
    }

    //a bad seed could roll no item rooms, then a random normal room becomes one
    if !kinds.contains(&RoomKind::Item) {
        let normal_rooms: Vec<usize> = (0..room_count)
            .filter(|&room| kinds[room] != RoomKind::Start && kinds[room] != RoomKind::End)
            .collect();
        if !normal_rooms.is_empty() {
            let room = normal_rooms[rng.random_range(0..normal_rooms.len())];
            kinds[room] = RoomKind::Item;
        }
    }

    kinds
}

//takes a random free tile out of the list so two spawns never share a tile
fn take_random_tile(rng: &mut Pcg32, tiles: &mut Vec<(i32, i32)>) -> Option<(i32, i32)> {
    if tiles.is_empty() {
        return None;
    }
    let index = rng.random_range(0..tiles.len());
    Some(tiles.swap_remove(index))
}

fn random_behaviour(rng: &mut Pcg32) -> &'static str {
    if rng.random_range(0..100) < AGGRESSIVE_CHANCE {
        "aggressive"
    } else {
        "passive"
    }
}

pub fn populate_dungeon(
    rng: &mut Pcg32,
    rooms: &[Room],
    doors: &[Door],
    start_room: usize,
    end_room: usize,
) -> (Vec<RoomKind>, Vec<Spawnable>) {
    let kinds = choose_room_kinds(rng, rooms.len(), start_room, end_room);
    let mut spawnables: Vec<Spawnable> = Vec::new();

    for room in rooms {
        let door_tiles = door_tiles_of_room(room.id, rooms, doors);
        let mut tiles = spawn_tiles(room, &door_tiles);

        match kinds[room.id] {
            RoomKind::Start | RoomKind::Empty => {}
            RoomKind::End => {
                if let Some((x, y)) = take_random_tile(rng, &mut tiles) {
                    spawnables.push(Spawnable::Enemy(EnemySpawn {
                        x,
                        y,
                        enemy: BOSS_KIND,
                        behaviour: "aggressive",
                    }));
                }
            }
            RoomKind::Enemy => {
                for _ in 0..enemy_count(room) {
                    if let Some((x, y)) = take_random_tile(rng, &mut tiles) {
                        let kind = ENEMY_KINDS[rng.random_range(0..ENEMY_KINDS.len())];
                        spawnables.push(Spawnable::Enemy(EnemySpawn {
                            x,
                            y,
                            enemy: kind,
                            behaviour: random_behaviour(rng),
                        }));
                    }
                }
            }
            RoomKind::Item => {
                if let Some((x, y)) = take_random_tile(rng, &mut tiles) {
                    spawnables.push(match rng.random_range(0..3) {
                        0 => Spawnable::Health(AmountSpawn { x, y, amount: HEALTH_AMOUNT }),
                        1 => Spawnable::Ammo(AmountSpawn { x, y, amount: AMMO_AMOUNT }),
                        _ => Spawnable::Buff(BuffSpawn { x, y, buff: BUFF_NAME }),
                    });
                }
            }
        }
    }

    (kinds, spawnables)
}

pub fn validate_population(
    rooms: &[Room],
    doors: &[Door],
    spawnables: &[Spawnable],
    start_room: usize,
) -> bool {
    if !spawnables.iter().any(|spawnable| !spawnable.is_hostile()) {
        eprintln!("no item room, the run has nothing to pick up");
        return false;
    }

    for spawnable in spawnables {
        let (x, y) = spawnable.position();
        let room = match room_at(rooms, x, y) {
            Some(room) => room,
            None => {
                eprintln!("spawn at ({}, {}) is not inside any room", x, y);
                return false;
            }
        };

        let door_tiles = door_tiles_of_room(room.id, rooms, doors);
        if is_near_door(&door_tiles, x, y) {
            eprintln!(
                "spawn at ({}, {}) is on or next to a door in room {}",
                x, y, room.id
            );
            return false;
        }

        if room.id == start_room && spawnable.is_hostile() {
            eprintln!("start room has something hostile in it at ({}, {})", x, y);
            return false;
        }
    }

    for room in rooms {
        let enemies = spawnables
            .iter()
            .filter(|spawnable| {
                matches!(spawnable, Spawnable::Enemy(_))
                    && room_at(rooms, spawnable.position().0, spawnable.position().1)
                        .map(|r| r.id)
                        == Some(room.id)
            })
            .count();
        if enemies > enemy_count(room) {
            eprintln!(
                "room {} has {} enemies but its size only allows {}",
                room.id,
                enemies,
                enemy_count(room)
            );
            return false;
        }
    }

    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bfs::{furthest_room, room_distances};
    use crate::constants::MAX_GENERATION_ATTEMPTS;
    use crate::door::generate_doors;
    use crate::edge::generate_edges;
    use crate::room_generation::generate_rooms;
    use crate::tree::build_tree;
    use crate::validation::validate_rooms;
    use rand::SeedableRng;

    fn generate(seed: u64) -> (Vec<Room>, Vec<Door>, Vec<Spawnable>) {
        let mut rng = Pcg32::seed_from_u64(seed);
        let mut rooms = generate_rooms(&mut rng);
        let mut generation_attempts = 1;
        while !validate_rooms(&rooms) && generation_attempts < MAX_GENERATION_ATTEMPTS {
            generation_attempts += 1;
            rooms = generate_rooms(&mut rng);
        }
        assert!(validate_rooms(&rooms), "seed {} has no valid rooms", seed);
        let edges = generate_edges(&mut rng, &rooms);
        let tree = build_tree(&edges, &rooms);
        let doors = generate_doors(&tree, &rooms);
        let distances = room_distances(&doors, rooms.len(), 0);
        let end_room = furthest_room(&distances);
        let (_, spawnables) = populate_dungeon(&mut rng, &rooms, &doors, 0, end_room);
        (rooms, doors, spawnables)
    }

    #[test]
    //nothing hostile spawns in the start room (PV-07)
    fn no_hostiles_in_start_room() {
        for seed in 0..200 {
            let (rooms, _, spawnables) = generate(seed);
            for spawnable in &spawnables {
                let (x, y) = spawnable.position();
                let room = room_at(&rooms, x, y).expect("spawn outside every room");
                assert!(!(room.id == 0 && spawnable.is_hostile()), "seed {}", seed);
            }
        }
    }

    #[test]
    //no room has more than MAX_ENEMIES_PER_ROOM enemies (PV-03)
    fn max_enemies_per_room() {
        for seed in 0..200 {
            let (rooms, _, spawnables) = generate(seed);
            for room in &rooms {
                let enemies = spawnables
                    .iter()
                    .filter(|s| s.is_hostile() && is_inside_room(room, s.position().0, s.position().1))
                    .count();
                assert!(enemies <= MAX_ENEMIES_PER_ROOM, "seed {} room {}", seed, room.id);
            }
        }
    }

    #[test]
    //no two spawnables stand on the same tile (PV-04)
    fn no_two_spawnables_on_same_tile() {
        for seed in 0..200 {
            let (_, _, spawnables) = generate(seed);
            let mut positions: Vec<(i32, i32)> = spawnables.iter().map(|s| s.position()).collect();
            let count = positions.len();
            positions.sort();
            positions.dedup();
            assert_eq!(positions.len(), count, "seed {}", seed);
        }
    }

    #[test]
    //the generated population passes validate_population
    fn generated_population_is_valid() {
        for seed in 0..200 {
            let (rooms, doors, spawnables) = generate(seed);
            assert!(validate_population(&rooms, &doors, &spawnables, 0), "seed {}", seed);
        }
    }
}
