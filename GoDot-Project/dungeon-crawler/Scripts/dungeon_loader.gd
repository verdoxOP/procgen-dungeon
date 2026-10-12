extends Node

const DUNGEON_PATH := "res://test_data/test_dungeon.json"

@onready var map: Map = $"../Map"
@onready var camera: RoomCamera = $"../Camera2D"
@onready var player: Player = $"../Player"
@onready var hud: Hud = $"../Hud"

var dungeon: Dungeon
# The Room the player is in. Every room is its own screen.
var current_room: Room
# Holds everything spawned for the current room, so leaving the room frees it all at once.
var room_nodes: Node2D
# True between walking into a door and the next room being loaded.
var _switching := false


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

	var start_room := dungeon.get_room(dungeon.start_room_id)
	if start_room == null:
		push_error("Start room %d does not exist" % dungeon.start_room_id)
		return

	hud.track(player)
	player.died.connect(_on_player_died)
	# Main is still setting up its children during _ready(), so load the room a frame later.
	enter_room.call_deferred(start_room, start_room.center())


# Stage 7: load a room. Builds its tiles, spawns what's in it and moves the player
# to `arrive` (a tile). Stuff that was picked up or killed stays gone.
func enter_room(room: Room, arrive: Vector2i) -> void:
	current_room = room
	if room_nodes != null:
		# Out of the tree right away: rooms can touch, so an old doorway could sit
		# exactly where the player arrives and send them straight back.
		get_parent().remove_child(room_nodes)
		room_nodes.queue_free()
	room_nodes = Node2D.new()
	get_parent().add_child(room_nodes)
	# Arrows still flying in the old room would hit things in the new one.
	for child in get_parent().get_children():
		if child is Arrow:
			child.queue_free()

	map.build_room(room, dungeon)
	spawn_pickups()
	spawn_enemies()
	spawn_doors()
	spawn_exit()

	player.position = map.map_to_local(arrive)
	player.velocity = Vector2.ZERO
	camera.focus(map.room_world_rect(room), map.visible_tiles(room), Vector2(map.tile_set.tile_size))
	_switching = false


func in_current_room(s: Spawnable) -> bool:
	return not s.gone and dungeon.room_at(s.position) == current_room


func spawn_pickups() -> void:
	for s in dungeon.spawnables:
		if s.type == "enemy" or not in_current_room(s):
			continue  # Enemies: see spawn_enemies().
		var pickup := Pickup.new()
		pickup.spawnable = s
		pickup.position = map.map_to_local(s.position)
		room_nodes.add_child(pickup)


func spawn_enemies() -> void:
	for s in dungeon.spawnables:
		if s.type != "enemy" or not in_current_room(s):
			continue
		var enemy := Enemy.new()
		enemy.spawnable = s
		enemy.target = player
		enemy.home = current_room
		# Only the room on screen exists, so its enemies are always active.
		enemy.active = true
		enemy.position = map.map_to_local(s.position)
		room_nodes.add_child(enemy)


# For now: restart the same dungeon. Later this becomes a game-over screen.
func _on_player_died() -> void:
	print("Game over")
	get_tree().reload_current_scene.call_deferred()


# Every door and corridor of this room gets a Doorway that loads the other room.
# Locked doors and unbroken weak walls sit on top of it and block it until opened.
func spawn_doors() -> void:
	for opening in dungeon.openings(current_room.id):
		var passage = opening.passage
		var doorway := Doorway.new()
		doorway.opening = opening
		doorway.position = map.map_to_local(opening.tile)
		doorway.entered.connect(_on_doorway_entered)
		room_nodes.add_child(doorway)

		if passage is Door and passage.locked:
			var locked_door := LockedDoor.new()
			locked_door.door = passage
			locked_door.position = map.map_to_local(opening.tile)
			room_nodes.add_child(locked_door)
		elif passage is Corridor and not passage.opened:
			var weak_wall := WeakWall.new()
			weak_wall.tile = opening.tile
			weak_wall.position = map.map_to_local(opening.tile)
			weak_wall.broken.connect(_on_weak_wall_broken.bind(passage))
			room_nodes.add_child(weak_wall)


func _on_doorway_entered(opening: Dictionary) -> void:
	if _switching or opening.from != current_room.id:
		return
	_switching = true
	# This runs inside a physics callback, so swap the room afterwards.
	enter_room.call_deferred(dungeon.get_room(opening.to), opening.arrive)


func _on_weak_wall_broken(tile: Vector2i, corridor: Corridor) -> void:
	corridor.opened = true
	map.open_tile(tile)


func spawn_exit() -> void:
	if current_room.id != dungeon.end_room_id:
		return
	var exit := Exit.new()
	exit.position = map.map_to_local(current_room.center())
	exit.used.connect(_on_exit_used)
	room_nodes.add_child(exit)


# For now: start the same dungeon again. Later this asks the generator for a new seed.
func _on_exit_used() -> void:
	print("Dungeon complete!")
	get_tree().reload_current_scene()


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
