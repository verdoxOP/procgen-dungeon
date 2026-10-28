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

use std::time::Instant;

use rand::SeedableRng;
use rand_pcg::Pcg32;

use bfs::{furthest_room, room_distances};
use constants::{MAP_HEIGHT, MAP_WIDTH, MAX_GENERATION_ATTEMPTS};
use door::{Door, generate_doors};
use dungeon_json::{Stats, build_dungeon_json};
use edge::{Edge, generate_edges};
use grid::{Grid, print_grid};
use population::{Spawnable, populate_dungeon, validate_population};
use room::Room;
use room_generation::generate_rooms;
use tree::build_tree;
use validation::validate_rooms;

// Command-line contract expected by the Godot game (GeneratorRunner.gd):
//   procgen_dungeon --seed <int>
//   benchmark: procgen_dungeon --seed <int> --runs <n> [--warmup <n>], see run_benchmark
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

//reads an optional number like --runs 1000, if the flag isnt there it is default
fn parse_count_arg(args: &[String], name: &str, default: u64) -> Result<u64, String> {
    let mut i = 1;
    while i < args.len() {
        if args[i] == name {
            let value = args
                .get(i + 1)
                .ok_or_else(|| format!("{} needs a value", name))?;
            return value
                .parse::<u64>()
                .map_err(|_| format!("invalid {} '{}'", name, value));
        }
        i += 1;
    }
    Ok(default)
}

//milliseconds since start, as a float so a fast step doesnt round down to 0
fn elapsed_ms(start: Instant) -> f64 {
    start.elapsed().as_secs_f64() * 1000.0
}

//everything one generated dungeon needs for the json
struct GeneratedDungeon {
    rooms: Vec<Room>,
    doors: Vec<Door>,
    spawnables: Vec<Spawnable>,
    start_room: usize,
    end_room: usize,
    stats: Stats,
}

//the whole pipeline for one seed. every step is timed on its own, the logging between the steps is not part of the time
//log = false skips that logging, the benchmark (--runs) uses that
//returns None when there are no valid rooms or the population is not valid
fn generate_dungeon(game_seed: u64, log: bool) -> Option<GeneratedDungeon> {
    let mut rng = Pcg32::seed_from_u64(game_seed);

    let rooms_start = Instant::now();
    let mut rooms = generate_rooms(&mut rng);
    let mut generation_attempts = 1;

    while !validate_rooms(&rooms) && generation_attempts < MAX_GENERATION_ATTEMPTS {
        generation_attempts += 1;
        rooms = generate_rooms(&mut rng);
    }
    let rooms_ms = elapsed_ms(rooms_start);

    if !validate_rooms(&rooms) {
        eprintln!(
            "no valid rooms after {} generation attempts",
            generation_attempts
        );
        return None;
    }

    let edges_start = Instant::now();
    let edges: Vec<Edge> = generate_edges(&mut rng, &rooms);
    let edges_ms = elapsed_ms(edges_start);
    if log {
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
    }

    let tree_start = Instant::now();
    let tree = build_tree(&edges, &rooms);
    let tree_ms = elapsed_ms(tree_start);

    let doors_start = Instant::now();
    let doors = generate_doors(&tree, &rooms);
    let doors_ms = elapsed_ms(doors_start);

    if log {
        for door in &doors {
            eprintln!("{:?}", door);
        }
    }

    let start_room: usize = 0;
    let bfs_start = Instant::now();
    let distances = room_distances(&doors, rooms.len(), start_room);
    let end_room = furthest_room(&distances);
    let bfs_ms = elapsed_ms(bfs_start);
    if log {
        for room in 0..distances.len() {
            eprintln!("room {} distance {}", room, distances[room]);
        }

        eprintln!("end room {}", end_room);
    }

    let population_start = Instant::now();
    let (room_kinds, spawnables) =
        populate_dungeon(&mut rng, &rooms, &doors, start_room, end_room);
    let mut population_ms = elapsed_ms(population_start);
    if log {
        for room in 0..room_kinds.len() {
            eprintln!("room {} is {:?}", room, room_kinds[room]);
        }
    }

    let validate_start = Instant::now();
    let population_valid = validate_population(&rooms, &doors, &spawnables, start_room);
    population_ms += elapsed_ms(validate_start);

    if !population_valid {
        eprintln!("population is not valid");
        return None;
    }

    let stats = Stats {
        rooms_ms,
        edges_ms,
        tree_ms,
        doors_ms,
        bfs_ms,
        population_ms,
        total_ms: rooms_ms + edges_ms + tree_ms + doors_ms + bfs_ms + population_ms,
        generation_attempts,
    };

    Some(GeneratedDungeon {
        rooms,
        doors,
        spawnables,
        start_room,
        end_room,
        stats,
    })
}

//benchmark: generates the seeds first_seed..first_seed+runs in one process and prints one line with the stats per dungeon.
//warmup generates the same seeds that many times first without printing, so the measured runs dont include
//one-time costs (for c# that is the jit compiling every method the first time it runs)
fn run_benchmark(first_seed: u64, runs: u64, warmup: u64) {
    for _ in 0..warmup {
        for i in 0..runs {
            generate_dungeon(first_seed.wrapping_add(i), false);
        }
    }

    for i in 0..runs {
        let seed = first_seed.wrapping_add(i);
        //written by hand so the stats keep the same key order as in the dungeon json
        match generate_dungeon(seed, false) {
            Some(dungeon) => {
                let stats = serde_json::to_string(&dungeon.stats).expect("Failed to turn stats into json");
                println!("{{\"seed\":{},\"stats\":{}}}", seed, stats);
            }
            None => println!("{{\"seed\":{},\"failed\":true}}", seed),
        }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let parsed = parse_seed_arg(&args).and_then(|seed| {
        let runs = parse_count_arg(&args, "--runs", 0)?;
        let warmup = parse_count_arg(&args, "--warmup", 0)?;
        Ok((seed, runs, warmup))
    });
    let (game_seed, runs, warmup) = match parsed {
        Ok(values) => values,
        Err(message) => {
            eprintln!("{}", message);
            std::process::exit(2);
        }
    };

    if runs > 0 {
        run_benchmark(game_seed, runs, warmup);
        return;
    }

    let dungeon = match generate_dungeon(game_seed, true) {
        Some(dungeon) => dungeon,
        None => std::process::exit(1),
    };

    let json = build_dungeon_json(
        game_seed,
        &dungeon.rooms,
        &dungeon.doors,
        &dungeon.spawnables,
        dungeon.start_room,
        dungeon.end_room,
        &dungeon.stats,
    );
    println!("{}", json);
}
