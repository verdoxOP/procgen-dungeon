# procgen_dungeon documentation

Developer documentation for the Rust dungeon generator. For a quick overview and how to run it, see the [crate README](../README.md).

All code references link to the exact lines in [`src/`](../src/).

## Pages

| Page | What's in it |
|---|---|
| [Getting started](getting-started.md) | Install, run, read the output, check determinism |
| [Architecture](architecture.md) | Requirements, pipeline, data flow, modules and dependencies |
| [Rooms](rooms.md) | `Room`, coordinate system, overlap check, room generation and validation |
| [Graph and backbone](graph.md) | `Edge`, the complete graph, Prim's algorithm with a worked example |
| [Visualisation](visualisation.md) | ASCII grid and Graphviz tree output |
| [Configuration](configuration.md) | Every constant and what changing it does |
| [Validation rules](validation-rules.md) | VR, PV and CV rules from the brainstorm, with status and code |
| [Design decisions](design-decisions.md) | Every decision, the options considered, and why |
| [Theory](theory.md) | Graph theory background: graphs, trees, representations, BFS/DFS, Prim/Kruskal |
| [Roadmap and known issues](roadmap.md) | Progress, timeline, open questions, known bugs, test ideas |
| [Test plan](test-plan.md) | What I test, why, expected results, and what I don't test (Dutch) |
| [Test report](test-report.md) | Results of `cargo test`, findings and known issues (Dutch) |
| [Glossary](glossary.md) | Terms in English and Dutch |

## Code at a glance

| File | Responsibility | Main items |
|---|---|---|
| [`main.rs`](../src/main.rs) | entry point and pipeline | `main`, `parse_seed_arg` |
| [`constants.rs`](../src/constants.rs) | tunable parameters | all constants |
| [`room.rs`](../src/room.rs) | room data type | [`Room`](../src/room.rs#L1-L8), [`room_overlap_check`](../src/room.rs#L11-L21) |
| [`room_generation.rs`](../src/room_generation.rs) | placing rooms | [`generate_room`](../src/room_generation.rs#L11-L22), [`generate_rooms`](../src/room_generation.rs#L24-L47) |
| [`validation.rs`](../src/validation.rs) | checking rooms | [`validate_rooms`](../src/validation.rs#L4-L32) |
| [`edge.rs`](../src/edge.rs) | candidate connections | [`Edge`](../src/edge.rs#L6-L11), [`generate_edges`](../src/edge.rs#L12-L25) |
| [`tree.rs`](../src/tree.rs) | backbone | [`build_tree`](../src/tree.rs#L4-L29) |
| [`door.rs`](../src/door.rs) | doors from the backbone | `Door`, `Wall`, `generate_doors` |
| [`bfs.rs`](../src/bfs.rs) | start/end room | `room_distances`, `furthest_room` |
| [`population.rs`](../src/population.rs) | spawning enemies and pickups | `RoomKind`, `Spawnable`, `populate_dungeon`, `validate_population` |
| [`dungeon_json.rs`](../src/dungeon_json.rs) | exported JSON shape | `DungeonJson`, `build_dungeon_json` |
| [`grid.rs`](../src/grid.rs) | ASCII debug view | [`Grid`](../src/grid.rs#L6-L10), [`print_grid`](../src/grid.rs#L35-L40) |
| [`tree_visualization.rs`](../src/tree_visualization.rs) | Graphviz debug view | [`visualize_tree_in_graph_form`](../src/tree_visualization.rs#L5-L53) |

Corridors are cut from scope (deadline) — there is no `corridor.rs` module; `corridors` stays an empty array in the exported JSON.
