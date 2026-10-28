use crate::constants::{MIN_ROOM_HEIGHT, MIN_ROOM_WIDTH, min_room_count};
use crate::room::Room;

pub fn validate_rooms(rooms: &[Room]) -> bool {
    if rooms.len() < min_room_count {
        eprintln!(
            "number of rooms is not enough, number of rooms is {}",
            rooms.len()
        );
        return false;
    }

    for room in rooms {
        if room.height < MIN_ROOM_HEIGHT || room.width < MIN_ROOM_WIDTH {
            eprintln!("failed room dimensions too small");
            return false;
        }
    }

    for i in 0..rooms.len() {
        for j in (i + 1)..rooms.len() {
            let room1 = &rooms[i];
            let room2 = &rooms[j];
            if room1.room_overlap_check(room2) {
                eprintln!("rooms {} and {} overlap :C", rooms[i].id, rooms[j].id);
                return false;
            }
        }
    }

    true
}

#[cfg(test)]
mod tests {
    use super::*;

    fn rooms_in_a_row(count: usize, width: i32, height: i32) -> Vec<Room> {
        let mut rooms: Vec<Room> = Vec::new();
        for i in 0..count {
            rooms.push(Room {
                width,
                height,
                x: i as i32 * 25,
                y: 0,
                id: i,
            });
        }
        rooms
    }

    #[test]
    //enough rooms of a good size that dont overlap are valid
    fn valid_rooms_pass() {
        let rooms = rooms_in_a_row(min_room_count, MIN_ROOM_WIDTH, MIN_ROOM_HEIGHT);
        assert!(validate_rooms(&rooms));
    }

    #[test]
    //one room less than the minimum is rejected (VR-03)
    fn too_few_rooms_fail() {
        let rooms = rooms_in_a_row(min_room_count - 1, MIN_ROOM_WIDTH, MIN_ROOM_HEIGHT);
        assert!(!validate_rooms(&rooms));
    }

    #[test]
    //a room that is too narrow or too low is rejected (VR-01)
    fn too_small_rooms_fail() {
        let mut rooms = rooms_in_a_row(min_room_count, MIN_ROOM_WIDTH, MIN_ROOM_HEIGHT);
        rooms[3].width = MIN_ROOM_WIDTH - 1;
        assert!(!validate_rooms(&rooms));

        let mut rooms = rooms_in_a_row(min_room_count, MIN_ROOM_WIDTH, MIN_ROOM_HEIGHT);
        rooms[3].height = MIN_ROOM_HEIGHT - 1;
        assert!(!validate_rooms(&rooms));
    }

    #[test]
    //two overlapping rooms are rejected (VR-02)
    fn overlapping_rooms_fail() {
        let mut rooms = rooms_in_a_row(min_room_count, MIN_ROOM_WIDTH, MIN_ROOM_HEIGHT);
        rooms[1].x = rooms[0].x + 2;
        assert!(!validate_rooms(&rooms));
    }
}
