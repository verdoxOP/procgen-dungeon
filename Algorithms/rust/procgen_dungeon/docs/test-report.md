# Testrapport

[← Documentation home](README.md) · [Testplan](test-plan.md)

## Uitvoering

- **Datum:** 28 oktober 2026
- **Omgeving:** Linux, `rustc 1.97.0`, `cargo 1.97.0`
- **Commando** (in `Algorithms/rust/procgen_dungeon`):

```sh
cargo test
```

## Resultaten

| # | Test | Regel | Seeds | Resultaat |
|---|---|---|---|---|
| 1 | `room_generation::tests::rooms_fit_inside_map` | room generation | 200 (0..200) | ✅ pass |
| 2 | `room_generation::tests::rooms_do_not_overlap` | VR-02 | 200 (0..200) | ✅ pass |
| 3a | `room::tests::overlapping_rooms_overlap` | `room_overlap_check` | — | ✅ pass |
| 3b | `room::tests::touching_rooms_do_not_overlap` | `room_overlap_check` | — | ✅ pass |
| 4 | `room_generation::tests::room_id_is_index` | id = index | 200 (0..200) | ✅ pass |
| 5a | `validation::tests::valid_rooms_pass` | VR-01/02/03 | — | ✅ pass |
| 5b | `validation::tests::too_few_rooms_fail` | VR-03 | — | ✅ pass |
| 5c | `validation::tests::too_small_rooms_fail` | VR-01 | — | ✅ pass |
| 5d | `validation::tests::overlapping_rooms_fail` | VR-02 | — | ✅ pass |
| 6 | `edge::tests::edges_form_complete_graph` | complete graph | 200 (0..200) | ✅ pass |
| 7 | `tree::tests::tree_has_n_minus_1_edges_and_reaches_every_room` | spanning tree | 200 (0..200) | ✅ pass |
| 8 | `tree::tests::same_seed_same_dungeon` | determinisme | 200 (0..200) | ✅ pass |
| 9 | `tree::tests::different_seed_different_tree` | variatie | 200 paren (`s`, `s+1`) | ✅ pass |
| 10a | `door::tests::door_right` | door walls | — | ✅ pass |
| 10b | `door::tests::door_left` | door walls | — | ✅ pass |
| 10c | `door::tests::door_bottom` | door walls | — | ✅ pass |
| 10d | `door::tests::door_top` | door walls | — | ✅ pass |
| 10e | `door::tests::diagonal_tie_goes_left_or_right` | tie naar left/right | — | ✅ pass |
| 10f | `door::tests::wall_b_is_opposite_of_wall_a` | consistente doors | — | ✅ pass |
| 11a | `bfs::tests::distances_on_a_line` | BFS start/end | — | ✅ pass |
| 11b | `bfs::tests::doors_go_both_ways` | BFS | — | ✅ pass |
| 11c | `bfs::tests::tie_lowest_id_wins` | end room tie | — | ✅ pass |
| 12a | `population::tests::no_hostiles_in_start_room` | PV-07 | 200 (0..200) | ✅ pass |
| 12b | `population::tests::max_enemies_per_room` | PV-03 | 200 (0..200) | ✅ pass |
| 12c | `population::tests::no_two_spawnables_on_same_tile` | PV-04 | 200 (0..200) | ✅ pass |
| 12d | `population::tests::generated_population_is_valid` | `validate_population` | 200 (0..200) | ✅ pass |

## Output van `cargo test`

```text
running 26 tests
...
test result: ok. 26 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.10s
```

Bij het compileren geeft `cargo` 9 warnings. Die komen allemaal uit de bestaande code (lowercase constants, `Ivertex1`/`Ivertex2`, ongebruikte `mst` enz.), niet uit de tests. De tests geven geen nieuwe warnings.

## Bevindingen

- Alle 26 tests slagen bij de eerste run; ik hoefde geen test aan te passen.
- Voor alle 200 seeds lukte het om binnen `MAX_GENERATION_ATTEMPTS` (10) pogingen geldige rooms te maken. Anders waren de seed-tests van `tree.rs` en `population.rs` gefaald.
- Voor alle 200 paren van opeenvolgende seeds was de tree anders.

## Bekende issues

| Waar | Issue | Status |
|---|---|---|
| `main.rs` | Als `validate_rooms` na 10 pogingen nog steeds faalt, stopt het programma met exit code `1` en is er geen fallback (bijv. minder rooms accepteren of verder zoeken). Eerder liep `main` in dit geval door met ongeldige rooms; in de huidige code is dat al vervangen door de exit. Wat er hoort te gebeuren is nog een open beslissing van mij. | open beslissing, niet aangepast |
| `main.rs` | Het pad "10 pogingen gefaald" wordt niet door een test geraakt: in seeds 0..200 komt het niet voor, en `main` kan ik niet in een unit test aanroepen. | niet getest |
| `population.rs` | PV-01 / PV-02 worden niet los getest, omdat de code ze alleen indirect controleert (zie [Roadmap](roadmap.md#known-issues)). | bekend |
| `src/` | De bestaande code is niet `rustfmt`-clean. Ik heb `cargo fmt` niet gedraaid, omdat dat ook mijn productiecode zou herschrijven. | bekend |

## Volgende stappen

- Beslissen wat er moet gebeuren als alle generatiepogingen falen, en dat gedrag dan testen.
- Een test voor de exit codes en `--seed` parsing, bijvoorbeeld door `parse_seed_arg` te testen.
- Als backbone validation af is: tests daarvoor toevoegen.
- Samen met Jip een integratietest: Rust JSON inlezen in Godot.
