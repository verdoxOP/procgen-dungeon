class_name Map
extends TileMapLayer

const SOURCE_ID := 0
const FLOOR_TILE := Vector2i(2, 2)
const WALL_TILE := Vector2i(2, 0)


# Stage 5 + 6: turn one room into tiles and draw it. Only the room the player is
# in exists, every room is its own screen. Doors are gaps in the wall ring.
func build_room(room: Room, dungeon: Dungeon) -> void:
	clear()
	var area := room.rect.grow(1)
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			var pos := Vector2i(x, y)
			set_cell(pos, SOURCE_ID, FLOOR_TILE if room.rect.has_point(pos) else WALL_TILE)

	for opening in dungeon.openings(room.id):
		var passage = opening.passage
		# Closed corridors: a WeakWall node takes the tile, so leave it empty.
		if passage is Corridor and not passage.opened:
			erase_cell(opening.tile)
		else:
			set_cell(opening.tile, SOURCE_ID, FLOOR_TILE)


# Turns a tile into floor, e.g. after a weak wall is broken.
func open_tile(pos: Vector2i) -> void:
	set_cell(pos, SOURCE_ID, FLOOR_TILE)


# A rectangle of tiles in pixels.
func tiles_world_rect(tiles: Rect2i) -> Rect2:
	var tile_size := Vector2(tile_set.tile_size)
	return Rect2(position + Vector2(tiles.position) * tile_size, Vector2(tiles.size) * tile_size)


# A room including its walls, in pixels.
func room_world_rect(room: Room) -> Rect2:
	return tiles_world_rect(room.rect.grow(1))


# What the player sees while in this room: the room with its walls.
func visible_tiles(room: Room) -> Dictionary:
	var tiles := {}
	var area := room.rect.grow(1)
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			tiles[Vector2i(x, y)] = true
	return tiles
