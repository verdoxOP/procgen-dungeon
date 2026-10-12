# procgen_dungeon (Rust)

The Rust half of the procedural dungeon generator for a 2D roguelike in the style of *The Binding of Isaac* and *Enter the Gungeon*. This crate generates and validates the dungeon data. Gameplay and rendering live in the Godot project (`GoDot-Project/`). A second generator in C# (`Algorithms/csharp/`) is built separately so both implementations can be compared in the report.

The generator runs entirely without Godot. The end goal is:

```
Rust generator → validated dungeon data → JSON → Godot
```

📖 **Full documentation:** [docs/](docs/README.md): architecture, every module, validation rules, design decisions, theory and roadmap.

## Contents

- [Current status](#current-status)
- [Requirements](#requirements)
- [Running](#running)
- [How it works](#how-it-works)
- [Validation rules](#validation-rules)
- [Key design decisions](#key-design-decisions)
- [Project structure](#project-structure)
- [Configuration](#configuration)
- [Planned pipeline and scope](#planned-pipeline-and-scope)
- [Known issues](#known-issues)

## Current status

| Stage | Status | Code |
|---|---|---|
| Seeded, deterministic RNG | ✅ done | [`main.rs` L23–30](src/main.rs#L23-L30) |
| Room generation (random size and position, no overlap) | ✅ done | [`room_generation.rs`](src/room_generation.rs) |
| Room validation + retry loop | ✅ done | [`validation.rs`](src/validation.rs), [`main.rs` L55–61](src/main.rs#L55-L61) |
| Candidate edges (complete graph, random weights) | ✅ done | [`edge.rs`](src/edge.rs) |
| Backbone / spanning tree with Prim's algorithm | ✅ done | [`tree.rs`](src/tree.rs) |
| ASCII grid visualisation of rooms | ✅ done | [`grid.rs`](src/grid.rs) |
| Graphviz visualisation of the tree | ✅ done | [`tree_visualization.rs`](src/tree_visualization.rs) |
| Adjacency list from the tree | ⏳ next | |
| BFS: start room / end room | ⏳ planned | |
| Backbone validation | ⏳ planned | |
| Door walls (derived from relative room positions) | ⏳ planned | |
| Corridors (extra hidden edges that create cycles) | ⏳ planned | |
| Population + population validation | ⏳ planned | |
| JSON export (serde) | ⏳ planned | |
| Unit tests | ⏳ planned | |

## Requirements

- Rust (edition 2024) with Cargo
- Dependencies (see [`Cargo.toml`](Cargo.toml)): `rand 0.9`, `rand_pcg 0.9`
- Optional, for the tree visualisation:
  - [Graphviz](https://graphviz.org/) (`dot` command) to render `tree.png`
  - [`chafa`](https://hpjansson.org/chafa/) to show the PNG as text in a terminal, **or** the Kitty terminal (uses `kitty +kitten icat`)

Without Graphviz the program still works and still writes `tree.dot`.

## Running

From this folder:

```sh
cargo run
```

The program asks for a seed:

```
Enter a seed for the game:
42
```

The same seed always produces the same dungeon. See [Getting started](docs/getting-started.md) for how to read the output.

### Output

1. Room generation stats, e.g. `Generated 18 rooms in 35 attempts`
2. Validation result and number of generation attempts
3. The details of every room (id, size, position)
4. A 100×100 ASCII grid where each room is drawn with its id (`0`–`9`, then `a`–`z`); `.` is empty space
5. `tree.dot` and `tree.png` in the current working directory: the spanning tree, with each room labelled with its size and position and each edge labelled with its weight

## How it works

### 1. Seeded RNG

The seed is read from stdin and used to create a `Pcg32` ([`main.rs` L23–30](src/main.rs#L23-L30)). Every random choice in the pipeline comes from this single RNG, which is passed along as `&mut`, so a seed fully determines the result. Rooms and edges are stored in `Vec`s (not `HashMap`s) so iteration order is also deterministic.

### 2. Room generation ([`room_generation.rs`](src/room_generation.rs))

- [`generate_room`](src/room_generation.rs#L11-L22) picks a random width and height and then a random position where the room still fits inside the map.
- [`generate_rooms`](src/room_generation.rs#L24-L47) picks a target room count and keeps generating rooms until the target is reached or `max_attempts` placement attempts are used up. A room that overlaps an existing room is thrown away ([L34–36](src/room_generation.rs#L34-L36)). Accepted rooms get `id = index in the Vec` ([L39–41](src/room_generation.rs#L39-L41)).
- Rooms may touch, but not overlap.

Rooms use a **tile-based** coordinate system: `x`, `y`, `width` and `height` are in tiles, not pixels. Godot translates tiles into world positions.

### 3. Room validation ([`validation.rs`](src/validation.rs), [`room.rs`](src/room.rs))

[`validate_rooms`](src/validation.rs#L4-L32) rejects a set of rooms when:

- there are fewer than `min_room_count` rooms ([L5–11](src/validation.rs#L5-L11)),
- a room is smaller than the minimum width/height ([L13–18](src/validation.rs#L13-L18)),
- any pair of rooms overlaps ([L20–29](src/validation.rs#L20-L29), using [`Room::room_overlap_check`](src/room.rs#L11-L21)).

`main` regenerates the whole set until it is valid, with at most `MAX_GENERATION_ATTEMPTS` tries ([`main.rs` L55–61](src/main.rs#L55-L61)).

### 4. Candidate edges ([`edge.rs`](src/edge.rs))

[`generate_edges`](src/edge.rs#L12-L25) connects every pair of rooms (a complete graph), so `n` rooms give `n·(n−1)/2` edges (12 rooms → 66 edges). Each edge gets a **random weight** from 1 to 100 ([L17](src/edge.rs#L17)).

### 5. Backbone: Prim's algorithm ([`tree.rs`](src/tree.rs))

[`build_tree`](src/tree.rs#L4-L29) builds a spanning tree, which becomes the backbone of the dungeon (the doors).

- Start with room `0` marked as visited ([L5–6](src/tree.rs#L5-L6)).
- Repeat until the tree has `n − 1` edges ([L9](src/tree.rs#L9)):
  - look through **all** edges and pick the cheapest one where exactly one end is visited ([L13](src/tree.rs#L13): `visited[a] ^ visited[b]`), i.e. an edge from the visited part of the dungeon to a new room,
  - mark both ends visited and add the edge to the tree ([L20–25](src/tree.rs#L20-L25)).

The result is a tree: every room is reachable, there are no cycles, and there is exactly one path between any two rooms. See [Graph and backbone](docs/graph.md) for a worked example.

### 6. Visualisation ([`grid.rs`](src/grid.rs), [`tree_visualization.rs`](src/tree_visualization.rs))

- [`Grid`](src/grid.rs#L6-L10) is a 2D `Vec<Vec<char>>` that rooms are drawn into ([`draw_room`](src/grid.rs#L22-L32)) for a quick visual check of placement and overlap.
- [`visualize_tree_in_graph_form`](src/tree_visualization.rs#L5-L53) writes the tree as a Graphviz `.dot` file, renders it to `tree.png`, and tries to show it in the terminal (Kitty image protocol, or `chafa` as a text fallback, which also works inside (Neo)Vim terminals).

## Validation rules

Rules from the brainstorm document. Full list with status: [Validation rules](docs/validation-rules.md).

| Rule | Description | Status |
|---|---|---|
| VR-01 | rooms must be at least a minimum size | ✅ [`validation.rs` L13–18](src/validation.rs#L13-L18) |
| VR-02 | rooms may not overlap | ✅ [`validation.rs` L20–29](src/validation.rs#L20-L29) |
| VR-03 | at least N rooms must be generated | ✅ [`validation.rs` L5–11](src/validation.rs#L5-L11) |
| VR-04 | minimum room width and height are configurable | ✅ [`constants.rs` L6–7](src/constants.rs#L6-L7) |
| PV-01 – PV-07 | population rules (enemy/health minimums, per-room limits, walkable tiles, reachability, safe start room) | ⏳ planned |
| CV | corridors may not skip most of the stage | ⏳ planned |

## Key design decisions

The full reasoning, including the options that were rejected, is in [Design decisions](docs/design-decisions.md).

| Decision | Why |
|---|---|
| **One room = one screen.** A door loads the next room directly. No hallways, no minimap. | like *Binding of Isaac*; keeps generation and rendering simple |
| **Rooms are generic** (option 2 from the brainstorm); only the dungeon knows which room is start/end | the spawnables in a room decide what kind of room it is, which adds randomness |
| **Every pair of rooms is a candidate edge** | rooms are separate screens, so any two rooms could share a door |
| **Random edge weights** instead of distance | the player never walks between rooms, so distance means nothing; random weights give a different tree per seed |
| **Prim** for the spanning tree, not Kruskal | understood and worked out by hand; Kruskal needs Union-Find, which there's no time to research |
| **`Vec` instead of `HashMap`** | `HashMap` iteration order changes between runs, which would break determinism |
| **Adjacency list** as the final graph representation | the graph is sparse and validation keeps asking "which rooms neighbour this room?" |
| **Start = room 0, end = furthest room by BFS** | furthest = most doors away from the start |
| **Door wall from relative room positions** | if room 2 is right of room 1, the door is on room 1's right wall and room 2's left wall; Godot needs this in the JSON |
| **Corridors are hidden extra edges** | alternate routes / shortcuts; the backbone must be playable without them |

## Project structure

```
procgen_dungeon/
├── Cargo.toml
├── README.md
├── docs/                       developer documentation
└── src/
    ├── main.rs                 entry point: seed input, pipeline, printing
    ├── constants.rs            tunable generation parameters
    ├── room.rs                 Room struct + overlap check
    ├── room_generation.rs      generate_room / generate_rooms
    ├── validation.rs           validate_rooms
    ├── edge.rs                 Edge struct + generate_edges (complete graph)
    ├── tree.rs                 build_tree (Prim's algorithm)
    ├── grid.rs                 ASCII grid visualisation
    └── tree_visualization.rs   Graphviz export + terminal preview
```

## Configuration

All values are in [`constants.rs`](src/constants.rs). Details and the effect of changing them: [Configuration](docs/configuration.md).

| Constant | Value | Meaning |
|---|---|---|
| `min_room_count` | 8 | minimum rooms in a valid dungeon |
| `max_room_count` | 20 | maximum rooms that will be attempted |
| `max_attempts` | 1000 | placement attempts per generation |
| `MAX_GENERATION_ATTEMPTS` | 10 | full regenerations before giving up |
| `MIN_ROOM_WIDTH` / `MIN_ROOM_HEIGHT` | 8 | minimum room size |
| `MAX_ROOM_WIDTH` / `MAX_ROOM_HEIGHT` | 20 | maximum room size |
| `MAP_WIDTH` / `MAP_HEIGHT` | 100 | map size in tiles |

## Planned pipeline and scope

Each stage validates its own output and retries locally, with a maximum number of attempts.

```
generate rooms → validate rooms
→ build graph / backbone (Prim) → validate backbone
→ optional corridors → validate corridors
→ populate → validate population
→ serialize to JSON → Godot
```

| Level | Includes |
|---|---|
| **MVP** | room generation, backbone, validation, doors, population, seeded generation, Rust → JSON → Godot, tests |
| **Nice to have** | smarter population, locked doors and keys, advanced corridors, benchmarking |
| **Stretch** | infinite / chunk-based generation, progression systems, multithreading |

The generator does **not** initially need infinite generation, chunk streaming, multithreading, complex room templates or advanced optimisation.

## Known issues

Full list: [Roadmap and known issues](docs/roadmap.md#known-issues).

- The edge print loop prints `edges.len()` once per edge instead of printing each edge ([`main.rs` L66–68](src/main.rs#L66-L68)).
- In `build_tree`, the loop that marks the chosen edge as visited runs only once and shadows `edge` ([`tree.rs` L20–24](src/tree.rs#L20-L24)).
- If all `MAX_GENERATION_ATTEMPTS` fail, the program continues with an invalid room set ([`main.rs` L58–61](src/main.rs#L58-L61)).
- `build_tree` starts with `101` as the "cheapest weight" ([`tree.rs` L11](src/tree.rs#L11)), which only works because edge weights are `1..=100`.
- `mst` is unused ([`constants.rs` L3](src/constants.rs#L3)).
- No unit tests yet.
