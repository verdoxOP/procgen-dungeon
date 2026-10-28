use crate::edge::Edge;
use crate::room::Room;
use serde::Serialize;

//which side of a room a door is on, an enum so a typo is a compile error instead of a bug in godot
#[derive(Debug, Clone, Copy, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Wall {
    Top,
    Bottom,
    Left,
    Right,
}

//a door connects two rooms from the tree, with the wall it sits on in each room
//the renames give the json keys godot expects without renaming the rust fields
#[derive(Debug, Serialize)]
pub struct Door {
    #[serde(rename = "from")]
    pub room_a: usize,
    #[serde(rename = "to")]
    pub room_b: usize,
    #[serde(rename = "from_wall")]
    pub wall_a: Wall,
    #[serde(rename = "to_wall")]
    pub wall_b: Wall,
}

//the door in room b is always on the wall facing room a
pub fn opposite_wall(wall: Wall) -> Wall {
    match wall {
        Wall::Top => Wall::Bottom,
        Wall::Bottom => Wall::Top,
        Wall::Left => Wall::Right,
        Wall::Right => Wall::Left,
    }
}

pub fn edge_to_door(edge: &Edge, rooms: &[Room]) -> Door {
    //id = index, so the edge ids can be used to look up the rooms directly
    let room_a = &rooms[edge.Ivertex1];
    let room_b = &rooms[edge.Ivertex2];

    let center_a_x = room_a.x + room_a.width / 2;
    let center_a_y = room_a.y + room_a.height / 2;
    let center_b_x = room_b.x + room_b.width / 2;
    let center_b_y = room_b.y + room_b.height / 2;

    let dx = center_b_x - center_a_x;
    let dy = center_b_y - center_a_y;

    //the bigger difference picks the axis, on a tie the door goes on a left or right wall
    //y grows downwards in the grid, so a positive dy means room b is below room a
    let wall_a = if dx.abs() >= dy.abs() {
        if dx > 0 { Wall::Right } else { Wall::Left }
    } else {
        if dy > 0 { Wall::Bottom } else { Wall::Top }
    };

    Door {
        room_a: edge.Ivertex1,
        room_b: edge.Ivertex2,
        wall_a,
        wall_b: opposite_wall(wall_a),
    }
}

pub fn generate_doors(tree: &[Edge], rooms: &[Room]) -> Vec<Door> {
    let mut doors: Vec<Door> = Vec::new();
    for edge in tree {
        doors.push(edge_to_door(edge, rooms));
    }
    doors
}

#[cfg(test)]
mod tests {
    use super::*;

    fn room(x: i32, y: i32, id: usize) -> Room {
        Room { width: 10, height: 10, x, y, id }
    }

    fn door_from_0_to_1(other_x: i32, other_y: i32) -> Door {
        let rooms = vec![room(50, 50, 0), room(other_x, other_y, 1)];
        let edge = Edge { weight: 1, Ivertex1: 0, Ivertex2: 1 };
        edge_to_door(&edge, &rooms)
    }

    #[test]
    //room b to the right gets a right door in a and a left door in b
    fn door_right() {
        let door = door_from_0_to_1(70, 50);
        assert!(matches!(door.wall_a, Wall::Right));
        assert!(matches!(door.wall_b, Wall::Left));
    }

    #[test]
    //room b to the left gets a left door in a and a right door in b
    fn door_left() {
        let door = door_from_0_to_1(30, 50);
        assert!(matches!(door.wall_a, Wall::Left));
        assert!(matches!(door.wall_b, Wall::Right));
    }

    #[test]
    //room b below gets a bottom door in a and a top door in b
    fn door_bottom() {
        let door = door_from_0_to_1(50, 70);
        assert!(matches!(door.wall_a, Wall::Bottom));
        assert!(matches!(door.wall_b, Wall::Top));
    }

    #[test]
    //room b above gets a top door in a and a bottom door in b
    fn door_top() {
        let door = door_from_0_to_1(50, 30);
        assert!(matches!(door.wall_a, Wall::Top));
        assert!(matches!(door.wall_b, Wall::Bottom));
    }

    #[test]
    //on a diagonal tie |dx| == |dy| the door goes on the left or right wall
    fn diagonal_tie_goes_left_or_right() {
        assert!(matches!(door_from_0_to_1(70, 70).wall_a, Wall::Right));
        assert!(matches!(door_from_0_to_1(30, 30).wall_a, Wall::Left));
        assert!(matches!(door_from_0_to_1(70, 30).wall_a, Wall::Right));
        assert!(matches!(door_from_0_to_1(30, 70).wall_a, Wall::Left));
    }

    #[test]
    //wall_b is always the opposite of wall_a
    fn wall_b_is_opposite_of_wall_a() {
        for (x, y) in [(70, 50), (30, 50), (50, 70), (50, 30), (70, 70), (30, 30), (65, 80), (20, 55)] {
            let door = door_from_0_to_1(x, y);
            let expected = opposite_wall(door.wall_a);
            assert_eq!(
                std::mem::discriminant(&door.wall_b),
                std::mem::discriminant(&expected)
            );
        }
    }
}
