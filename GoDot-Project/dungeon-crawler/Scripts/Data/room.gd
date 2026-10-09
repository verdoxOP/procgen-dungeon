class_name Room
extends RefCounted

var id: int
# Floor tiles only. Walls are added around this by the layout stage.
var rect: Rect2i


static func from_dict(d: Dictionary) -> Room:
	var r := Room.new()
	r.id = int(d.get("id", 0))
	r.rect = Rect2i(
		int(d.get("x", 0)), int(d.get("y", 0)),
		int(d.get("width", 0)), int(d.get("height", 0)))
	return r


func center() -> Vector2i:
	return rect.position + rect.size / 2
