mod constants;
mod door;
mod edge;
mod grid;
mod room;
mod room_generation;
mod tree;
mod tree_visualization;
mod validation;

use rand::SeedableRng;
use rand_pcg::Pcg32;
use std::io;

use constants::{MAP_HEIGHT, MAP_WIDTH, MAX_GENERATION_ATTEMPTS};
use door::generate_doors;
use edge::{Edge, generate_edges};
use grid::{Grid, print_grid};
use room_generation::generate_rooms;
use tree::build_tree;
use tree_visualization::visualize_tree_in_graph_form;
use validation::validate_rooms;

fn main() {
    let mut input = String::new();
    println!("Enter a seed for the game:");
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    let game_seed: u64 = input.trim().parse().expect("Please enter a valid number");
    let mut rng = Pcg32::seed_from_u64(game_seed);

    /*
    let test_room1 = Room{
        id: 1,
        width: 22,
        height: 22,
        x: 12,
        y: 12

    };
     let test_room2 = Room{
        id: 1,
        width: 22,
        height: 22,
        x: 12,
        y: 12

    };

    let test_rooms = vec![test_room1, test_room2];
    println!("validation result {}",validate_rooms(&test_rooms));
    for testing validation, dont forget to chnage const of min rooms to 2 because otheriwse it will aready fail based in too little rooms
    */

    let mut rooms = generate_rooms(&mut rng);
    let mut generation_attempts = 1;

    while !validate_rooms(&rooms) && generation_attempts < MAX_GENERATION_ATTEMPTS {
        generation_attempts += 1;
        rooms = generate_rooms(&mut rng);
    }

    if !validate_rooms(&rooms) {
        println!(
            "no valid rooms after {} generation attempts",
            generation_attempts
        );
        return;
    }

    let edges: Vec<Edge> = generate_edges(&mut rng, &rooms);
    //let tree = build_tree(&edges, &rooms);

    println!("amount of edges {}", edges.len());

    let valid = validate_rooms(&rooms);
    println!(
        "rooms {} after {} generation attempts",
        valid, generation_attempts
    );

    for i in 0..rooms.len() {
        println!("Checking room {}", rooms[i].id);
        println!("Room details: {:?}", rooms[i]);
    }

    println!("these are the room details of each room: {:?}", rooms);

    let mut grid = Grid::constructor(MAP_WIDTH, MAP_HEIGHT);

    for existing_room in &rooms {
        grid.draw_room(existing_room);
    }

    print_grid(&grid);
    let tree = build_tree(&edges, &rooms);
    let doors = generate_doors(&tree, &rooms);

    for door in &doors {
        println!("{:?}", door);
    }

    // TODO: temporary end room, replace with the room bfs finds furthest from room 0
    let end_room: usize = rooms.len() - 1;
    println!("end room {}", end_room);

    visualize_tree_in_graph_form(&tree, &rooms);
}
