extends SceneTree

# Headless playthrough of test_data/test_dungeon.json. Run from this folder:
#   godot --headless --path . -s res://tests/smoke_test.gd

var loader
var fails := 0


func check(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func room_nodes_of(type) -> Array:
	return loader.room_nodes.get_children().filter(func(n): return is_instance_of(n, type))


# Hold a direction until the room changes (max 2 seconds), like a player would.
func hold(action: String) -> void:
	var start = loader.current_room
	Input.action_press(action)
	for i in 120:
		await physics_frame
		if loader.current_room != start:
			break
	Input.action_release(action)
	await frames(2)


func opening_to(room_id: int) -> Dictionary:
	for o in loader.dungeon.openings(loader.current_room.id):
		if o.to == room_id:
			return o
	return {}


# Put the player on the door tile and let physics fire the Doorway.
func walk_through(to_id: int) -> void:
	var o := opening_to(to_id)
	loader.player.position = loader.map.map_to_local(o.tile)
	await frames(4)


func _initialize() -> void:
	var scene: PackedScene = load("res://Scenes/dungeon_loader.tscn")
	root.add_child(scene.instantiate())
	_run.call_deferred()


func _run() -> void:
	await frames(5)
	loader = root.get_node("Main/Dungeon_Loader")
	var d = loader.dungeon
	var map = loader.map
	var player = loader.player

	check(loader.current_room.id == 0, "starts in room 0")
	check(map.get_used_cells().size() == 12 * 10 - 1, "only room 0 + walls built (%d cells)" % map.get_used_cells().size())
	check(room_nodes_of(Enemy).is_empty(), "start room has no enemies")
	check(room_nodes_of(WeakWall).size() == 1, "start room has the hidden corridor weak wall")

	await walk_through(1)
	check(loader.current_room.id == 1, "door 0 -> 1 loads room 1")
	var back := opening_to(0)
	check(map.local_to_map(player.position) == Dungeon.inside(back.tile, "left"), "arrive just inside room 1's left door")
	check(room_nodes_of(Enemy).size() == 1, "room 1 has 1 enemy")
	check(room_nodes_of(LockedDoor).size() == 1, "locked door to room 3 present")

	await walk_through(3)
	check(loader.current_room.id == 1, "locked door blocks the way to room 3")

	await walk_through(2)
	check(loader.current_room.id == 2, "door 1 -> 2 loads room 2")
	var key = room_nodes_of(Pickup).filter(func(p): return p.spawnable.type == "key")[0]
	player.position = key.position
	await frames(4)
	check(player.has_key("key_1"), "picked up key_1")

	await walk_through(1)
	check(loader.current_room.id == 1, "back to room 1")
	await walk_through(2)
	check(room_nodes_of(Pickup).filter(func(p): return p.spawnable.type == "key").is_empty(), "key does not respawn")
	await walk_through(1)

	var door = room_nodes_of(LockedDoor)[0]
	door._player = player
	door.unlock()
	await frames(2)
	await walk_through(3)
	check(loader.current_room.id == 3, "unlocked door 1 -> 3 loads room 3")
	check(room_nodes_of(LockedDoor).is_empty(), "door stays unlocked from room 3's side")

	await walk_through(4)
	check(loader.current_room.id == 4, "door 3 -> 4 loads end room 4")
	check(room_nodes_of(Exit).size() == 1, "exit spawned in end room")

	# Corridor: break the weak wall in room 0, walk through to room 2.
	loader.enter_room(d.get_room(0), d.get_room(0).center())
	await frames(2)
	var wall = room_nodes_of(WeakWall)[0]
	wall.take_hit(3)
	await frames(2)
	await walk_through(2)
	check(loader.current_room.id == 2, "broken weak wall: corridor 0 -> 2 works")
	check(room_nodes_of(WeakWall).is_empty(), "corridor open from room 2's side too")

	# Real walking: stand next to room 0's right door and hold "move_right".
	loader.enter_room(d.get_room(0), d.get_room(0).center())
	await frames(2)
	var o := opening_to(1)
	player.position = map.map_to_local(o.tile + Vector2i(-3, 0))
	await hold("move_right")
	check(loader.current_room.id == 1, "walking right into the door loads room 1")

	# Real walking into the locked door (room 1 -> 3, still locked in a fresh load? no: unlocked above),
	# so walk into room 4's top door from below instead to check walls don't block doors.
	loader.enter_room(d.get_room(4), d.get_room(4).center())
	await frames(2)
	o = opening_to(3)
	player.position = map.map_to_local(o.tile + Vector2i(0, 3))
	await hold("move_up")
	check(loader.current_room.id == 3, "walking up into the door loads room 3")

	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
