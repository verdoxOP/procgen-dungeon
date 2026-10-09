class_name Corridor
extends RefCounted

var id: int
var from_room_id: int
var to_room_id: int
# Floor tiles in walking order, including the weak walls.
var path: Array[Vector2i] = []
# Breakable walls hiding the corridor, usually the first and last path tile.
var weak_walls: Array[Vector2i] = []


static func from_dict(d: Dictionary) -> Corridor:
	var c := Corridor.new()
	c.id = int(d.get("id", 0))
	c.from_room_id = int(d.get("from", 0))
	c.to_room_id = int(d.get("to", 0))
	for tile in d.get("path", []):
		c.path.append(Vector2i(int(tile[0]), int(tile[1])))
	for tile in d.get("weak_walls", []):
		c.weak_walls.append(Vector2i(int(tile[0]), int(tile[1])))
	return c


# The smallest rectangle (in tiles) around the whole path.
func bounds() -> Rect2i:
	var rect := Rect2i(path[0], Vector2i.ONE)
	for tile in path:
		rect = rect.merge(Rect2i(tile, Vector2i.ONE))
	return rect
