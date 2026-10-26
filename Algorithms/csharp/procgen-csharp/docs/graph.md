# Graph and backbone

[← Documentation home](README.md)

Covers [`Edge.cs`](../procgen-csharp/Edge.cs), [`EdgeGeneration.cs`](../procgen-csharp/EdgeGeneration.cs), [`SpanningTree.cs`](../procgen-csharp/SpanningTree.cs), [`Door.cs`](../procgen-csharp/Door.cs) and [`DoorGeneration.cs`](../procgen-csharp/DoorGeneration.cs).

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

In Rust the range `1..=100` is written directly in `edge.rs`, and `tree.rs` uses `101` as its starting "cheapest weight". In C# the range is named: [`EdgeGeneration.MinWeight` and `MaxWeight`](../procgen-csharp/EdgeGeneration.cs#L7-L8). Prim doesn't need a `101` at all (see below), so the two can't get out of sync.

## Backbone: Prim's algorithm ([`SpanningTree.cs`](../procgen-csharp/SpanningTree.cs))

### `BuildTree(edges, roomCount)` ([L8–40](../procgen-csharp/SpanningTree.cs#L8-L40))

Builds a **spanning tree** over the complete graph. Its edges become the doors: the **backbone** of the dungeon. Same steps as [`tree.rs`](../../../rust/procgen_dungeon/src/tree.rs):

1. Room `0` is visited ([L11](../procgen-csharp/SpanningTree.cs#L11)).
2. Until the tree has `roomCount − 1` edges ([L14](../procgen-csharp/SpanningTree.cs#L14)):
   - go through **all** edges in list order and keep the cheapest one where **exactly one** end is visited ([L19–26](../procgen-csharp/SpanningTree.cs#L19-L26)); that is an edge from the part of the dungeon already connected to a new room. `visited[a] ^ visited[b]` (xor) is `true` only when one side is visited and the other isn't,
   - mark both ends visited and add the edge to the tree ([L34–36](../procgen-csharp/SpanningTree.cs#L34-L36)).

The result: every room is reachable, there are no cycles, and there is exactly one path between any two rooms. Seed 42: 18 rooms → 17 tree edges, out of 153 candidates.

Prim draws **no random numbers**; it only uses the weights. Because the weights and their order are identical to Rust, the tree is too.

### Tie-break

Weights only go from 1 to 100, so equal weights are common: 87 of the first 100 seeds have a tree with at least two edges of the same weight. When two candidate edges are equally cheap, the **first one in the edge list wins**, because only a strictly lower weight (`<`) replaces the current choice ([L22](../procgen-csharp/SpanningTree.cs#L22)). This is the same rule as in Rust, and it matters: `<=` would pick the last one and could build a different tree. See [Rust → Design decisions → Tie-breaking](../../../rust/procgen_dungeon/docs/design-decisions.md#tie-breaking).

### Differences from `tree.rs` (same result)

| `tree.rs` | C# | Why |
|---|---|---|
| starts the search with `weight = 101` and `index_edges = 0` | starts with "no edge yet" (`cheapest = null`) | no magic number that has to stay above `MaxWeight`; picks the same edge |
| marks the chosen edge visited inside a loop that runs exactly once ([L20–24](../../../rust/procgen_dungeon/src/tree.rs#L20-L24)) | two plain assignments | same effect, easier to read (the Rust loop is in its known issues) |
| if no crossing edge is found, pushes edge 0 again | throws `InvalidOperationException` ([L29–32](../procgen-csharp/SpanningTree.cs#L29-L32)) | can't happen on a complete graph; if it ever did, failing loudly beats a silently wrong tree |
| `rooms.len() − 1` underflows with 0 rooms | `int`, the loop just doesn't run | can't happen after validation (at least 8 rooms) |
| takes the rooms list | takes `roomCount` | Prim only needs the number of rooms |

### Complexity

Each of the `n − 1` steps scans all `n · (n − 1) / 2` edges: O(n³) on a complete graph. At 20 rooms that is 19 × 190 ≈ 3600 edge checks, which is nothing. A priority queue would only be worth it for much larger dungeons; keeping the same simple version as Rust keeps the comparison fair.

## Doors ([`Door.cs`](../procgen-csharp/Door.cs), [`DoorGeneration.cs`](../procgen-csharp/DoorGeneration.cs))

Every backbone edge becomes a **door**. The JSON only says which **wall** of each room the door is in; the game picks the exact tile itself (see the game's `FORMAT.md`). Port of [`door.rs`](../../../rust/procgen_dungeon/src/door.rs).

### `Wall` and `Door` ([`Door.cs`](../procgen-csharp/Door.cs))

| Type | Members | Rust | JSON |
|---|---|---|---|
| [`Wall`](../procgen-csharp/Door.cs#L4-L10) (enum) | `Top`, `Bottom`, `Left`, `Right` | `enum Wall` | `"top"`, `"bottom"`, `"left"`, `"right"` |
| [`Door`](../procgen-csharp/Door.cs#L14-L25) | `RoomA`, `RoomB`, `WallA`, `WallB` | `room_a`, `room_b`, `wall_a`, `wall_b` | `from`, `to`, `from_wall`, `to_wall` |

An enum instead of strings means a typo like `"rigth"` is a compile error instead of a bug in the game, the same reason Matt gives in `door.rs`.

### `EdgeToDoor(edge, rooms)` ([`DoorGeneration.cs` L14–47](../procgen-csharp/DoorGeneration.cs#L14-L47))

1. Look up both rooms by id (ids equal list indexes).
2. Compute each room's centre: `x + width / 2`, `y + height / 2` ([L21–24](../procgen-csharp/DoorGeneration.cs#L21-L24)). Integer division, like Rust's `i32`; all values are positive, so both languages round the same way.
3. `dx` and `dy` are the differences from room A's centre to room B's.
4. **The bigger difference picks the axis** ([L30–38](../procgen-csharp/DoorGeneration.cs#L30-L38)):
   - `|dx| >= |dy|`: the door is in A's **right** wall if B is to the right (`dx > 0`), otherwise in A's **left** wall,
   - otherwise: A's **bottom** wall if B is below (`dy > 0`, because `y` grows downwards), otherwise A's **top** wall.
5. Room B's door is in the **opposite** wall ([`OppositeWall`](../procgen-csharp/DoorGeneration.cs#L49-L58)).

Example: room A's centre is at (10, 10) and room B's at (40, 20). `dx = 30`, `dy = 10`, so the door is in A's right wall and B's left wall.

**Tie:** when `|dx| = |dy|` the door goes in a left or right wall, because the check is `>=`. This is Rust's rule and has to be copied exactly. In seeds 0–299 it happened for 36 of the 3839 doors. If both centres are at exactly the same spot (`dx = dy = 0`), the result is A: left, B: right, also as in Rust.

### `GenerateDoors(tree, rooms)` ([L6–9](../procgen-csharp/DoorGeneration.cs#L6-L9))

One door per tree edge, **in the same order as the tree**. That order ends up in the JSON, so it has to match Rust too. Doors draw no random numbers.

### Diagonal neighbours

Rooms are placed anywhere on the map, so two connected rooms can be far apart or diagonal from each other. The rule above always picks one wall per side, even then. Whether that's the best choice for diagonal rooms is an open question in the Rust docs: see [Rust → Design decisions → Doors](../../../rust/procgen_dungeon/docs/design-decisions.md#doors).
