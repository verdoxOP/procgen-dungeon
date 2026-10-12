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
cargo run
```

The program reads a seed from stdin ([`main.rs` L23–30](../src/main.rs#L23-L30)):

```
Enter a seed for the game:
42
```

The seed must be a whole number that fits in a `u64`. Anything else makes the program panic with `Please enter a valid number` ([L29](../src/main.rs#L29)).

You can also pipe the seed in:

```sh
echo 42 | cargo run
```

## Reading the output

In order:

| # | Output | Printed by |
|---|---|---|
| 1 | `Generated 18 rooms in 35 attempts` (once per generation attempt) | [`room_generation.rs` L45](../src/room_generation.rs#L45) |
| 2 | validation messages if a room set fails | [`validation.rs`](../src/validation.rs) |
| 3 | edge count, printed once per edge (see [known issues](roadmap.md#known-issues)) | [`main.rs` L66–68](../src/main.rs#L66-L68) |
| 4 | `rooms true after N generation attempts` | [`main.rs` L70–74](../src/main.rs#L70-L74) |
| 5 | details of every room | [`main.rs` L76–81](../src/main.rs#L76-L81) |
| 6 | ASCII grid of the map (see [Visualisation](visualisation.md)) | [`main.rs` L83–89](../src/main.rs#L83-L89) |
| 7 | `tree.dot` / `tree.png` + terminal preview | [`main.rs` L90–91](../src/main.rs#L90-L91) |

Example (seed `42`):

```
Generated 18 rooms in 35 attempts
rooms true after 1 generation attempts
Checking room 0
Room details: Room { width: 18, height: 9, x: 81, y: 33, id: 0 }
Checking room 1
Room details: Room { width: 16, height: 18, x: 27, y: 76, id: 1 }
...
```

## Determinism check

Run the same seed twice and compare the output:

```sh
echo 42 | cargo run > a.txt
echo 42 | cargo run > b.txt
diff a.txt b.txt
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
