class_name Door
extends RefCounted

# A door between two rooms (one edge of the backbone). Walking through it loads the other room.
var from_room_id: int
var to_room_id: int
# "top", "bottom", "left" or "right": the wall of each room the door is in.
var from_wall: String
var to_wall: String
var locked: bool
var key_id: String

# Filled in by Dungeon.place_openings(), not part of the JSON.
var from_tile: Vector2i
var to_tile: Vector2i


static func from_dict(d: Dictionary) -> Door:
	var door := Door.new()
	door.from_room_id = int(d.get("from", 0))
	door.to_room_id = int(d.get("to", 0))
	door.from_wall = str(d.get("from_wall", ""))
	door.to_wall = str(d.get("to_wall", ""))
	door.locked = bool(d.get("locked", false))
	door.key_id = str(d.get("key_id", ""))
	return door
