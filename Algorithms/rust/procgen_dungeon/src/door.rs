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
