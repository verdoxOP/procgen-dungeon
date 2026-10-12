class_name Dungeon
extends RefCounted

const WALLS: Array[String] = ["top", "bottom", "left", "right"]

var format_version: int
var dungeon_seed: int
var generator: String
var rooms: Array[Room] = []
var start_room_id: int
var end_room_id: int
var doors: Array[Door] = []
var corridors: Array[Corridor] = []
var spawnables: Array[Spawnable] = []


static func from_dict(d: Dictionary) -> Dungeon:
	var dungeon := Dungeon.new()
	dungeon.format_version = int(d.get("format_version", 0))
	dungeon.dungeon_seed = int(d.get("seed", 0))
	dungeon.generator = str(d.get("generator", ""))
	for room_dict in d.get("rooms", []):
		dungeon.rooms.append(Room.from_dict(room_dict))
	dungeon.start_room_id = int(d.get("start_room", 0))
	dungeon.end_room_id = int(d.get("end_room", 0))
	for door_dict in d.get("doors", []):
		dungeon.doors.append(Door.from_dict(door_dict))
	for corridor_dict in d.get("corridors", []):
		dungeon.corridors.append(Corridor.from_dict(corridor_dict))
	for spawnable_dict in d.get("spawnables", []):
		dungeon.spawnables.append(Spawnable.from_dict(spawnable_dict))
	dungeon.place_openings()
	return dungeon


# Returns null if no room has this id.
func get_room(id: int) -> Room:
	for room in rooms:
		if room.id == id:
			return room
	return null


# Returns the room containing this tile, or null if it's not inside a room.
func room_at(tile: Vector2i) -> Room:
	for room in rooms:
		if room.rect.has_point(tile):
			return room
	return null


# Everything leading out of a room: doors and corridors (hidden doors).
# Each entry is {"passage": Door or Corridor, "from": this room's id, "tile": wall tile
# in this room, "to": the other room's id, "arrive": tile the player lands on in the other room}.
func openings(room_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for passage in passages():
		if passage.from_room_id == room_id:
			result.append({"passage": passage, "from": room_id, "tile": passage.from_tile,
				"to": passage.to_room_id, "arrive": inside(passage.to_tile, passage.to_wall)})
		elif passage.to_room_id == room_id:
			result.append({"passage": passage, "from": room_id, "tile": passage.to_tile,
				"to": passage.from_room_id, "arrive": inside(passage.from_tile, passage.from_wall)})
	return result


# Doors and corridors together. Both have the same from/to/wall/tile fields.
func passages() -> Array:
	var result: Array = []
	result.append_array(doors)
	result.append_array(corridors)
	return result


# The JSON only says which wall a door is on. This picks the tile: doors on the
# same wall are spread out evenly along it, a single door sits in the middle.
func place_openings() -> void:
	for room in rooms:
		for wall in WALLS:
			# [passage, true if this room is the "from" side]
			var on_wall: Array = []
			for passage in passages():
				if passage.from_room_id == room.id and passage.from_wall == wall:
					on_wall.append([passage, true])
				if passage.to_room_id == room.id and passage.to_wall == wall:
					on_wall.append([passage, false])
			var length := room.rect.size.x if wall in ["top", "bottom"] else room.rect.size.y
			for i in on_wall.size():
				var offset := clampi(length * (i + 1) / (on_wall.size() + 1), 0, length - 1)
				var tile := wall_tile(room, wall, offset)
				if on_wall[i][1]:
					on_wall[i][0].from_tile = tile
				else:
					on_wall[i][0].to_tile = tile

	for passage in passages():
		for side in [[passage.from_room_id, passage.from_wall], [passage.to_room_id, passage.to_wall]]:
			if get_room(side[0]) == null:
				push_warning("Door/corridor points to missing room %d" % side[0])
			if not WALLS.has(side[1]):
				push_warning("Door/corridor of room %d has an invalid wall '%s'" % [side[0], side[1]])


# The tile in the wall ring around the room, `offset` tiles along that wall.
static func wall_tile(room: Room, wall: String, offset: int) -> Vector2i:
	var r := room.rect
	match wall:
		"top":
			return Vector2i(r.position.x + offset, r.position.y - 1)
		"bottom":
			return Vector2i(r.position.x + offset, r.end.y)
		"left":
			return Vector2i(r.position.x - 1, r.position.y + offset)
		_:
			return Vector2i(r.end.x, r.position.y + offset)


# The floor tile just inside a door, where the player appears.
static func inside(tile: Vector2i, wall: String) -> Vector2i:
	match wall:
		"top":
			return tile + Vector2i.DOWN
		"bottom":
			return tile + Vector2i.UP
		"left":
			return tile + Vector2i.RIGHT
		_:
			return tile + Vector2i.LEFT
