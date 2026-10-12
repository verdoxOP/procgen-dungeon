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
