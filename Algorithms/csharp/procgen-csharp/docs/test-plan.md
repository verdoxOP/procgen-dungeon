# Testplan

[← Documentation home](README.md) · [Testrapport](test-report.md)

## Doel

Ik wil aantonen dat de C#-generator doet wat hij moet doen, zonder Godot. Matt heeft voor de Rust-generator 26 unit tests geschreven ([Rust testplan](../../../rust/procgen_dungeon/docs/test-plan.md)). Ik heb die tests **één op één vertaald** naar C#: dezelfde tests, dezelfde seeds, dezelfde verwachte resultaten. Zo testen beide generators precies dezelfde eisen, en dat past bij de vergelijking: als een test in de ene taal slaagt en in de andere niet, zit er een verschil in de port.

## Testopzet

- Een apart xUnit-project, [`procgen-csharp.Tests`](../procgen-csharp.Tests), naast de generator in dezelfde solution. Rust zet tests in een `mod tests` onderaan elk bestand. In C# is een apart testproject de gewone manier: de tests komen dan niet in de generator die naar Godot gaat.
- Eén testklasse per Rust-testmodule, met dezelfde namen in PascalCase (`rooms_fit_inside_map` → `RoomsFitInsideMap`).
- Twee hulpfuncties uit `Population` (`IsInsideRoom`, `RoomAt`) zijn `internal` in plaats van `private`, en de generator geeft het testproject toegang met `InternalsVisibleTo`. De Rust-tests kunnen bij private functies omdat ze in hetzelfde bestand staan. Dit is de C#-manier om hetzelfde te doen.
- Draaien: `dotnet test` in `Algorithms/csharp/procgen-csharp`.
- **Seed-gebaseerde tests** draaien over de vaste seeds `0..200` met `Pcg32.FromSeed(seed)`, net als in Rust. De foutmelding noemt de seed, zodat een fout altijd terug te vinden is.
- Tests die een hele dungeon nodig hebben, gebruiken dezelfde retry loop als `Program.cs` (max `MaxGenerationAttempts` keer `GenerateRooms` tot `ValidateRooms` slaagt). In Rust staat die loop twee keer, in `tree.rs` en `population.rs`. In C# staat hij één keer, in [`TestDungeon.cs`](../procgen-csharp.Tests/TestDungeon.cs).
- **Handgemaakte tests** (overlap, validatie, doors, BFS) gebruiken kleine rooms die ik zelf neerzet, met dezelfde posities als in Rust.

## Wat ik test en waarom

