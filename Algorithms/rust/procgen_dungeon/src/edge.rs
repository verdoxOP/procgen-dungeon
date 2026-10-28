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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::room_generation::generate_rooms;
    use rand::SeedableRng;

    #[test]
    //n rooms give n*(n-1)/2 edges, no self-loops and no duplicate pairs
    fn edges_form_complete_graph() {
        for seed in 0..200 {
            let mut rng = Pcg32::seed_from_u64(seed);
            let rooms = generate_rooms(&mut rng);
            let edges = generate_edges(&mut rng, &rooms);
            let n = rooms.len();
            assert_eq!(edges.len(), n * (n - 1) / 2, "seed {}", seed);

            let mut pairs: Vec<(usize, usize)> = Vec::new();
            for edge in &edges {
                assert_ne!(edge.Ivertex1, edge.Ivertex2, "seed {}", seed);
                let pair = (
                    edge.Ivertex1.min(edge.Ivertex2),
                    edge.Ivertex1.max(edge.Ivertex2),
                );
                assert!(!pairs.contains(&pair), "seed {}", seed);
                pairs.push(pair);
            }
        }
    }
}
