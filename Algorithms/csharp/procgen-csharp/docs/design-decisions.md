# Design decisions

[← Documentation home](README.md)

The design of the generator itself (one room = one screen, generic rooms, random edge weights, Prim, BFS end room, doors on walls, corridors) is shared with the Rust version and explained in [Rust → Design decisions](../../../rust/procgen_dungeon/docs/design-decisions.md). This page covers the decisions that are specific to the C# port.

Legend: ✅ decided · ❓ open

## Contents

- [Port, don't redesign](#port-dont-redesign)
- [Own Pcg32 instead of System.Random](#own-pcg32-instead-of-systemrandom)
- [Build in the same order as Rust](#build-in-the-same-order-as-rust)
- [Command-line contract](#command-line-contract)
- [Exit code on failure](#exit-code-on-failure)
- [C# style instead of a literal translation](#c-style-instead-of-a-literal-translation)
- [Target framework](#target-framework)

## Port, don't redesign

| | Decision |
|---|---|
| ✅ | **The C# generator uses the same algorithm as the Rust generator.** |

**Why:** the research compares languages. If the algorithms differed too, a difference in results could come from either one, and the comparison would say nothing about the language.

## Own Pcg32 instead of System.Random

| Option | Pro | Con |
|---|---|---|
| `System.Random` | built in, no extra code | different numbers → different dungeons → unequal work |
| **port `Pcg32` from Rust** | identical dungeons per seed, output can be checked against Rust | must copy seeding and range sampling exactly |

| | Decision |
|---|---|
| ✅ | **Port `Pcg32`, including `seed_from_u64` and `random_range`.** |

**Why:** with identical dungeons both languages do exactly the same work, and every porting step can be verified by comparing output. Details: [Random number generator](rng.md).

## Build in the same order as Rust

| | Decision |
|---|---|
| ✅ | **One class at a time, in the order the Rust generator was built** (seed → rooms → validation → edges → Prim → doors → JSON → BFS), verified against Rust after each step. |

**Why:** a mismatch is easy to find when only one step changed. It also keeps the documentation of both generators parallel. See [Architecture → Porting approach](architecture.md#porting-approach).

## Command-line contract

| Rust (current) | C# |
|---|---|
| seed from stdin (`Enter a seed for the game:`) | `--seed <int>` argument |
| logs on stdout | logs on stderr |
| `dungeon.json` file | JSON on stdout (planned) |

| | Decision |
|---|---|
| ✅ | **Follow the contract the Godot game expects from every generator.** |

**Why:** the game runs generators with `OS.execute()` and reads the JSON from stdout. Following the contract from the start means the C# generator can be dropped into the game's `generators/` folder without changes. The Rust generator still has to be updated to the contract (on the team board).

## Exit code on failure

| | Decision |
|---|---|
| ✅ | **Exit with code 1 when no valid rooms are found after `MaxGenerationAttempts`.** |

Rust currently continues with the invalid room set (in its known issues). The contract says exit 1 = generation failed, so the game can show an error instead of loading a broken dungeon. This doesn't change any dungeon that *is* valid, so the comparison stays fair.

## C# style instead of a literal translation

| | Decision |
|---|---|
| ✅ | **Same logic and same order of random calls, but written as normal C#.** |

| Rust | C# |
|---|---|
| free functions in modules | `static` classes (`RoomGeneration`, `Validation`) |
| `struct Room` with public fields | `class Room` with properties; position and size are `init`-only |
| `room_overlap_check` | `Overlaps` |
| `Vec<Room>` | `List<Room>` |
| `iter().any(...)` | LINQ `Any(...)` |
| `usize` ids | `int` ids |
| `SCREAMING_CASE` / `snake_case` constants | `PascalCase` constants |

**Why:** the C# version should look like C# a developer would write, so the comparison reflects each language as it's normally used, not a Rust program in C# syntax. None of these changes affect the random calls.

## Target framework

| | Decision |
|---|---|
| ✅ | **`net8.0`** (kept from the original project) |
| ❓ | Whether to measure with a newer runtime or as a native AOT build for the comparison. |

.NET 8 is a long-term support release. Native AOT would make start-up faster, which matters for the "process time" the game measures, but not for the generator's own timing (`stats`).
