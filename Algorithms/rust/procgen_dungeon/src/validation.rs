use crate::constants::{MIN_ROOM_HEIGHT, MIN_ROOM_WIDTH, min_room_count};
use crate::room::Room;

pub fn validate_rooms(rooms: &[Room]) -> bool {
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
