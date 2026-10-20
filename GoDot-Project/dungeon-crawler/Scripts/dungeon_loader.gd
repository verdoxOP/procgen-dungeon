extends Node

const MENU_SCENE := "res://Scenes/menu.tscn"
const FORMAT_VERSION := 2

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
	var data := load_dungeon()
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
		fail("Start room %d does not exist." % dungeon.start_room_id)
		return

	player.restore(GameSettings.carried)
	hud.track(player)
	hud.show_info(GameSettings.last_info)
	hud.retry_pressed.connect(_on_retry)
	hud.new_seed_pressed.connect(_on_new_seed)
	hud.menu_pressed.connect(_on_menu)
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


func _on_player_died() -> void:
	hud.show_game_over(GameSettings.floor_number)
	get_tree().paused = true


func _on_retry() -> void:
	GameSettings.retry()
	restart()


func _on_new_seed() -> void:
	GameSettings.new_run(GameSettings.generator, GameSettings.random_seed())
	restart()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# Esc goes back to the menu.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		_on_menu()


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


# Next floor: a new dungeon from the same generator, keeping the player's stats.
func _on_exit_used() -> void:
	GameSettings.next_floor(player.snapshot())
	get_tree().reload_current_scene.call_deferred()


# Stage 1 + 2: get the JSON text (generator or test file) and parse it.
# Returns an empty Dictionary on failure, after sending the player back to the menu.
func load_dungeon() -> Dictionary:
	var text := ""
	var process_ms := -1.0
	if GameSettings.generator == GameSettings.TEST_GENERATOR:
		var path := GameSettings.TEST_DUNGEON_PATH
		text = FileAccess.get_file_as_string(path)
		if text.is_empty():
			fail("Could not read %s (%s)." % [path, error_string(FileAccess.get_open_error())])
			return {}
	else:
		var result := GeneratorRunner.run(GameSettings.generator, GameSettings.dungeon_seed)
		if result.has("error"):
			fail(result["error"])
			return {}
		text = result["text"]
		process_ms = result["process_ms"]

	var json := JSON.new()
	if json.parse(text) != OK:
		fail("%s did not output valid JSON (line %d: %s)." % [
			GameSettings.generator, json.get_error_line(), json.get_error_message()])
		return {}
	var data = json.data
	if not data is Dictionary:
		fail("The dungeon JSON must be an object at the top level.")
		return {}
	if int(data.get("format_version", 0)) != FORMAT_VERSION:
		fail("Unsupported format_version %s (expected %d)." % [data.get("format_version"), FORMAT_VERSION])
		return {}
	if data.get("rooms", []).is_empty():
		fail("The dungeon has no rooms.")
		return {}

	GameSettings.last_info = describe(data, process_ms)
	return data


# One line for the HUD and menu, e.g. "Floor 2 · rust · seed 1234 · 4.8 ms (process 31 ms)".
func describe(data: Dictionary, process_ms: float) -> String:
	var stats = data.get("stats")
	var total = stats.get("total_ms") if stats is Dictionary else null
	var timing := "%.2f ms" % float(total) if total != null else "no stats"
	if process_ms >= 0.0:
		timing += " (process %.0f ms)" % process_ms
	return "Floor %d  ·  %s  ·  seed %d  ·  %s" % [
		GameSettings.floor_number, GameSettings.generator, int(data.get("seed", 0)), timing]


# Back to the menu with the reason. Deferred, because this can run during _ready().
func fail(message: String) -> void:
	push_error(message)
	GameSettings.last_error = message
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)
