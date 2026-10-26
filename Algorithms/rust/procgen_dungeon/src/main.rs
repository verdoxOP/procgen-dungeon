mod bfs;
mod constants;
mod door;
mod dungeon_json;
mod edge;
mod grid;
mod population;
mod room;
mod room_generation;
mod tree;
mod tree_visualization;
mod validation;

use rand::SeedableRng;
use rand_pcg::Pcg32;

use bfs::{furthest_room, room_distances};
use constants::{MAP_HEIGHT, MAP_WIDTH, MAX_GENERATION_ATTEMPTS};
use door::generate_doors;
use dungeon_json::build_dungeon_json;
use edge::{Edge, generate_edges};
use grid::{Grid, print_grid};
use population::{populate_dungeon, validate_population};
use room_generation::generate_rooms;
use tree::build_tree;
use validation::validate_rooms;

// Command-line contract expected by the Godot game (GeneratorRunner.gd):
//   procgen_dungeon --seed <int>
//   stdout: only the dungeon JSON      stderr: logs
//   exit 0 = ok, 1 = generation failed, 2 = invalid arguments
fn parse_seed_arg(args: &[String]) -> Result<u64, String> {
    let mut i = 1;
    while i < args.len() {
        if args[i] == "--seed" {
            let value = args
                .get(i + 1)
                .ok_or_else(|| "--seed needs a value".to_string())?;
            return value
                .parse::<u64>()
                .map_err(|_| format!("invalid seed '{}'", value));
        }
        i += 1;
    }
    Err("usage: procgen_dungeon --seed <int>".to_string())
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let game_seed = match parse_seed_arg(&args) {
        Ok(seed) => seed,
        Err(message) => {
            eprintln!("{}", message);
            std::process::exit(2);
        }
    };

    let mut rng = Pcg32::seed_from_u64(game_seed);

    let mut rooms = generate_rooms(&mut rng);
    let mut generation_attempts = 1;

    while !validate_rooms(&rooms) && generation_attempts < MAX_GENERATION_ATTEMPTS {
        generation_attempts += 1;
        rooms = generate_rooms(&mut rng);
    }

    if !validate_rooms(&rooms) {
        eprintln!(
            "no valid rooms after {} generation attempts",
            generation_attempts
        );
        std::process::exit(1);
    }

    let edges: Vec<Edge> = generate_edges(&mut rng, &rooms);
    eprintln!("amount of edges {}", edges.len());
    eprintln!(
        "rooms valid after {} generation attempts",
        generation_attempts
    );

    for room in &rooms {
        eprintln!("Room details: {:?}", room);
    }

    let mut grid = Grid::constructor(MAP_WIDTH, MAP_HEIGHT);
    for existing_room in &rooms {
        grid.draw_room(existing_room);
    }
    print_grid(&grid);
    let tree = build_tree(&edges, &rooms);
    let doors = generate_doors(&tree, &rooms);

    for door in &doors {
        eprintln!("{:?}", door);
    }

    let start_room: usize = 0;
    let distances = room_distances(&doors, rooms.len(), start_room);
    for room in 0..distances.len() {
        eprintln!("room {} distance {}", room, distances[room]);
    }

    let end_room = furthest_room(&distances);
    eprintln!("end room {}", end_room);

    let (room_kinds, spawnables) =
        populate_dungeon(&mut rng, &rooms, &doors, start_room, end_room);
    for room in 0..room_kinds.len() {
        eprintln!("room {} is {:?}", room, room_kinds[room]);
    }

    if !validate_population(&rooms, &doors, &spawnables, start_room) {
        eprintln!("population is not valid");
        std::process::exit(1);
    }

    let json = build_dungeon_json(game_seed, &rooms, &doors, &spawnables, start_room, end_room);
    println!("{}", json);
}
