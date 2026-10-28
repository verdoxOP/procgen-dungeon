use std::collections::VecDeque;

use crate::door::Door;

//bfs from the start room over the doors, gives the distance of every room in doors from the start
pub fn room_distances(doors: &[Door], room_count: usize, start_room: usize) -> Vec<i32> {
    //neighbours of each room, a door goes both ways
    let mut neighbours: Vec<Vec<usize>> = vec![Vec::new(); room_count];
    for door in doors {
        neighbours[door.room_a].push(door.room_b);
        neighbours[door.room_b].push(door.room_a);
    }

    //-1 means not reached yet
    let mut distances = vec![-1; room_count];
    distances[start_room] = 0;

    let mut queue: VecDeque<usize> = VecDeque::new();
    queue.push_back(start_room);

    while let Some(room) = queue.pop_front() {
        for &neighbour in &neighbours[room] {
            if distances[neighbour] == -1 {
                distances[neighbour] = distances[room] + 1;
                queue.push_back(neighbour);
            }
        }
    }

    distances
}

//the end room is the room the most doors away from the start, on a tie the lowest id wins
pub fn furthest_room(distances: &[i32]) -> usize {
    let mut end_room: usize = 0;
    for room in 0..distances.len() {
        if distances[room] > distances[end_room] {
            end_room = room;
        }
    }
    end_room
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::door::Wall;

    fn door(room_a: usize, room_b: usize) -> Door {
        Door { room_a, room_b, wall_a: Wall::Right, wall_b: Wall::Left }
    }

    #[test]
    //on a line 0-1-2-3 the start is 0 doors away and room 3 is furthest
    fn distances_on_a_line() {
        let doors = vec![door(0, 1), door(1, 2), door(2, 3)];
        let distances = room_distances(&doors, 4, 0);
        assert_eq!(distances, vec![0, 1, 2, 3]);
        assert_eq!(furthest_room(&distances), 3);
    }

    #[test]
    //doors work both ways, so a door stored as 1->0 still reaches room 1 from 0
    fn doors_go_both_ways() {
        let doors = vec![door(1, 0), door(2, 1)];
        let distances = room_distances(&doors, 3, 0);
        assert_eq!(distances, vec![0, 1, 2]);
    }

    #[test]
    //on a tie between two furthest rooms the lowest id wins
    fn tie_lowest_id_wins() {
        let doors = vec![door(0, 1), door(1, 2), door(0, 3), door(3, 4)];
        let distances = room_distances(&doors, 5, 0);
        assert_eq!(distances, vec![0, 1, 2, 1, 2]);
        assert_eq!(furthest_room(&distances), 2);
    }
}
