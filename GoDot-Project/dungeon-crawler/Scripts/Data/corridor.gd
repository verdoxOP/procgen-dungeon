class_name Corridor
extends RefCounted

# A hidden extra door between two rooms that aren't directly connected, so the
# dungeon gets a shortcut / alternate route. Both sides are behind a weak wall.
var id: int
var from_room_id: int
var to_room_id: int
var from_wall: String
var to_wall: String

# Filled in by Dungeon.place_openings(), not part of the JSON.
var from_tile: Vector2i
var to_tile: Vector2i
# True once a weak wall on either side is broken. Then both sides are open.
var opened := false


static func from_dict(d: Dictionary) -> Corridor:
	var c := Corridor.new()
	c.id = int(d.get("id", 0))
	c.from_room_id = int(d.get("from", 0))
	c.to_room_id = int(d.get("to", 0))
	c.from_wall = str(d.get("from_wall", ""))
	c.to_wall = str(d.get("to_wall", ""))
	return c
