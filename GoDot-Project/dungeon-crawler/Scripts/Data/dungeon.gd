class_name Dungeon
extends RefCounted

var format_version: int
var dungeon_seed: int
var generator: String
var rooms: Array[Room] = []
var start_room_id: int
var end_room_id: int
var connections: Array[Connection] = []
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
	for connection_dict in d.get("connections", []):
		dungeon.connections.append(Connection.from_dict(connection_dict))
	for corridor_dict in d.get("corridors", []):
		dungeon.corridors.append(Corridor.from_dict(corridor_dict))
	for spawnable_dict in d.get("spawnables", []):
		dungeon.spawnables.append(Spawnable.from_dict(spawnable_dict))
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


# Returns the corridor this tile belongs to, or null.
func corridor_at(tile: Vector2i) -> Corridor:
	for corridor in corridors:
		if corridor.path.has(tile):
			return corridor
	return null
