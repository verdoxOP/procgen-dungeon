# Architecture

[← Documentation home](README.md)

## Goal

The generator produces validated dungeon data that the Godot game loads as JSON. It has to run and be testable **without Godot**.

```
Rust generator → validated dungeon data → JSON → Godot
```

The Rust side owns generation, validation and the dungeon data. The Godot side owns gameplay, rendering and turning tile coordinates into world positions.

## Requirements

From the brainstorm document.

### The generator must

| Requirement | Status |
|---|---|
| Generate N non-overlapping rooms | ✅ [`room_generation.rs`](../src/room_generation.rs), [`validation.rs`](../src/validation.rs) |
| Create a connected dungeon structure | ✅ [`tree.rs`](../src/tree.rs) (spanning tree) |
| Generate corridors between connected rooms | ⏳ planned |
| Populate the dungeon | ⏳ planned |
| Validate each generation stage | 🟡 rooms done, other stages planned |
| Use a seed | ✅ [`main.rs` L23–30](../src/main.rs#L23-L30) |
| Export the result for Godot | ⏳ planned (JSON) |

### The generator does not initially need

- infinite generation
- chunk streaming
- multithreading
- complex room templates
- advanced optimisation

These are deliberately out of scope for the MVP (see [Roadmap](roadmap.md#scope)).

## Concepts

| Concept | Meaning |
|---|---|
| **Room** | a normal gameplay chamber; one room = one screen |
| **Door / connection** | a normal graph edge; moves the player directly from one room to another |
| **Corridor** | an optional hidden path between rooms that aren't directly connected in the normal graph; may need a weak wall to be broken, may contain passive spawnables, creates shortcuts / alternate routes |
| **Backbone** | the spanning tree of doors; the dungeon must be fully playable with only these |
| **Dungeon** | all rooms plus the graph; it knows which room is the start and which is the end |

## Pipeline

### Implemented

```mermaid
flowchart LR
    seed[seed from stdin] --> rng[Pcg32 RNG]
    rng --> gen[generate_rooms]
    gen --> val{validate_rooms}
    val -- fail, attempts left --> gen
    val -- pass / out of attempts --> edges[generate_edges]
    edges --> prim[build_tree<br/>Prim]
    prim --> viz[Graphviz tree.dot / tree.png]
    gen --> grid[ASCII grid]
```

### Planned

Each stage validates its own output and retries locally, with a maximum number of attempts.

```
generate rooms → validate rooms (fail: regenerate)
→ build graph / backbone → validate backbone
→ optional corridors → validate corridors
→ populate → validate population
→ serialize JSON → Godot
```

## Data flow in `main`

| Step | Call | Produces | Code |
|---|---|---|---|
| 1 | read stdin, `Pcg32::seed_from_u64` | `rng: Pcg32` | [L23–30](../src/main.rs#L23-L30) |
| 2 | `generate_rooms` in a retry loop with `validate_rooms` | `rooms: Vec<Room>` | [L55–61](../src/main.rs#L55-L61) |
| 3 | `generate_edges(&mut rng, &rooms)` | `edges: Vec<Edge>` (complete graph) | [L63](../src/main.rs#L63) |
| 4 | `Grid::constructor` + `draw_room` + `print_grid` | ASCII map on stdout | [L83–89](../src/main.rs#L83-L89) |
| 5 | `build_tree(&edges, &rooms)` | `tree: Vec<Edge>` (n − 1 edges) | [L90](../src/main.rs#L90) |
| 6 | `visualize_tree_in_graph_form(&tree, &rooms)` | `tree.dot`, `tree.png` | [L91](../src/main.rs#L91) |

The same `rng` is passed by `&mut` through every random step. That is what makes a seed fully determine the dungeon: the order of calls fixes the order of random numbers. Adding a new random call somewhere in the middle changes everything after it, so the same seed will give a different dungeon after such a change.

## Modules

| Module | Responsibility | Public items |
|---|---|---|
| [`constants`](../src/constants.rs) | tunable parameters | all constants |
| [`room`](../src/room.rs) | the room data type | `Room`, `Room::room_overlap_check` |
| [`room_generation`](../src/room_generation.rs) | placing rooms on the map | `generate_rooms` (`generate_room` is private) |
| [`validation`](../src/validation.rs) | checking a room set | `validate_rooms` |
| [`edge`](../src/edge.rs) | candidate connections between rooms | `Edge`, `generate_edges` |
| [`tree`](../src/tree.rs) | the backbone (spanning tree) | `build_tree` |
| [`grid`](../src/grid.rs) | ASCII debug view | `Grid`, `print_grid` |
| [`tree_visualization`](../src/tree_visualization.rs) | Graphviz debug view | `visualize_tree_in_graph_form` |

Each file has one responsibility, so a stage can be tested or replaced on its own. Modules are registered in [`main.rs` L1–8](../src/main.rs#L1-L8).

## Module dependencies

```mermaid
flowchart TD
    main --> constants
    main --> room_generation
    main --> validation
    main --> edge
    main --> tree
    main --> grid
    main --> tree_visualization
    room_generation --> constants
    room_generation --> room
    validation --> constants
    validation --> room
    edge --> room
    tree --> edge
    tree --> room
    grid --> room
    tree_visualization --> edge
    tree_visualization --> room
```

`room` and `constants` depend on nothing, and nothing depends on `main`. Dependencies only point "down", so there are no cycles between modules.

## Core data types

[`Room`](../src/room.rs#L1-L8):

```rust
pub struct Room {
    pub width: i32,
    pub height: i32,
    pub x: i32,
    pub y: i32,
    pub id: usize,
}
```

[`Edge`](../src/edge.rs#L6-L11):

```rust
pub struct Edge {
    pub weight: i32,
    pub Ivertex1: usize,
    pub Ivertex2: usize,
}
```

`x` and `y` are the top-left corner, in tiles. `id` is the room's index in the rooms `Vec`, and `Ivertex1` / `Ivertex2` are room ids. Because `id` equals the index, an edge can look up its rooms with `rooms[id]` directly. This only holds as long as rooms are never removed or reordered after generation.

## Complexity (n = number of rooms, max 20)

| Function | Cost | At n = 20 |
|---|---|---|
| [`generate_rooms`](../src/room_generation.rs#L24-L47) | O(attempts · n) | ≤ 1000 × 20 overlap checks |
| [`validate_rooms`](../src/validation.rs#L4-L32) | O(n²) | 190 pair checks |
| [`generate_edges`](../src/edge.rs#L12-L25) | O(n²) | 190 edges |
| [`build_tree`](../src/tree.rs#L4-L29) | O(n · E) = O(n³) on a complete graph | 19 × 190 ≈ 3600 edge checks |

All are trivial at this size. `build_tree` is the one that would need a priority queue if room counts grow a lot.
