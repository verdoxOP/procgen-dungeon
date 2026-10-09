class_name Connection
extends RefCounted

var from_room_id: int
var to_room_id: int
# Floor tiles between the two rooms, in walking order. Outside rooms only.
var path: Array[Vector2i] = []
# null when the connection has no door.
var door: Door


static func from_dict(d: Dictionary) -> Connection:
	var c := Connection.new()
	c.from_room_id = int(d.get("from", 0))
	c.to_room_id = int(d.get("to", 0))
	for tile in d.get("path", []):
		c.path.append(Vector2i(int(tile[0]), int(tile[1])))
	var door_dict = d.get("door")
	if door_dict is Dictionary:
		c.door = Door.from_dict(door_dict)
	return c
