# Graph and backbone

[← Documentation home](README.md)

Covers [`Edge.cs`](../procgen-csharp/Edge.cs) and [`EdgeGeneration.cs`](../procgen-csharp/EdgeGeneration.cs). The backbone (Prim's algorithm) will be added here once it is ported.

Graph theory background (vertices, edges, trees, spanning trees, Prim vs Kruskal) and a worked example by hand are in [Rust → Graph and backbone](../../../rust/procgen_dungeon/docs/graph.md) and [Rust → Theory](../../../rust/procgen_dungeon/docs/theory.md).

## The graph

| Graph term | In the generator |
|---|---|
| vertex | a room (identified by its `Id`) |
| edge | a possible door between two rooms |
| weight | a random number from 1 to 100, used by Prim to pick the backbone |

## `Edge` ([`Edge.cs` L5–15](../procgen-csharp/Edge.cs#L5-L15))

| Property | Type | Meaning | Rust name |
|---|---|---|---|
| `Weight` | `int` | random cost, 1–100 | `weight` |
| `RoomA` | `int` | id of the first room | `Ivertex1` |
| `RoomB` | `int` | id of the second room | `Ivertex2` |

The graph is **undirected**: an edge from room 2 to room 5 is the same connection as from 5 to 2, so each pair is stored once, with `RoomA < RoomB`. The names `RoomA` / `RoomB` match how the Rust door code (`door.rs`) names the two rooms.

`ToString()` gives `Edge 0-1: weight 63`, used for the log output and the verification.

## Edge generation: `GenerateEdges(rng, rooms)` ([`EdgeGeneration.cs` L10–27](../procgen-csharp/EdgeGeneration.cs#L10-L27))

Connects **every pair of rooms**, so the result is a **complete graph**:

1. loop `i` over all rooms ([L13](../procgen-csharp/EdgeGeneration.cs#L13)),
2. loop `j` from `i + 1` ([L15](../procgen-csharp/EdgeGeneration.cs#L15)), so each pair appears once and no room is paired with itself,
3. give the pair a random weight in `MinWeight..=MaxWeight` ([L19](../procgen-csharp/EdgeGeneration.cs#L19)).

`n` rooms give `n · (n − 1) / 2` edges:

| Rooms | Edges |
|---|---|
| 8 (minimum) | 28 |
| 18 (seed 42) | 153 |
| 20 (maximum) | 190 |

**The order is fixed:** pairs are visited as `(0,1), (0,2), …, (0,n−1), (1,2), …`, exactly like `edge.rs`, and each pair draws one random number. A different loop order would assign the same weights to different pairs, and Prim would build a different tree than Rust.

Edges are generated right after the rooms are valid ([`Program.cs` L38](../procgen-csharp/Program.cs#L38)), with the same `rng`, so the weights continue the same random sequence as in Rust.

### Why every pair, and why random weights

Rooms are separate screens, so any two rooms could share a door; and because the player never walks between rooms, the physical distance between them doesn't matter. Random weights give a different backbone per seed. The full reasoning is in [Rust → Design decisions → Candidate edges and weights](../../../rust/procgen_dungeon/docs/design-decisions.md#candidate-edges-and-weights).

### Weight range constants

In Rust the range `1..=100` is written directly in `edge.rs`, and `tree.rs` uses `101` as its starting "cheapest weight". In C# the range is named: [`EdgeGeneration.MinWeight` and `MaxWeight`](../procgen-csharp/EdgeGeneration.cs#L7-L8). When Prim is ported it can use `MaxWeight + 1` instead of a magic `101`, so the two can't get out of sync.

## Backbone: Prim's algorithm

⏳ Next step. Rust: [`tree.rs`](../../../rust/procgen_dungeon/src/tree.rs).
