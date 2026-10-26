@tool
class_name GameSettings
extends RefCounted

# Everything that has to survive a scene change (menu -> game -> next floor).
# Static vars live as long as the game runs, so no autoload is needed.

const TEST_GENERATOR := "Test file"
const TEST_DUNGEON_PATH := "res://test_data/test_dungeon.json"
const MAX_SEED := 1_000_000

static var generator := TEST_GENERATOR
static var dungeon_seed := 42
static var floor_number := 1
# Player stats taken to the next floor (see Player.snapshot()). Empty = fresh start.
static var carried := {}
# Shown in the menu when loading a dungeon failed.
static var last_error := ""
# Generator, seed and timing of the current dungeon, shown in the HUD and menu.
static var last_info := ""


static func random_seed() -> int:
	return randi() % MAX_SEED


# A new run from the menu, or "new seed" after dying.
static func new_run(generator_name: String, seed_value: int) -> void:
	generator = generator_name
	dungeon_seed = seed_value
	floor_number = 1
	carried = {}
	last_error = ""


# Same dungeon again with fresh stats, after dying.
static func retry() -> void:
	carried = {}
	last_error = ""


# Used the exit: a new dungeon, keeping the player's stats.
static func next_floor(player_stats: Dictionary) -> void:
	floor_number += 1
	dungeon_seed = random_seed()
	carried = player_stats
