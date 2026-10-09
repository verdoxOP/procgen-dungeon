
use rand::{Rng, SeedableRng};
use rand_pcg::Pcg32;
use std::io;

const min_room_count: i32 = 8;
const max_room_count: i32 = 20;
const mst: i32 = 5;
const max_attempts: i32 = 1000;
//mst == mimimum spanning tree, the minimum fastest route to the exit

#[derive(Debug)]
struct Room {
    width: i32,
    height: i32,
    x: i32,
    y: i32,
    id: i32,
}

fn generate_room(rng: &mut Pcg32) -> Room {
    Room {
        id:0,
        width: rng.random_range(8..=20),
        height: rng.random_range(8..=20),
        x: rng.random_range(0..=100),
        y: rng.random_range(0..=100),
    }
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

fn main() {
    let mut input = String::new();
    println!("Enter a seed for the game:");
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    let game_seed: u64 = input.trim().parse().expect("Please enter a valid number");
    let mut rng = Pcg32::seed_from_u64(game_seed);



    let room_count = rng.random_range(min_room_count..=max_room_count);

    let mut room: Vec<Room> = Vec::new();
    let mut attempts = 0;

    while room.len() < room_count as usize && attempts < max_attempts {
        attempts += 1;

        let new_room = generate_room(&mut rng);

        let overlaps = room.iter().any(|existing_room| {
            new_room.room_overlap_check(existing_room)
        });

        if !overlaps {
             let mut new_room = new_room;
             new_room.id = room.len() as i32 + 1;
            room.push(new_room);
        }
    }

    println!("Generated {} rooms in {} attempts", room.len(), attempts);

    for i in 0..room.len() {
        println!("Checking room {}", room[i].id);
        println!("Room details: {:?}", room[i]);
    }

    let overlaps: bool = room.iter().enumerate().any(|(i, room1)| {
        room.iter().enumerate().any(|(j, room2)| {
            i != j && room1.room_overlap_check(room2)
        })
    });

    println!(
        "do the rooms overlap? {}",
        if overlaps { "Yes" } else { "No" }
    );

    println!("these are the room details of each room: {:?}", room);






    //vec of rooms to visualise the rooms in a grid to dubug easily
    struct Grid {
        width: i32,
        height: i32,
        chars: Vec<Vec<char>>,
        room: Vec<Room>,

    }
    impl Grid {
        fn new(width: i32, height: i32) -> Self {
            Self {
                width,
                height,
                chars: vec![vec!['.'; width as usize]; height as usize],
                room: Vec::new(),

                
            }
        }
    fn draw_room(&mut self, room: &Room) {
                    for y in room.y..(room.y + room.height) {
                        for x in room.x..(room.x + room.width) {
                            if y >= 0 && y < self.height && x >= 0 && x < self.width {
                                self.chars[y as usize][x as usize] = '#';
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
    let mut grid = Grid::new(100, 100);
   for existing_room in &room {
    grid.draw_room(existing_room);
}   
    print_grid(&grid);



}
