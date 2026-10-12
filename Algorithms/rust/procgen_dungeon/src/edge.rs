use rand::Rng;
use rand_pcg::Pcg32;

use crate::room::Room;

#[derive(Debug, Clone)]
pub struct Edge {
    pub weight: i32,
    pub Ivertex1: usize,
    pub Ivertex2: usize,
}
pub fn generate_edges(rng: &mut Pcg32, rooms: &[Room]) -> Vec<Edge> {
    let mut edges: Vec<Edge> = Vec::new();
    for i in 0..rooms.len() {
        for j in (i + 1)..rooms.len() {
            let new_edge = Edge {
                weight: rng.random_range(1..=100),
                Ivertex1: i,
                Ivertex2: j,
            };
            edges.push(new_edge);
        }
    }
    edges
}
