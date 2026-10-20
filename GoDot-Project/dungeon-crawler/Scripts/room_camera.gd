class_name RoomCamera
extends Camera2D

# Tiles that are not covered by the black mask (used as a set).
var _visible_tiles := {}
var _tile_size := Vector2(16, 16)


func _ready() -> void:
	# Draw the mask on top of the map (and later the player/enemies).
	z_index = 100


# Centre on an area (a room or corridor) and zoom so it fills the screen.
# world_rect is the area in pixels, see Map.room_world_rect() / corridor_world_rect().
# visible_tiles is everything that should stay visible, see Map.visible_tiles().
func focus(world_rect: Rect2, visible_tiles: Dictionary, tile_size: Vector2) -> void:
	_visible_tiles = visible_tiles
	_tile_size = tile_size
	position = world_rect.get_center()

	var view := get_viewport_rect().size
	var fit := minf(view.x / world_rect.size.x, view.y / world_rect.size.y)
	# Whole numbers only, otherwise pixel art gets uneven pixels.
	var z := maxf(floorf(fit), 1.0)
	zoom = Vector2(z, z)

	queue_redraw()


# Black over every tile on screen that isn't visible.
# Assumes the Map is at (0, 0), so tile * tile_size is the world position.
func _draw() -> void:
	if _visible_tiles.is_empty():
		return
	var half_view := get_viewport_rect().size / zoom / 2.0
	var first := Vector2i(((position - half_view) / _tile_size).floor()) - Vector2i.ONE
	var last := Vector2i(((position + half_view) / _tile_size).ceil()) + Vector2i.ONE
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			if not _visible_tiles.has(Vector2i(x, y)):
				# _draw() uses the camera's local space, so shift by the camera position.
				draw_rect(Rect2(Vector2(x, y) * _tile_size - position, _tile_size), Color.BLACK)
