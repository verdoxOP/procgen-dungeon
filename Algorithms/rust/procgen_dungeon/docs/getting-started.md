# Getting started

[← Documentation home](README.md)

## Requirements

| Tool | Needed for | Required? |
|---|---|---|
| Rust + Cargo (edition 2024) | building and running | yes |
| Graphviz (`dot`) | rendering `tree.png` | optional |
| `chafa` | showing `tree.png` as text in a terminal | optional |
| Kitty terminal | showing `tree.png` as a real image | optional |

Dependencies (from [`Cargo.toml`](../Cargo.toml)): `rand 0.9`, `rand_pcg 0.9`.

## Build and run

From `Algorithms/rust/procgen_dungeon/`:

```sh
cargo build
cargo run -- --seed 42
```

The seed is a `--seed <int>` CLI argument, not a stdin prompt ([`parse_seed_arg`, `main.rs` L32–46](../src/main.rs#L32-L46)) — this is the command-line contract the Godot game calls the built binary with (`GeneratorRunner.gd`). A missing or non-numeric seed prints a usage/error message to stderr and exits with code `2`.

## Reading the output

**stdout carries only the final dungeon JSON.** Everything else below goes to **stderr**, so stdout can be piped straight into a file or into Godot without stripping debug text:

| # | Output | Stream | Printed by |
|---|---|---|---|
| 1 | `Generated 18 rooms in 35 attempts` (once per generation attempt) | stderr | [`room_generation.rs`](../src/room_generation.rs) |
| 2 | validation messages if a room set fails | stderr | [`validation.rs`](../src/validation.rs) |
| 3 | edge count, printed once per edge (see [known issues](roadmap.md#known-issues)) | stderr | [`main.rs`](../src/main.rs) |
| 4 | `rooms valid after N generation attempts` | stderr | [`main.rs`](../src/main.rs) |
| 5 | details of every room | stderr | [`main.rs`](../src/main.rs) |
| 6 | ASCII grid of the map (see [Visualisation](visualisation.md)) | stderr | [`grid.rs`](../src/grid.rs) |
| 7 | each door, each room's BFS distance from the start, the chosen end room | stderr | [`main.rs`](../src/main.rs) |
| 8 | each room's populated kind (start/end/enemy/item/empty) | stderr | [`main.rs`](../src/main.rs) |
| 9 | `tree.dot` / `tree.png` written to disk + terminal preview | — | [`main.rs`](../src/main.rs) |
| 10 | the dungeon JSON (`format_version`, `seed`, `rooms`, `start_room`, `end_room`, `doors`, `corridors` (always `[]` — see [Design decisions → Corridors](design-decisions.md#corridors)), `spawnables`) | **stdout** | [`dungeon_json.rs`](../src/dungeon_json.rs) |

Exit codes: `0` success, `1` room generation or population validation failed, `2` bad/missing `--seed`.

To get only the JSON (what Godot does):

```sh
cargo run -- --seed 42 2>/dev/null
```

## Determinism check

Run the same seed twice and compare the output:

```sh
cargo run -- --seed 42 2>/dev/null > a.json
cargo run -- --seed 42 2>/dev/null > b.json
diff a.json b.json
```

No diff means generation is deterministic for that seed. This works because:

- every random value comes from one `Pcg32` seeded with the input,
- that RNG is passed as `&mut` through every step, in a fixed order,
- rooms and edges are kept in `Vec`s, which always iterate in the same order.

## Optional: Graphviz preview

- Arch / CachyOS: `sudo pacman -S graphviz chafa`
- Debian / Ubuntu: `sudo apt install graphviz chafa`
- macOS: `brew install graphviz chafa`

If `dot` is missing, the program prints `Could not run graphviz, tree.dot was still written` and carries on. You can render the file later with:

```sh
dot -Tpng tree.dot -o tree.png
```
