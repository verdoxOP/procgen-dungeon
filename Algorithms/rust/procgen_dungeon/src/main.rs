use rand::{Rng, SeedableRng};
use rand_pcg::Pcg32;
use std::io;

const MIN_ROOM_COUNT: usize = 8;
const MAX_ROOM_COUNT: usize = 20;
const MST: i32 = 5;
const MAX_PLACEMENT_ATTEMPTS: i32 = 1000;
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
    id: usize,
    width: i32,
    height: i32,
    x: i32,
    y: i32,
}

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
    let room_count = rng.random_range(MIN_ROOM_COUNT..=MAX_ROOM_COUNT);
    let mut rooms: Vec<Room> = Vec::new();
    let mut attempts = 0;

    while rooms.len() < room_count && attempts < MAX_PLACEMENT_ATTEMPTS {
        attempts += 1;

        let mut new_room = generate_room(rng);
        //validate
        let overlaps = rooms.iter().any(|existing_room| {
            new_room.overlaps(existing_room)
        });

        if !overlaps {
            new_room.id = rooms.len();
            rooms.push(new_room);
        }
    }

    println!("Generated {} rooms in {} attempts", rooms.len(), attempts);
    rooms
}

impl Room {
    fn overlaps(&self, other: &Room) -> bool {
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
    fn new(width: i32, height: i32) -> Grid {
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
    if rooms.len() < MIN_ROOM_COUNT {
        println!("number of rooms is not enough, number of rooms is {}", rooms.len());
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
            if room1.overlaps(room2) {
                println!("rooms {} and {} overlap :C", room1.id, room2.id);
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

    let valid = validate_rooms(&rooms);
    println!("rooms {} after {} generation attempts", valid, generation_attempts);

    for room in &rooms {
        println!("Checking room {}", room.id);
        println!("Room details: {:?}", room);
    }

    println!("these are the room details of each room: {:?}", rooms);

    let mut grid = Grid::new(MAP_WIDTH, MAP_HEIGHT);

    for room in &rooms {
        grid.draw_room(room);
    }

    print_grid(&grid);
}