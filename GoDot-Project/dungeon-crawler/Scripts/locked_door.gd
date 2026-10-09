class_name LockedDoor
extends StaticBody2D

const TILESET := preload("res://Assets/Dungeon_Tileset.png")
const DOOR_TILE := Vector2i(7, 3)
const TILE_SIZE := 16

# Set before adding the door to the scene.
var door: Door

# The player while standing next to the door, otherwise null.
var _player: Player


# Built in code like Pickup: a sprite, a solid body, and a slightly bigger area
# that notices the player standing next to the door.
func _ready() -> void:
	var texture := AtlasTexture.new()
	texture.atlas = TILESET
	texture.region = Rect2(Vector2(DOOR_TILE * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
	var sprite := Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)

	var solid := RectangleShape2D.new()
	solid.size = Vector2(TILE_SIZE, TILE_SIZE)
	var solid_shape := CollisionShape2D.new()
	solid_shape.shape = solid
	add_child(solid_shape)

	var detector := Area2D.new()
	var reach := RectangleShape2D.new()
	reach.size = Vector2(TILE_SIZE + 8, TILE_SIZE + 8)
	var reach_shape := CollisionShape2D.new()
	reach_shape.shape = reach
	detector.add_child(reach_shape)
	add_child(detector)
	detector.body_entered.connect(_on_body_entered)
	detector.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player != null and _player.has_key(door.key_id) and Input.is_action_just_pressed("interact"):
		unlock()


func unlock() -> void:
	_player.use_key(door.key_id)
	hud().hide_prompt()
	queue_free()


func hud() -> Hud:
	return get_tree().get_first_node_in_group("hud")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body
		hud().show_prompt("[E] Use key" if _player.has_key(door.key_id) else "Locked")


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		hud().hide_prompt()
