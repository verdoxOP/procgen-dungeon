class_name Spawnable
extends RefCounted

# "enemy", "health", "ammo", "key" or "buff".
var type: String
var position: Vector2i

# Only the fields that belong to the type are filled in.
var amount: int        # health, ammo
var key_id: String     # key
var buff: String       # buff
var enemy: String      # enemy
var behaviour: String  # enemy


static func from_dict(d: Dictionary) -> Spawnable:
	var s := Spawnable.new()
	s.type = str(d.get("type", ""))
	s.position = Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))
	s.amount = int(d.get("amount", 0))
	s.key_id = str(d.get("key_id", ""))
	s.buff = str(d.get("buff", ""))
	s.enemy = str(d.get("enemy", ""))
	s.behaviour = str(d.get("behaviour", ""))
	return s
