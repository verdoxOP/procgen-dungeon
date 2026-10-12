use rand::{Rng, SeedableRng};
use rand_pcg::Pcg32;
use std::io;

const min_room_count: usize = 8;
const max_room_count: usize = 20;
const mst: i32 = 5;
const max_attempts: i32 = 1000;
const MAX_GENERATION_ATTEMPTS: i32 = 10;
const MIN_ROOM_WIDTH: i32 = 8;
const MIN_ROOM_HEIGHT: i32 = 8;
const MAX_ROOM_WIDTH: i32 = 20;
const MAX_ROOM_HEIGHT: i32 = 20;
const MAP_WIDTH: i32 = 100;
const MAP_HEIGHT: i32 = 100;
//mst == mimimum spanning tree, the minimum fastest route to the exit

#[derive(Debug)]
struct Room {
    width: i32,
    height: i32,
    x: i32,
    y: i32,
    id: usize,
}
#[derive(Debug, Clone)]
struct Edge {
    weight: i32,
    Ivertex1: usize,
    Ivertex2: usize,
}
fn generate_edges(rng: &mut Pcg32, rooms: &[Room]) -> Vec<Edge> {
    let mut edges: Vec<Edge> = Vec::new();
    for i in 0..rooms.len() {
        for j in (i + 1)..rooms.len() {
            let new_edge = Edge {
                weight: rng.random_range(1..=100),
                Ivertex1: i,
                Ivertex2: j,
            };
            edges.push(new_edge);
        }
    }
    edges
}

fn build_tree(edges: &[Edge], rooms: &[Room]) -> Vec<Edge> {
    let mut visited = vec![false; rooms.len()];
    visited[0] = true;

    let mut tree: Vec<Edge> = Vec::new();
    while tree.len() < rooms.len() - 1 {
        let mut index_edges: usize = 0;
        let mut weight: i32 = 101;
        for (index_edges_new, edge) in edges.iter().enumerate() {
            if visited[edge.Ivertex1] ^ visited[edge.Ivertex2] {
                if edge.weight < weight {
                    weight = edge.weight;
                    index_edges = index_edges_new;
                }
            }
        }
        for edge in edges.iter().take(index_edges + 1).skip(index_edges) {
            let edge = &edges[index_edges];
            visited[edge.Ivertex1] = true;
            visited[edge.Ivertex2] = true;
        }
        tree.push(edges[index_edges].clone());
    }

    tree
}

/*
Outer loop: keep repeating while tree.len() is smaller than rooms.len() - 1. Look up while loops in Rust for this.
Before searching, inside the outer loop: make two variables to remember the best edge found so far:
one for its index in edges (a usize) and one for its weight (an i32).
Start the weight at something higher than any real weight, so the first valid edge always beats it.
Your weights go up to 100, so think about what start value works.
Inner loop: go through every edge in edges, keeping track of each edge’s index.
Skip the edge unless exactly one of its two rooms is visited. Hint: compare visited[...] for Ivertex1 and Ivertex2. When are two bools “exactly one true”?
If it passes, and its weight is lower than the best weight so far, save its index and weight.
After the inner loop: you have the index of the cheapest valid edge.
Mark both of its rooms as visited. One is already true, and setting it again is harmless, so you don’t have to work out which one is new.
Push that edge into tree. */

//generate a room
fn generate_room(rng: &mut Pcg32) -> Room {
    let width = rng.random_range(MIN_ROOM_WIDTH..=MAX_ROOM_WIDTH);
    let height = rng.random_range(MIN_ROOM_HEIGHT..=MAX_ROOM_HEIGHT);

    Room {
        id: 0,
        width,
        height,
        x: rng.random_range(0..=MAP_WIDTH - width),
        y: rng.random_range(0..=MAP_HEIGHT - height),
    }
}

fn generate_rooms(rng: &mut Pcg32) -> Vec<Room> {
    let room_count = rng.random_range(min_room_count..=max_room_count);
    let mut rooms: Vec<Room> = Vec::new();
    let mut attempts = 0;

    while rooms.len() < room_count && attempts < max_attempts {
        attempts += 1;

        let new_room = generate_room(rng);
        //validate
        let overlaps = rooms
            .iter()
            .any(|existing_room| new_room.room_overlap_check(existing_room));

        if !overlaps {
            let mut new_room = new_room;
            new_room.id = rooms.len();
            rooms.push(new_room);
        }
    }

    println!("Generated {} rooms in {} attempts", rooms.len(), attempts);
    rooms
}

impl Room {
    fn room_overlap_check(&self, other: &Room) -> bool {
        let self_right = self.x + self.width;
        let self_bottom = self.y + self.height;
        let other_right = other.x + other.width;
        let other_bottom = other.y + other.height;

        !(self.x >= other_right
            || self_right <= other.x
            || self.y >= other_bottom
            || self_bottom <= other.y)
    }
}

//teken grid

//vec of rooms to visualise the rooms in a grid to dubug easily
struct Grid {
    width: i32,
    height: i32,
    chars: Vec<Vec<char>>,
}

impl Grid {
    fn constructor(width: i32, height: i32) -> Grid {
        Grid {
            width,
            height,
            chars: vec![vec!['.'; width as usize]; height as usize],
            // Add a field to store the rooms
        }
    }

    fn draw_room(&mut self, room: &Room) {
        let symbol = char::from_digit(room.id as u32 % 36, 36).unwrap();

        for y in room.y..(room.y + room.height) {
            for x in room.x..(room.x + room.width) {
                if y >= 0 && y < self.height && x >= 0 && x < self.width {
                    self.chars[y as usize][x as usize] = symbol;
                }
            }
        }
    }
}

fn print_grid(grid: &Grid) {
    for row in &grid.chars {
        let line: String = row.iter().collect();
        println!("{}", line);
    }
}

fn validate_rooms(rooms: &[Room]) -> bool {
    if rooms.len() < min_room_count {
        println!(
            "number of rooms is not enough, number of rooms is {}",
            rooms.len()
        );
        return false;
    }

    for room in rooms {
        if room.height < MIN_ROOM_HEIGHT || room.width < MIN_ROOM_WIDTH {
            println!("failed room dimensions too small");
            return false;
        }
    }

    for i in 0..rooms.len() {
        for j in (i + 1)..rooms.len() {
            let room1 = &rooms[i];
            let room2 = &rooms[j];
            if room1.room_overlap_check(room2) {
                println!("rooms {} and {} overlap :C", rooms[i].id, rooms[j].id);
                return false;
            }
        }
    }

    true
}

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

    let edges: Vec<Edge> = generate_edges(&mut rng, &rooms);
    //let tree = build_tree(&edges, &rooms);

    for edge in &edges {
        println!("amount of edges {:?}", edges.len())
    }

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
}
