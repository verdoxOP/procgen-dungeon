# Roadmap and known issues

[← Documentation home](README.md)

## Progress

| Stage | Status | Code |
|---|---|---|
| Seeded, deterministic RNG | ✅ done | `--seed <int>` CLI arg, [`main.rs` L32–58](../src/main.rs#L32-L58) |
| Room generation | ✅ done | [`room_generation.rs`](../src/room_generation.rs) |
| Room validation + retry loop | ✅ done | [`validation.rs`](../src/validation.rs) |
| Candidate edges (complete graph) | ✅ done | [`edge.rs`](../src/edge.rs) |
| Backbone with Prim | ✅ done | [`tree.rs`](../src/tree.rs) |
| ASCII grid + Graphviz visualisation | ✅ done | [`grid.rs`](../src/grid.rs), [`tree_visualization.rs`](../src/tree_visualization.rs) |
| Door walls | ✅ done | [`door.rs`](../src/door.rs) |
| BFS: start / end room | ✅ done | [`bfs.rs`](../src/bfs.rs) |
| Population + population validation | ✅ done | [`population.rs`](../src/population.rs) |
| JSON export (serde), printed to stdout | ✅ done | [`dungeon_json.rs`](../src/dungeon_json.rs) |
| Godot command-line contract (`--seed`, JSON-only stdout, logs on stderr) | ✅ done | [`main.rs` L28–31](../src/main.rs#L28-L31) |
| Adjacency list from the tree | ⏳ next | |
| Backbone validation | ⏳ planned | |
| Corridors + corridor validation | ❌ cut — dropped from scope, see [Design decisions → Corridors](design-decisions.md#corridors) |
| Unit tests | ⏳ planned | |

## Timeline

| Week | Focus |
|---|---|
| 1 | research, rooms, room validation, edges ✅ |
| 2 | Prim ✅, BFS start/end ✅, door walls ✅ |
| 3 | population + PV rules ✅, decided to cut corridors to stay on schedule |
| 4 | JSON export ✅, Godot CLI contract ✅, tests, report |

## Scope

| Level | Includes |
|---|---|
| **MVP** | room generation, backbone, validation, doors, population, seeded generation, Rust → JSON → Godot, tests |
| **Nice to have** | smarter population, locked doors and keys, benchmarking |
| **Cut** | corridors — dropped due to the deadline |
| **Stretch** | infinite / chunk-based generation, progression systems, multithreading |

## Open questions

| Question | Context |
|---|---|
| Which wall gets the door for diagonal neighbours? | [Design decisions → Doors](design-decisions.md#doors) |
| Is there a maximum number of doors per room? | a spanning tree doesn't limit it |
| How do we stop the dungeon becoming one long line? | random spanning trees can still produce long chains; measure it before deciding |
| Explicit seed-based tie-break, or keep `Vec` order? | [Design decisions → Tie-breaking](design-decisions.md#tie-breaking) |
| What happens when all generation attempts fail? | currently exits with code `1`, see [Known issues](#known-issues) |
| Which parameters make progress measurable? | feedback from Patrick, 12 Oct |
| One room = one screen: confirmed with the Godot side? | [Design decisions → Game structure](design-decisions.md#game-structure) |

~~How is "skipping the stage" measured for corridors (CV)?~~ moot now that corridors are cut from scope.

## Known issues

| Where | Issue |
|---|---|
| [`main.rs`](../src/main.rs) | the edge print loop prints `edges.len()` once per edge instead of printing each edge |
| [`tree.rs` L20–24](../src/tree.rs#L20-L24) | the "mark visited" loop runs exactly once and shadows `edge` (unused-variable warning) |
| [`tree.rs` L11](../src/tree.rs#L11) | starting weight `101` is tied to the `1..=100` weight range in [`edge.rs` L17](../src/edge.rs#L17) |
| [`tree.rs` L10](../src/tree.rs#L10) | if no crossing edge is found, edge 0 would be pushed again (can't happen on a complete graph) |
| [`tree.rs` L9](../src/tree.rs#L9) | `rooms.len() - 1` underflows if there are 0 rooms |
| [`constants.rs` L3](../src/constants.rs#L3), [L12](../src/constants.rs#L12) | `mst` is unused, and its comment ("the fastest route to the exit") doesn't describe an MST |
| [`constants.rs` L1–4](../src/constants.rs#L1-L4), [`edge.rs` L9–10](../src/edge.rs#L9-L10) | naming warnings: lowercase constants, `Ivertex1` / `Ivertex2` not snake_case |
| [`population.rs`](../src/population.rs) | PV-01 / PV-02 are only checked as "at least one non-hostile pickup exists", not as separate `min_enemies` / `min_health` counts |
| tests | no `#[test]` functions yet |

## Test ideas

Things that are easy to check without Godot:

| Test | Checks |
|---|---|
| every room fits inside the map | room generation |
| no two rooms overlap | VR-02 |
| touching rooms don't count as overlap | `room_overlap_check` |
| room ids equal their index | `generate_rooms` |
| `generate_edges` returns `n · (n − 1) / 2` edges, no self-loops | complete graph |
| `build_tree` returns `n − 1` edges | tree size |
| `build_tree` reaches every room | connected |
| the same seed gives the same rooms and tree twice | determinism |
| two different seeds give different trees | variety |
