class_name Door
extends RefCounted

var position: Vector2i
var locked: bool
var key_id: String


static func from_dict(d: Dictionary) -> Door:
	var door := Door.new()
	door.position = Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))
	door.locked = bool(d.get("locked", false))
	door.key_id = str(d.get("key_id", ""))
	return door
