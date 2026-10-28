# Testplan

[← Documentation home](README.md)

## Doel

Ik wil aantonen dat mijn generator doet wat hij moet doen, zonder Godot. Elke stap in de pipeline (rooms → edges → tree → doors → BFS → population) test ik los, met de validatieregels uit [Validation rules](validation-rules.md) als eisen.

## Testopzet

- Alle tests zijn unit tests in een `#[cfg(test)] mod tests` onderaan het bestand dat ze testen. De crate is alleen een binary (`main.rs`), daarom geen `tests/` map: die kan niet bij de functies van een binary.
- Draaien: `cargo test` in `Algorithms/rust/procgen_dungeon`.
- Geen extra crates, alleen `rand` / `rand_pcg` die ik al gebruik.
- **Seed-gebaseerde tests** draaien over de vaste seeds `0..200` met `Pcg32::seed_from_u64(seed)`. Daardoor is elke run hetzelfde (deterministisch) en kan ik een fout altijd terugvinden: de foutmelding noemt de seed.
- Tests die een hele dungeon nodig hebben, doen dezelfde retry loop als `main` (max `MAX_GENERATION_ATTEMPTS` keer `generate_rooms` tot `validate_rooms` slaagt).
- **Handgemaakte tests** (overlap, validatie, doors, BFS) gebruiken kleine rooms die ik zelf neerzet, zodat de verwachte uitkomst meteen duidelijk is.

## Wat ik test en waarom

| # | Test | Bestand | Regel / eis | Seeds | Verwacht resultaat |
|---|---|---|---|---|---|
| 1 | `rooms_fit_inside_map` | `room_generation.rs` | room generation: rooms passen in `MAP_WIDTH` × `MAP_HEIGHT` | 0..200 | geen room steekt buiten de map |
| 2 | `rooms_do_not_overlap` | `room_generation.rs` | VR-02 | 0..200 | geen enkel paar rooms overlapt |
| 3a | `overlapping_rooms_overlap` | `room.rs` | `room_overlap_check` | — | twee rooms die een tile delen → `true` (beide kanten op) |
| 3b | `touching_rooms_do_not_overlap` | `room.rs` | `room_overlap_check`, touching mag | — | rooms die alleen tegen elkaar aan liggen → `false` |
| 4 | `room_id_is_index` | `room_generation.rs` | id = index in de `Vec` | 0..200 | `rooms[i].id == i` |
| 5a | `valid_rooms_pass` | `validation.rs` | VR-01/02/03 (controle) | — | 8 losse rooms van minimale grootte → geldig |
| 5b | `too_few_rooms_fail` | `validation.rs` | VR-03 | — | 7 rooms → ongeldig |
| 5c | `too_small_rooms_fail` | `validation.rs` | VR-01 | — | één room te smal of te laag → ongeldig |
| 5d | `overlapping_rooms_fail` | `validation.rs` | VR-02 | — | twee rooms over elkaar → ongeldig |
| 6 | `edges_form_complete_graph` | `edge.rs` | complete graph | 0..200 | `n·(n−1)/2` edges, geen self-loops, geen dubbele paren |
| 7 | `tree_has_n_minus_1_edges_and_reaches_every_room` | `tree.rs` | spanning tree | 0..200 | `n−1` edges en vanaf room 0 is elke room bereikbaar |
| 8 | `same_seed_same_dungeon` | `tree.rs` | determinisme | 0..200 | twee keer dezelfde seed → zelfde rooms, edges en tree |
| 9 | `different_seed_different_tree` | `tree.rs` | variatie | 0..200 (paren `s`, `s+1`) | andere seed → andere tree |
| 10a–d | `door_right`, `door_left`, `door_bottom`, `door_top` | `door.rs` | door walls | — | goede wall in room a, tegenovergestelde wall in room b |
| 10e | `diagonal_tie_goes_left_or_right` | `door.rs` | tie: `dx` en `dy` even groot | — | door komt op left/right, niet top/bottom |
| 10f | `wall_b_is_opposite_of_wall_a` | `door.rs` | consistente doors | — | `wall_b == opposite_wall(wall_a)` voor 8 posities |
| 11a | `distances_on_a_line` | `bfs.rs` | BFS start/end | — | lijn 0-1-2-3 → afstanden `[0,1,2,3]`, end room 3 |
| 11b | `doors_go_both_ways` | `bfs.rs` | door is twee kanten op | — | een door opgeslagen als 1→0 werkt ook vanaf 0 |
| 11c | `tie_lowest_id_wins` | `bfs.rs` | tie bij end room | — | twee rooms op afstand 2 → laagste id (2) wint |
| 12a | `no_hostiles_in_start_room` | `population.rs` | PV-07 | 0..200 | geen enemy in de start room |
| 12b | `max_enemies_per_room` | `population.rs` | PV-03 | 0..200 | max `MAX_ENEMIES_PER_ROOM` enemies per room |
| 12c | `no_two_spawnables_on_same_tile` | `population.rs` | PV-04 | 0..200 | geen twee spawnables op dezelfde tile |
| 12d | `generated_population_is_valid` | `population.rs` | `validate_population` | 0..200 | mijn eigen validatie keurt elke gegenereerde population goed |

## Wat ik bewust NIET test

- **Godot-kant**: renderen, gameplay, of Godot de JSON goed inleest. Dat is het werk van Jip en hoort bij een integratietest.
- **JSON export** (`dungeon_json.rs`): alleen serde, geen eigen logica.
- **`main` en `parse_seed_arg`**: de command-line contract test ik met de hand.
- **Visualisatie** (`grid.rs`, `tree_visualization.rs`): debug-output, geen onderdeel van de dungeon.
- **Performance**: geen eis meer (geen Raspberry Pi), benchmarking is nice-to-have.
- **Corridors**: uit de scope gehaald.
- **Of de tree minimaal is (MST)**: de weights zijn random, dus "minimaal" zegt niets over de gameplay. Ik test alleen dat het een spanning tree is.
