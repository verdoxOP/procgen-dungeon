use serde::Serialize;

#[derive(Debug, Serialize)]
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

#[cfg(test)]
mod tests {
    use super::*;

    fn room(x: i32, y: i32, width: i32, height: i32) -> Room {
        Room { width, height, x, y, id: 0 }
    }

    #[test]
    //two rooms that share a tile overlap
    fn overlapping_rooms_overlap() {
        let a = room(0, 0, 10, 10);
        let b = room(5, 5, 10, 10);
        assert!(a.room_overlap_check(&b));
        assert!(b.room_overlap_check(&a));
    }

    #[test]
    //rooms that only touch on a side do not overlap
    fn touching_rooms_do_not_overlap() {
        let a = room(0, 0, 10, 10);
        let right = room(10, 0, 10, 10);
        let below = room(0, 10, 10, 10);
        assert!(!a.room_overlap_check(&right));
        assert!(!a.room_overlap_check(&below));
        assert!(!right.room_overlap_check(&a));
        assert!(!below.room_overlap_check(&a));
    }
}
