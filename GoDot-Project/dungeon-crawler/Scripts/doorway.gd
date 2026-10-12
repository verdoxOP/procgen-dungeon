class_name Doorway
extends Area2D

# Emitted when the player walks into the door tile. The loader loads the other room.
signal entered(opening: Dictionary)

# Smaller than a tile, so the player arriving next to a door doesn't touch it.
const SIZE := 10

# Set before adding the doorway to the scene. See Dungeon.openings().
var opening: Dictionary


# Built in code like Pickup: an invisible area on the door tile.
func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(SIZE, SIZE)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)

	# Right after a room loads, physics still has the player at the old room's door,
	# which can be on top of this one. Wait until the move has gone through.
	monitoring = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		entered.emit(opening)