| # | Test (C#) | Rust | Regel / eis | Seeds | Verwacht resultaat |
|---|---|---|---|---|---|
| 1 | `RoomGenerationTests.RoomsFitInsideMap` | `rooms_fit_inside_map` | rooms passen in `MapWidth` × `MapHeight` | 0..200 | geen room steekt buiten de map |
| 2 | `RoomGenerationTests.RoomsDoNotOverlap` | `rooms_do_not_overlap` | VR-02 | 0..200 | geen enkel paar rooms overlapt |
| 3a | `RoomTests.OverlappingRoomsOverlap` | `overlapping_rooms_overlap` | `Room.Overlaps` | — | twee rooms die een tile delen → `true` (beide kanten op) |
| 3b | `RoomTests.TouchingRoomsDoNotOverlap` | `touching_rooms_do_not_overlap` | `Room.Overlaps`, raken mag | — | rooms die alleen tegen elkaar aan liggen → `false` |
| 4 | `RoomGenerationTests.RoomIdIsIndex` | `room_id_is_index` | id = index in de lijst | 0..200 | `rooms[i].Id == i` |
| 5a | `ValidationTests.ValidRoomsPass` | `valid_rooms_pass` | VR-01/02/03 (controle) | — | 8 losse rooms van minimale grootte → geldig |
| 5b | `ValidationTests.TooFewRoomsFail` | `too_few_rooms_fail` | VR-03 | — | 7 rooms → ongeldig |
| 5c | `ValidationTests.TooSmallRoomsFail` | `too_small_rooms_fail` | VR-01 | — | één room te smal of te laag → ongeldig |
| 5d | `ValidationTests.OverlappingRoomsFail` | `overlapping_rooms_fail` | VR-02 | — | twee rooms over elkaar → ongeldig |
| 6 | `EdgeGenerationTests.EdgesFormCompleteGraph` | `edges_form_complete_graph` | complete graph | 0..200 | `n·(n−1)/2` edges, geen self-loops, geen dubbele paren |
| 7 | `SpanningTreeTests.TreeHasNMinus1EdgesAndReachesEveryRoom` | `tree_has_n_minus_1_edges_and_reaches_every_room` | spanning tree | 0..200 | `n−1` edges en vanaf room 0 is elke room bereikbaar |
| 8 | `SpanningTreeTests.SameSeedSameDungeon` | `same_seed_same_dungeon` | determinisme | 0..200 | twee keer dezelfde seed → zelfde rooms, edges en tree |
| 9 | `SpanningTreeTests.DifferentSeedDifferentTree` | `different_seed_different_tree` | variatie | 0..200 (paren `s`, `s+1`) | andere seed → andere tree |
| 10a–d | `DoorGenerationTests.DoorRight`, `DoorLeft`, `DoorBottom`, `DoorTop` | `door_right` enz. | door walls | — | goede wall in room A, tegenovergestelde wall in room B |
| 10e | `DoorGenerationTests.DiagonalTieGoesLeftOrRight` | `diagonal_tie_goes_left_or_right` | tie: `dx` en `dy` even groot | — | door komt op left/right, niet top/bottom |
| 10f | `DoorGenerationTests.WallBIsOppositeOfWallA` | `wall_b_is_opposite_of_wall_a` | consistente doors | — | `WallB == OppositeWall(WallA)` voor 8 posities |
| 11a | `BfsTests.DistancesOnALine` | `distances_on_a_line` | BFS start/end | — | lijn 0-1-2-3 → afstanden `[0,1,2,3]`, end room 3 |
| 11b | `BfsTests.DoorsGoBothWays` | `doors_go_both_ways` | een door werkt twee kanten op | — | een door opgeslagen als 1→0 werkt ook vanaf 0 |
| 11c | `BfsTests.TieLowestIdWins` | `tie_lowest_id_wins` | tie bij end room | — | twee rooms op afstand 2 → laagste id (2) wint |
| 12a | `PopulationTests.NoHostilesInStartRoom` | `no_hostiles_in_start_room` | PV-07 | 0..200 | geen enemy in de start room |
| 12b | `PopulationTests.MaxEnemiesPerRoom` | `max_enemies_per_room` | PV-03 | 0..200 | max `MaxEnemiesPerRoom` enemies per room |
| 12c | `PopulationTests.NoTwoSpawnablesOnSameTile` | `no_two_spawnables_on_same_tile` | PV-04 | 0..200 | geen twee spawnables op dezelfde tile |
| 12d | `PopulationTests.GeneratedPopulationIsValid` | `generated_population_is_valid` | `ValidatePopulation` | 0..200 | de eigen validatie keurt elke gegenereerde population goed |

## Verschillen met de Rust-tests

Alleen in de vorm, niet in wat er getest wordt:

| Rust | C# | Waarom |
|---|---|---|
| `rooms[3].width = …` | `rooms[3] = new Room { … }` | `Width`, `Height`, `X` en `Y` zijn in C# `init`-only, dus een room wordt vervangen in plaats van aangepast |
| `matches!(door.wall_a, Wall::Right)` | `Assert.Equal(Wall.Right, door.WallA)` | een C#-enum kun je direct vergelijken |
| `std::mem::discriminant(...)` | `Assert.Equal(OppositeWall(WallA), WallB)` | idem |
| `positions.sort(); positions.dedup();` | `.Distinct().Count()` | zelfde controle: geen dubbele posities |
| `generate()` in `tree.rs` en `population.rs` | `TestDungeon.Tree()` / `TestDungeon.Populated()` | één gedeelde helper in plaats van twee kopieën |

## Wat ik bewust NIET test

Hetzelfde als Matt, met dezelfde redenen:

- **Godot-kant**: renderen, gameplay, of Godot de JSON goed inleest. Dat test de smoketest en de generatortest van de game.
- **JSON-export** (`DungeonJson.cs`): weinig eigen logica. Dat de JSON byte voor byte gelijk is aan die van Rust, is apart gecontroleerd voor seeds 0–999 (zie [Verification](verification.md)).
- **`Program.cs`** en het command-line contract: met de hand getest, en via de game.
- **Performance**: hoort bij de benchmark, niet bij de unit tests.
- **Corridors**: uit de scope gehaald.
- **Of de tree minimaal is (MST)**: de weights zijn random, dus "minimaal" zegt niets over de gameplay.

De extra testideeën die alleen voor de C#-port gelden (zoals de officiële PCG32-testwaarden en een regressietest tegen opgeslagen Rust-JSON) staan nog in de [Roadmap](roadmap.md#test-ideas). Die zijn al met de hand gecontroleerd in [Verification](verification.md), maar nog geen unit test.
