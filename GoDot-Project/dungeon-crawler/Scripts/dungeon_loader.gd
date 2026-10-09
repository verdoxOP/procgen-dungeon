extends Node

const DUNGEON_PATH := "res://test_data/test_dungeon.json"

@onready var map: Map = $"../Map"
@onready var camera: RoomCamera = $"../Camera2D"
@onready var player: Player = $"../Player"
@onready var hud: Hud = $"../Hud"

var dungeon: Dungeon
var current_room: Room


func _ready() -> void:
	var data := load_dungeon(DUNGEON_PATH)
	if data.is_empty():
		return

	dungeon = Dungeon.from_dict(data)

	print("Seed: ", dungeon.dungeon_seed)
	print("Generator: ", dungeon.generator)
	print("Rooms: ", dungeon.rooms.size())
	print("Start room: ", dungeon.start_room_id, ", end room: ", dungeon.end_room_id)
	for room in dungeon.rooms:
		print("  Room %d at %s, size %s, center %s" % [
			room.id, room.rect.position, room.rect.size, room.center()])

	map.build(dungeon)
	hud.track(player)
	spawn_pickups()
	spawn_doors()

	var start_room := dungeon.get_room(dungeon.start_room_id)
	player.position = map.map_to_local(start_room.center())
	enter_room(start_room)


# Switch the camera when the player walks into another room.
# On paths (outside any room) the camera stays where it is.
func _process(_delta: float) -> void:
	if dungeon == null:
		return
	var room := dungeon.room_at(map.local_to_map(player.position))
	if room != null and room != current_room:
		enter_room(room)


func spawn_pickups() -> void:
	for s in dungeon.spawnables:
		if s.type == "enemy":
			continue  # Enemies get their own step.
		var pickup := Pickup.new()
		pickup.spawnable = s
		pickup.position = map.map_to_local(s.position)
		# Main is still setting up its children during _ready(), so add it a frame later.
		get_parent().add_child.call_deferred(pickup)


# Only locked doors are spawned. An unlocked door is just an open doorway for now.
func spawn_doors() -> void:
	for connection in dungeon.connections:
		if connection.door == null or not connection.door.locked:
			continue
		var locked_door := LockedDoor.new()
		locked_door.door = connection.door
		locked_door.position = map.map_to_local(connection.door.position)
		get_parent().add_child.call_deferred(locked_door)


func enter_room(room: Room) -> void:
	current_room = room
	camera.focus_room(
		map.room_world_rect(room),
		map.visible_tiles(room, dungeon),
		Vector2(map.tile_set.tile_size))


# Stage 1 + 2: read the JSON text and parse it.
# Returns an empty Dictionary on failure.
func load_dungeon(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Dungeon file not found: %s" % path)
		return {}

	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Could not read dungeon file: %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return {}

	var data = JSON.parse_string(text)
	if data == null:
		push_error("Dungeon file is not valid JSON: %s" % path)
		return {}
	if not data is Dictionary:
		push_error("Dungeon JSON must be an object at the top level: %s" % path)
		return {}

	return data
