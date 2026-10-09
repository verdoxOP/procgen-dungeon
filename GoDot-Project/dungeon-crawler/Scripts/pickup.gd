class_name Pickup
extends Area2D

const TEXTURES := {
	"health": preload("res://Assets/flasks/flasks_1_1.png"),
	"buff": preload("res://Assets/flasks/flasks_2_1.png"),
	"key": preload("res://Assets/keys/keys_1_1.png"),
	"ammo": preload("res://Assets/arrow/Just_arrow.png"),
}

# Set before adding the pickup to the scene.
var spawnable: Spawnable


# Built in code instead of a .tscn, since every pickup is just a sprite and a hitbox.
func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURES.get(spawnable.type)
	add_child(sprite)

	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 10)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.collect(spawnable)
		queue_free()
