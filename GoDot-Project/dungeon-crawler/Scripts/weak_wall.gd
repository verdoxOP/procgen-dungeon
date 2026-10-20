class_name WeakWall
extends StaticBody2D

# Emitted with the wall's tile when it breaks. The loader turns that tile into floor.
signal broken(tile: Vector2i)

const TILESET := preload("res://Assets/Dungeon_Tileset.png")
const WALL_TILE := Vector2i(2, 0)
const TILE_SIZE := 16

# Set before adding the wall to the scene.
var tile: Vector2i
var health := 3


# Looks exactly like a normal wall, so the corridor behind it stays a secret.
func _ready() -> void:
	var texture := AtlasTexture.new()
	texture.atlas = TILESET
	texture.region = Rect2(Vector2(WALL_TILE * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))
	var sprite := Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)

	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)


# Called by Arrow.
func take_hit(damage: int) -> void:
	health -= damage
	# Short red flash so the player notices this wall is different.
	modulate = Color(1.5, 0.6, 0.6)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)
	if health <= 0:
		broken.emit(tile)
		queue_free()
