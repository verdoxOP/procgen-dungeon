use rand::Rng;
use rand_pcg::Pcg32;

use crate::constants::{
    MAP_HEIGHT, MAP_WIDTH, MAX_ROOM_HEIGHT, MAX_ROOM_WIDTH, MIN_ROOM_HEIGHT, MIN_ROOM_WIDTH,
    max_attempts, max_room_count, min_room_count,
};
use crate::room::Room;

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

pub fn generate_rooms(rng: &mut Pcg32) -> Vec<Room> {
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

    eprintln!("Generated {} rooms in {} attempts", rooms.len(), attempts);
    rooms
}

#[cfg(test)]
mod tests {
    use super::*;
    use rand::SeedableRng;

    #[test]
    //every generated room fits inside the map
    fn rooms_fit_inside_map() {
        for seed in 0..200 {
            let mut rng = Pcg32::seed_from_u64(seed);
            for room in generate_rooms(&mut rng) {
                assert!(room.x >= 0 && room.y >= 0, "seed {}", seed);
                assert!(room.x + room.width <= MAP_WIDTH, "seed {}", seed);
                assert!(room.y + room.height <= MAP_HEIGHT, "seed {}", seed);
            }
        }
    }

    #[test]
    //no two generated rooms overlap (VR-02)
    fn rooms_do_not_overlap() {
        for seed in 0..200 {
            let mut rng = Pcg32::seed_from_u64(seed);
            let rooms = generate_rooms(&mut rng);
            for i in 0..rooms.len() {
                for j in (i + 1)..rooms.len() {
                    assert!(!rooms[i].room_overlap_check(&rooms[j]), "seed {}", seed);
                }
            }
        }
    }

    #[test]
    //the id of every room is its index in the vec
    fn room_id_is_index() {
        for seed in 0..200 {
            let mut rng = Pcg32::seed_from_u64(seed);
            let rooms = generate_rooms(&mut rng);
            for (index, room) in rooms.iter().enumerate() {
                assert_eq!(room.id, index, "seed {}", seed);
            }
        }
    }
}
