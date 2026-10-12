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
