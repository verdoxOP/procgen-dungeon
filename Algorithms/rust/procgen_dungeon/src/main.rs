
use rand::{Rng, SeedableRng};
use rand_pcg::Pcg32;
use std::io;

const min_room_count: usize = 8;
const max_room_count: usize = 20;
const mst: i32 = 5;
const max_attempts: i32 = 1000;
const MIN_ROOM_WIDTH: i32 = 8;
const MIN_ROOM_HEIGHT: i32 = 8;
//mst == mimimum spanning tree, the minimum fastest route to the exit

#[derive(Debug)]
struct Room {
    width: i32,
    height: i32,
    x: i32,
    y: i32,
    id: i32,
}
//generate a room 
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
//validate
        let overlaps = room.iter().any(|existing_room| {
            new_room.room_overlap_check(existing_room)
        });

        if !overlaps {
             let mut new_room = new_room;
             new_room.id = room.len() as i32 + 1;
            room.push(new_room);
        }
    }
let valid = validate_rooms(&room);
println!("rooms {}", valid);

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




//teken grid

    //vec of rooms to visualise the rooms in a grid to dubug easily
    struct Grid {
        width: i32,
        height: i32,
        chars: Vec<Vec<char>>,
        room: Vec<Room>,

    }
    impl Grid {
        fn constructor(width: i32, height: i32) -> Grid {
            Grid {
                width,
                height,
                chars: vec![vec!['.'; width as usize]; height as usize],
                room: Vec::new(),
                // Add a field to store the rooms
                
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
    let mut grid = Grid::constructor(100, 100);
   for existing_room in &room {
    grid.draw_room(existing_room);
}   
    print_grid(&grid);

fn validate_rooms(rooms: &[Room]) -> bool {
  
    if rooms.len() < min_room_count{
println!("number of rooms is not enough, number of rooms is {}", rooms.len());
return false;
    }
    

for room in rooms{
    println!("{}", room.width);
    println!("{}", room.height);
    if room.height < MIN_ROOM_HEIGHT|| room.width < MIN_ROOM_WIDTH{
        println!("failed room dimensions too small");
    return false;
    }
}
    true



}




}
