use rand::{Rng, SeedableRng};
use rand_pcg::Pcg32;
use std::io;

const min_room_count: i32 = 8;
const max_room_count: i32 = 20;
const mst:i32 = 5;
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
        id: rng.random_range(1..=1000),
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

//    let room1 = generate_room(&mut rng);

    let room_count = rng.random_range(min_room_count..=max_room_count);

    let mut room: Vec<Room> = Vec::new();
   for i in 0..room_count {
        let new_room = generate_room(&mut rng);
        room.push(new_room);
    }

    for i in 0..room.len() {
        println!("Checking room {}", room[i].id);
        println!("Room details: {:?}", room[i]);
    }

    let overlaps = room[0].room_overlap_check(&room[2])
        || room[0].room_overlap_check(&room[1])
        || room[0].room_overlap_check(&room[2])
        || room[1].room_overlap_check(&room[2]);
    println!(
        "do the rooms overlap? {}",
        if overlaps { "Yes" } else { "No" }
        
    );
    println!("these are the room details of each room: {:?}", room);

}
