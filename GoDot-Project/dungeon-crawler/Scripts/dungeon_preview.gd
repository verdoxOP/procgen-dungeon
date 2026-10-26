@tool
class_name DungeonPreview
extends Node2D

# Shows a whole generated dungeon inside the editor: open Scenes/dungeon_preview.tscn,
# pick a generator and a seed in the Inspector, and the map is drawn right away.
# Uses the same generators, JSON loading and door placement as the game.

const TILE_SIZE := 16
const TILESET := preload("res://Assets/Dungeon_Tileset.png")
const FLOOR_TILE := Vector2i(2, 2)
const WALL_TILE := Vector2i(2, 0)
const PICKUP_TEXTURES := {
	"health": "res://Assets/flasks/flasks_1_1.png",
	"buff": "res://Assets/flasks/flasks_2_1.png",
	"ammo": "res://Assets/arrow/Just_arrow.png",
	"key": "res://Assets/keys/keys_1_1.png",
}
# First frame of each enemy's idle animation (32x32 frames, same sheets as the game).
const ENEMY_SHEETS := {
	"skeleton": "res://Assets/Enemy_Animations_Set/enemies-skeleton1_idle.png",
	"skeleton2": "res://Assets/Enemy_Animations_Set/enemies-skeleton2_idle.png",
	"vampire": "res://Assets/Enemy_Animations_Set/enemies-vampire_idle.png",
}
const ENEMY_FRAME := 32
# The character sits low-left in its frame; same offset as enemy.gd.
const ENEMY_OFFSET := Vector2(2, -5)

const START_COLOR := Color(0.3, 0.9, 0.4)
const END_COLOR := Color(1.0, 0.35, 0.35)
const BACKBONE_COLOR := Color(1.0, 0.85, 0.2, 0.75)
const TEXT_COLOR := Color(1, 1, 1)
const ERROR_COLOR := Color(1.0, 0.4, 0.4)

## Which generator to run. Lists the programs in the game's generators/ folder
## (build them with build-generators.ps1 / .sh) plus the built-in test file.
@export var generator := GameSettings.TEST_GENERATOR:
	set(value):
		generator = value
		_regenerate_if_ready()

## The seed passed to the generator. Ignored for the test file.
@export var seed_value := 42:
	set(value):
		seed_value = value
		_regenerate_if_ready()

@export_tool_button("Generate", "Reload") var generate_button := generate
@export_tool_button("Random seed", "RandomNumberGenerator") var random_seed_button := pick_random_seed

@export_group("Show")
## Lines between the two sides of every door: the backbone of the dungeon.
@export var show_backbone := true:
	set(value):
		show_backbone = value
		queue_redraw()
@export var show_spawnables := true:
	set(value):
		show_spawnables = value
		queue_redraw()
@export var show_labels := true:
	set(value):
		show_labels = value
		queue_redraw()

var _dungeon: Dungeon
var _error := ""
var _info := ""
var _textures := {}


func _ready() -> void:
	generate()


# Turns the "generator" text field into a dropdown with the generators that exist right now.
func _validate_property(property: Dictionary) -> void:
	if property.name == "generator":
		var names := PackedStringArray([GameSettings.TEST_GENERATOR])
		names.append_array(GeneratorRunner.available())
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(names)


func pick_random_seed() -> void:
	seed_value = GameSettings.random_seed()


# Runs the generator and loads its dungeon, the same way the game does.
func generate() -> void:
	_dungeon = null
	_error = ""
	_info = ""

	var text := ""
	var process_ms := -1.0
	if generator == GameSettings.TEST_GENERATOR:
		text = FileAccess.get_file_as_string(GameSettings.TEST_DUNGEON_PATH)
	else:
		var result := GeneratorRunner.run(generator, seed_value)
		if result.has("error"):
			_fail(result["error"])
			return
		text = result["text"]
		process_ms = result["process_ms"]

	var data = JSON.parse_string(text)
	if not data is Dictionary:
		_fail("%s did not give valid dungeon JSON." % generator)
		return
	if data.get("rooms", []).is_empty():
		_fail("The dungeon has no rooms.")
		return

	_dungeon = Dungeon.from_dict(data)
	var spawn_counts := {}
	for s in _dungeon.spawnables:
		spawn_counts[s.type] = spawn_counts.get(s.type, 0) + 1
	_info = "%s  ·  seed %d  ·  %d rooms  ·  %d doors  ·  start %d, end %d  ·  spawnables %s%s" % [
		generator, _dungeon.dungeon_seed, _dungeon.rooms.size(), _dungeon.doors.size(),
		_dungeon.start_room_id, _dungeon.end_room_id, _format_counts(spawn_counts),
		"  ·  process %.0f ms" % process_ms if process_ms >= 0.0 else ""]
	queue_redraw()


