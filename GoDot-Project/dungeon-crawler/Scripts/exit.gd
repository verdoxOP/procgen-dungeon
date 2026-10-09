class_name Exit
extends Area2D

# Emitted when the player uses the exit. The loader decides what happens next.
signal used

const TILESET := preload("res://Assets/Dungeon_Tileset.png")
const LADDER_TILE := Vector2i(9, 3)
const TILE_SIZE := 16

# The player while standing on the exit, otherwise null.
var _player: Player


# Built in code like the door: a ladder sprite and an area the player can stand in.
func _ready() -> void:
	var texture := AtlasTexture.new()
	texture.atlas = TILESET
	texture.region = Rect2(Vector2(LADDER_TILE * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
	var sprite := Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)

	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player != null and Input.is_action_just_pressed("interact"):
		hud().hide_prompt()
		used.emit()


func hud() -> Hud:
	return get_tree().get_first_node_in_group("hud")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body
		hud().show_prompt("[E] Descend")


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		hud().hide_prompt()
