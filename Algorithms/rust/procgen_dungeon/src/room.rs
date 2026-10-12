#[derive(Debug)]
pub struct Room {
    pub width: i32,
    pub height: i32,
    pub x: i32,
    pub y: i32,
    pub id: usize,
}

impl Room {
    pub fn room_overlap_check(&self, other: &Room) -> bool {
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
