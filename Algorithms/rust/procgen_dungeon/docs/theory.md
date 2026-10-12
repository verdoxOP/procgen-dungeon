# Theory

[← Documentation home](README.md)

The graph theory behind the generator, tied to the dungeon. Based on the research in the brainstorm document.

## Graphs

A **graph** is a set of **vertices** (points) connected by **edges** (lines). In this project a vertex is a room and an edge is a possible door.

| Term | Meaning | In the dungeon |
|---|---|---|
| directed graph | edges have a direction (A → B) | not used |
| undirected graph | edges work both ways (A – B) | ✅ doors work both ways |
| weighted graph | every edge has a number | ✅ random weights ([`edge.rs` L17](../src/edge.rs#L17)) |
| path | a sequence of edges from one vertex to another | the doors you walk through |
| connected graph | there is a path between every pair of vertices | every room is reachable |
| disconnected graph | some vertices can't be reached | invalid dungeon |
| cycle | a path that ends where it started | only via corridors |
| complete graph | every pair of vertices has an edge | the candidate edges ([`generate_edges`](../src/edge.rs#L12-L25)) |
| sparse graph | few edges compared to the number of vertices | the final dungeon |
| directed acyclic graph (DAG) | directed, no cycles | not used |

## Trees

A **tree** is a graph that is:

- **connected**,
- **acyclic** (no cycles),
- has exactly **n − 1 edges** for n vertices,
- has **exactly one path** between any two vertices.

Two consequences:

- **remove any edge** → the graph falls apart into two pieces (disconnected),
- **add any edge** → it creates a cycle.

In the dungeon: removing a backbone door makes rooms unreachable, and adding a corridor creates an alternate route. That's why the backbone is a tree and corridors are extra.

### Spanning tree

A **spanning tree** of a graph is a tree that includes **every vertex** of that graph, using only edges from that graph.

### Minimum spanning tree (MST)

The spanning tree with the **lowest total weight**. An MST is *not* "the fastest route to the exit"; it's the cheapest way to connect *all* vertices. With random weights, the MST is effectively a random spanning tree.

## Graph representations

The same graph can be stored in different ways. Example graph: 0–1, 0–2, 0–3, 1–3, 2–3, 3–4.

**Adjacency matrix:** n × n table, `1` = edge.

```
    0 1 2 3 4
0 [ 0 1 1 1 0 ]
1 [ 1 0 0 1 0 ]
2 [ 1 0 0 1 0 ]
3 [ 1 1 1 0 1 ]
4 [ 0 0 0 1 0 ]
```

**Edge set / edge list:** a list of pairs.

```
(0,1) (0,2) (0,3) (1,3) (2,3) (3,4)
```

**Adjacency list:** per vertex, its neighbours.

```
0 → 1, 2, 3
1 → 0, 3
2 → 0, 3
3 → 0, 1, 2, 4
4 → 3
```

| | Matrix | Edge list | Adjacency list |
|---|---|---|---|
| memory | n² | E | n + E |
| "is A–B an edge?" | instant | scan all edges | scan A's neighbours |
| "neighbours of A?" | scan a row of n | scan all edges | **direct** |
| best for | dense graphs | Kruskal, storing candidates | sparse graphs, BFS/DFS |

The dungeon uses an **edge list** for the candidate edges ([`Edge`](../src/edge.rs#L6-L11)) and will use an **adjacency list** for the final graph. In an undirected graph, every edge appears in the adjacency list **twice** (A in B's list and B in A's list), so the list lengths add up to 2E.

## Graph traversal

### BFS: breadth-first search

Starts at a chosen vertex, first visits all its direct neighbours, then their neighbours, and so on. It searches the graph **layer by layer**, moving further away from the start.

Because it goes layer by layer, the layer a vertex is found in is its distance (number of edges) from the start. In the dungeon: the number of doors from the start room. That is how the **end room** will be found: the room in the last layer.

### DFS: depth-first search

Picks a neighbour and keeps going deeper until it can't go further, then goes back to the previous vertex and tries another path. Repeats until everything reachable has been visited.

DFS is useful for "can everything be reached?" checks, but it doesn't give the shortest distance, so BFS is the choice for finding the end room.

## Minimum spanning tree algorithms

### Prim

1. Remove self-loops and parallel edges (keep the cheapest).
2. Start from any vertex.
3. Repeatedly pick the cheapest edge from **any already-visited vertex** to an unvisited vertex (no cycles allowed).
4. Stop at n − 1 edges.

Implemented in [`build_tree`](../src/tree.rs#L4-L29). Step 1 is not needed in this project because [`generate_edges`](../src/edge.rs#L14-L15) never creates loops or duplicate pairs.

Common mistake: only looking at the edges of the **most recently added** vertex. Prim looks at the edges of **all** visited vertices. In the code this is the scan over every edge with the XOR check ([`tree.rs` L12–13](../src/tree.rs#L12-L13)).

### Kruskal

1. Remove self-loops and parallel edges (keep the cheapest).
2. Sort all edges by weight, ascending.
3. Go through the sorted list and take each edge unless it creates a cycle.
4. Stop at n − 1 edges. If the list runs out first, the graph is disconnected (in the dungeon: unreachable rooms, so invalid).

Detecting "creates a cycle" efficiently needs a **Union-Find** (disjoint set) structure.

### Comparison

| | Prim | Kruskal |
|---|---|---|
| grows from | one start vertex | the cheapest edges anywhere |
| cycle check | implicit (only edges to unvisited vertices) | needs Union-Find |
| partial result | always one connected tree | a forest of pieces until the end |
| equal weights | can pick a different tree than Kruskal | can pick a different tree than Prim |

Both find a minimum spanning tree. If all weights are different, the MST is unique and both give the same result. Hand-worked examples of both: [Design decisions](design-decisions.md#spanning-tree-algorithm-prim-vs-kruskal).

## Determinism

An algorithm is **deterministic** if the same input always gives the same output. For the generator, the input is the seed. That holds when:

- all randomness comes from one seeded RNG,
- random numbers are drawn in the same order every run,
- data is iterated in a fixed order (`Vec`, not `HashMap`),
- ties are broken by a fixed or seed-based rule.

## Sources

- [Introduction to Graph Theory: A Computer Science Perspective](https://www.youtube.com/watch?v=LFKZLXVO-Dg)
- [Graph Traversals: BFS & DFS](https://www.youtube.com/watch?v=pcKY4hjDrxk)
