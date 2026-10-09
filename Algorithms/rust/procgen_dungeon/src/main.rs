use rand::{Rng, SeedableRng};
use rand_pcg::Pcg32;
use std::io;

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
        let self_id = self.id;
        let other_id = other.id;

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

    let room1 = generate_room(&mut rng);
    let room2 = generate_room(&mut rng);
    let room3 = generate_room(&mut rng);

    let mut room: Vec<Room> = Vec::new();
    room.push(room1);
    room.push(room2);
    room.push(room3);

    for i in 0..room.len() {
        println!("Checking room {}", room[i].id);
    }

    let overlaps = room[0].room_overlap_check(&room[2])
        || room[0].room_overlap_check(&room[1])
        || room[0].room_overlap_check(&room[2])
        || room[1].room_overlap_check(&room[2]);
    println!(
        "do the rooms overlap? {}",
        if overlaps { "Yes" } else { "No" }
    );
}
