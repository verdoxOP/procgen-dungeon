# Testrapport

[← Documentation home](README.md) · [Testplan](test-plan.md)

## Uitvoering

- **Datum:** 28 oktober 2026
- **Omgeving:** Windows 11, .NET SDK 10.0.204, project target `net8.0`, xUnit 2.5.3
- **Commando** (in `Algorithms/csharp/procgen-csharp`):

```sh
dotnet test
```

## Resultaten

| # | Test | Regel | Seeds | Resultaat |
|---|---|---|---|---|
| 1 | `RoomGenerationTests.RoomsFitInsideMap` | room generation | 200 (0..200) | ✅ pass |
| 2 | `RoomGenerationTests.RoomsDoNotOverlap` | VR-02 | 200 (0..200) | ✅ pass |
| 3a | `RoomTests.OverlappingRoomsOverlap` | `Room.Overlaps` | — | ✅ pass |
| 3b | `RoomTests.TouchingRoomsDoNotOverlap` | `Room.Overlaps` | — | ✅ pass |
| 4 | `RoomGenerationTests.RoomIdIsIndex` | id = index | 200 (0..200) | ✅ pass |
| 5a | `ValidationTests.ValidRoomsPass` | VR-01/02/03 | — | ✅ pass |
| 5b | `ValidationTests.TooFewRoomsFail` | VR-03 | — | ✅ pass |
| 5c | `ValidationTests.TooSmallRoomsFail` | VR-01 | — | ✅ pass |
| 5d | `ValidationTests.OverlappingRoomsFail` | VR-02 | — | ✅ pass |
| 6 | `EdgeGenerationTests.EdgesFormCompleteGraph` | complete graph | 200 (0..200) | ✅ pass |
| 7 | `SpanningTreeTests.TreeHasNMinus1EdgesAndReachesEveryRoom` | spanning tree | 200 (0..200) | ✅ pass |
| 8 | `SpanningTreeTests.SameSeedSameDungeon` | determinisme | 200 (0..200) | ✅ pass |
| 9 | `SpanningTreeTests.DifferentSeedDifferentTree` | variatie | 200 paren (`s`, `s+1`) | ✅ pass |
| 10a | `DoorGenerationTests.DoorRight` | door walls | — | ✅ pass |
| 10b | `DoorGenerationTests.DoorLeft` | door walls | — | ✅ pass |
| 10c | `DoorGenerationTests.DoorBottom` | door walls | — | ✅ pass |
| 10d | `DoorGenerationTests.DoorTop` | door walls | — | ✅ pass |
| 10e | `DoorGenerationTests.DiagonalTieGoesLeftOrRight` | tie naar left/right | — | ✅ pass |
| 10f | `DoorGenerationTests.WallBIsOppositeOfWallA` | consistente doors | — | ✅ pass |
| 11a | `BfsTests.DistancesOnALine` | BFS start/end | — | ✅ pass |
| 11b | `BfsTests.DoorsGoBothWays` | BFS | — | ✅ pass |
| 11c | `BfsTests.TieLowestIdWins` | end room tie | — | ✅ pass |
| 12a | `PopulationTests.NoHostilesInStartRoom` | PV-07 | 200 (0..200) | ✅ pass |
| 12b | `PopulationTests.MaxEnemiesPerRoom` | PV-03 | 200 (0..200) | ✅ pass |
| 12c | `PopulationTests.NoTwoSpawnablesOnSameTile` | PV-04 | 200 (0..200) | ✅ pass |
| 12d | `PopulationTests.GeneratedPopulationIsValid` | `ValidatePopulation` | 200 (0..200) | ✅ pass |

## Output van `dotnet test`

```text
Passed!  - Failed:     0, Passed:    26, Skipped:     0, Total:    26, Duration: 383 ms - procgen-csharp.Tests.dll (net8.0)
```

De build geeft 0 warnings. Tijdens de tests print `GenerateRooms` regels als `Generated 12 rooms in 35 attempts` naar stderr. Dat is de gewone log van de generator en geen fout.

## Controle: vangen de tests echt fouten?

Een test die altijd slaagt, bewijst niets. Daarom heb ik twee keer met opzet een fout in de generator gezet, de tests gedraaid, en de fout daarna weer teruggedraaid:

| Opzettelijke fout | Gevolg |
|---|---|
| `Room.Overlaps`: `X >= otherRight` veranderd in `X > otherRight` (rooms die elkaar raken tellen dan als overlap) | 2 tests faalden |
| `Bfs.FurthestRoom`: `>` veranderd in `>=` (bij een gelijke afstand wint dan het hoogste id) | `TieLowestIdWins` faalde |

## Bevindingen

- Alle 26 tests slagen, net als de 26 Rust-tests in het [Rust testrapport](../../../rust/procgen_dungeon/docs/test-report.md). Beide generators voldoen dus aan precies dezelfde eisen.
- Ik hoefde geen generatorcode te veranderen om de tests te laten slagen. Alleen `IsInsideRoom` en `RoomAt` zijn van `private` naar `internal` gegaan, zodat de tests erbij kunnen (zie [Testplan](test-plan.md#testopzet)).
- Voor alle 200 seeds lukte het om binnen `MaxGenerationAttempts` (10) pogingen geldige rooms te maken. Dat klopt met Rust: dezelfde seed geeft dezelfde rooms.

## Bekende issues

| Waar | Issue | Status |
|---|---|---|
| `Program.cs` | Het pad "10 pogingen gefaald" (exit code 1) wordt door geen test geraakt: het komt in seeds 0..200 niet voor, en de top-level code van `Program.cs` kan niet in een unit test aangeroepen worden. Hetzelfde issue staat in het Rust-rapport. | niet getest |
| `Population.cs` | PV-01 / PV-02 worden niet los getest, net als in Rust. | bekend |
| `Population.DoorTile` | Spawns naast een deur op muren met 2+ deuren (zie [Roadmap](roadmap.md#known-issues)). De tests vangen dit niet, omdat ze dezelfde `DoorTile` gebruiken als de generator. | samen met Matt oplossen |

## Volgende stappen

- Als Matt nieuwe tests toevoegt (exit codes, `--seed` parsing, backbone validation): die ook vertalen.
- De C#-specifieke testideeën uit de [Roadmap](roadmap.md#test-ideas) als unit tests toevoegen, vooral de PCG32-testwaarden en een regressietest tegen opgeslagen Rust-JSON.
