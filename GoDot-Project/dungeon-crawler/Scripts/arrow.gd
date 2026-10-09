class_name Arrow
extends Area2D

const TEXTURE := preload("res://Assets/arrow/Just_arrow.png")
const SPEED := 200.0
const LIFETIME := 2.0

# Set before adding the arrow to the scene.
var direction := Vector2.RIGHT
var damage := 1

var _age := 0.0


# Built in code like Pickup: a sprite and a small hitbox.
func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	add_child(sprite)
	# The sprite points down, so turn it from "down" to the flight direction.
	rotation = direction.angle() - PI / 2
	z_index = 1

	var rect := RectangleShape2D.new()
	rect.size = Vector2(4, 4)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


# Anything solid stops the arrow. Things that can be hit (enemies, weak walls)
# get a take_hit(damage) function.
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		return
	if body.has_method("take_hit"):
		body.take_hit(damage)
	queue_free()
