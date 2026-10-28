use crate::edge::Edge;
use crate::room::Room;

pub fn build_tree(edges: &[Edge], rooms: &[Room]) -> Vec<Edge> {
    let mut visited = vec![false; rooms.len()];
    visited[0] = true;

    let mut tree: Vec<Edge> = Vec::new();
    while tree.len() < rooms.len() - 1 {
        let mut index_edges: usize = 0;
        let mut weight: i32 = 101;
        for (index_edges_new, edge) in edges.iter().enumerate() {
            if visited[edge.Ivertex1] ^ visited[edge.Ivertex2] {
                if edge.weight < weight {
                    weight = edge.weight;
                    index_edges = index_edges_new;
                }
            }
        }
        for edge in edges.iter().take(index_edges + 1).skip(index_edges) {
            let edge = &edges[index_edges];
            visited[edge.Ivertex1] = true;
            visited[edge.Ivertex2] = true;
        }
        tree.push(edges[index_edges].clone());
    }

    tree
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::constants::MAX_GENERATION_ATTEMPTS;
    use crate::edge::generate_edges;
    use crate::room_generation::generate_rooms;
    use crate::validation::validate_rooms;
    use rand::SeedableRng;
    use rand_pcg::Pcg32;

    fn generate(seed: u64) -> (Vec<Room>, Vec<Edge>, Vec<Edge>) {
        let mut rng = Pcg32::seed_from_u64(seed);
        let mut rooms = generate_rooms(&mut rng);
        let mut generation_attempts = 1;
        while !validate_rooms(&rooms) && generation_attempts < MAX_GENERATION_ATTEMPTS {
            generation_attempts += 1;
            rooms = generate_rooms(&mut rng);
        }
        assert!(validate_rooms(&rooms), "seed {} has no valid rooms", seed);
        let edges = generate_edges(&mut rng, &rooms);
        let tree = build_tree(&edges, &rooms);
        (rooms, edges, tree)
    }

    fn room_values(rooms: &[Room]) -> Vec<(i32, i32, i32, i32, usize)> {
        rooms.iter().map(|r| (r.x, r.y, r.width, r.height, r.id)).collect()
    }

    fn edge_values(edges: &[Edge]) -> Vec<(i32, usize, usize)> {
        edges.iter().map(|e| (e.weight, e.Ivertex1, e.Ivertex2)).collect()
    }

    #[test]
    //the tree has n-1 edges and every room can be reached from room 0
    fn tree_has_n_minus_1_edges_and_reaches_every_room() {
        for seed in 0..200 {
            let (rooms, _, tree) = generate(seed);
            assert_eq!(tree.len(), rooms.len() - 1, "seed {}", seed);

            let mut reached = vec![false; rooms.len()];
            reached[0] = true;
            let mut changed = true;
            while changed {
                changed = false;
                for edge in &tree {
                    if reached[edge.Ivertex1] != reached[edge.Ivertex2] {
                        reached[edge.Ivertex1] = true;
                        reached[edge.Ivertex2] = true;
                        changed = true;
                    }
                }
            }
            assert!(reached.iter().all(|&r| r), "seed {}", seed);
        }
    }

    #[test]
    //the same seed twice gives the same rooms, edges and tree
    fn same_seed_same_dungeon() {
        for seed in 0..200 {
            let (rooms_1, edges_1, tree_1) = generate(seed);
            let (rooms_2, edges_2, tree_2) = generate(seed);
            assert_eq!(room_values(&rooms_1), room_values(&rooms_2), "seed {}", seed);
            assert_eq!(edge_values(&edges_1), edge_values(&edges_2), "seed {}", seed);
            assert_eq!(edge_values(&tree_1), edge_values(&tree_2), "seed {}", seed);
        }
    }

    #[test]
    //two different seeds give a different tree
    fn different_seed_different_tree() {
        for seed in 0..200 {
            let (_, _, tree_1) = generate(seed);
            let (_, _, tree_2) = generate(seed + 1);
            assert_ne!(edge_values(&tree_1), edge_values(&tree_2), "seed {}", seed);
        }
    }
}