func _fail(message: String) -> void:
	_error = message
	push_warning("Dungeon preview: " + message)
	queue_redraw()


func _regenerate_if_ready() -> void:
	# Setters also run while the scene is loading; only generate once it's in the tree.
	if is_node_ready():
		generate()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	if _error != "":
		draw_multiline_string(font, Vector2(0, -26), _error, HORIZONTAL_ALIGNMENT_LEFT, 900, 14, -1, ERROR_COLOR)
		return
	if _dungeon == null:
		return

	# Above the room labels, which sit up to 4 px above the map.
	draw_string(font, Vector2(0, -26), _info, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TEXT_COLOR)

	# Rooms: floor with a wall ring around it, like the game builds each room.
	for room in _dungeon.rooms:
		var area: Rect2i = room.rect.grow(1)
		for x in range(area.position.x, area.end.x):
			for y in range(area.position.y, area.end.y):
				var tile := Vector2i(x, y)
				_draw_tile(tile, FLOOR_TILE if room.rect.has_point(tile) else WALL_TILE)

	# Doors: openings in the wall ring, placed by the same code the game uses.
	for room in _dungeon.rooms:
		for opening in _dungeon.openings(room.id):
			_draw_tile(opening.tile, FLOOR_TILE)

	# Start and end room.
	_outline_room(_dungeon.get_room(_dungeon.start_room_id), START_COLOR, "START")
	_outline_room(_dungeon.get_room(_dungeon.end_room_id), END_COLOR, "EXIT")

	# Backbone: rooms are separate screens, so a line shows which two doors belong together.
	if show_backbone:
		for door in _dungeon.doors:
			draw_line(_tile_center(door.from_tile), _tile_center(door.to_tile), BACKBONE_COLOR, 2.0)

	if show_spawnables:
		for s in _dungeon.spawnables:
			_draw_spawnable(s)

	if show_labels:
		for room in _dungeon.rooms:
			var top_left := Vector2(room.rect.position * TILE_SIZE) + Vector2(3, 13)
			draw_string(font, top_left, str(room.id), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT_COLOR)


func _draw_tile(tile: Vector2i, atlas: Vector2i) -> void:
	var dest := Rect2(Vector2(tile * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
	var source := Rect2(Vector2(atlas * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
	draw_texture_rect_region(TILESET, dest, source)


func _draw_spawnable(s: Spawnable) -> void:
	var center := _tile_center(s.position)
	if s.type == "enemy":
		var sheet := _texture(ENEMY_SHEETS.get(s.enemy, ENEMY_SHEETS["skeleton"]))
		var dest := Rect2(center - Vector2(ENEMY_FRAME, ENEMY_FRAME) / 2.0 + ENEMY_OFFSET, Vector2(ENEMY_FRAME, ENEMY_FRAME))
		# Passive enemies are drawn a bit faded, so they stand out from aggressive ones.
		var tint := Color(1, 1, 1) if s.behaviour == "aggressive" else Color(0.75, 0.85, 1.0, 0.8)
		draw_texture_rect_region(sheet, dest, Rect2(0, 0, ENEMY_FRAME, ENEMY_FRAME), tint)
	elif PICKUP_TEXTURES.has(s.type):
		var texture := _texture(PICKUP_TEXTURES[s.type])
		draw_texture_rect(texture, Rect2(center - Vector2(TILE_SIZE, TILE_SIZE) / 2.0, Vector2(TILE_SIZE, TILE_SIZE)), false)


func _outline_room(room: Room, color: Color, label: String) -> void:
	if room == null:
		return
	var area: Rect2i = room.rect.grow(1)
	var rect := Rect2(Vector2(area.position * TILE_SIZE), Vector2(area.size * TILE_SIZE))
	draw_rect(rect, color, false, 3.0)
	if show_labels:
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, -4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)


func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile * TILE_SIZE) + Vector2(TILE_SIZE, TILE_SIZE) / 2.0


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


func _format_counts(counts: Dictionary) -> String:
	if counts.is_empty():
		return "none"
	var parts := PackedStringArray()
	for type in counts:
		parts.append("%d %s" % [counts[type], type])
	return ", ".join(parts)
