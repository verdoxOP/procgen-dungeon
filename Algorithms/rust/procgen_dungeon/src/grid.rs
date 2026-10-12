use crate::room::Room;

//teken grid

//vec of rooms to visualise the rooms in a grid to dubug easily
pub struct Grid {
    pub width: i32,
    pub height: i32,
    pub chars: Vec<Vec<char>>,
}

impl Grid {
    pub fn constructor(width: i32, height: i32) -> Grid {
        Grid {
            width,
            height,
            chars: vec![vec!['.'; width as usize]; height as usize],
            // Add a field to store the rooms
        }
    }

    pub fn draw_room(&mut self, room: &Room) {
        let symbol = char::from_digit(room.id as u32 % 36, 36).unwrap();

        for y in room.y..(room.y + room.height) {
            for x in room.x..(room.x + room.width) {
                if y >= 0 && y < self.height && x >= 0 && x < self.width {
                    self.chars[y as usize][x as usize] = symbol;
                }
            }
        }
    }
}

pub fn print_grid(grid: &Grid) {
    for row in &grid.chars {
        let line: String = row.iter().collect();
        println!("{}", line);
    }
}
