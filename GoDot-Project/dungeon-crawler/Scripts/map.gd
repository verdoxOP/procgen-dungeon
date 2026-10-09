class_name Map
extends TileMapLayer

const SOURCE_ID := 0
const FLOOR_TILE := Vector2i(2, 2)
const WALL_TILE := Vector2i(2, 0)

const NEIGHBOURS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0),                   Vector2i(1, 0),
	Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1),
]

var _floor_tiles := {}


# Stage 5 + 6: turn the dungeon data into tiles and draw them.
func build(dungeon: Dungeon) -> void:
	clear()
	var floor_tiles := collect_floor(dungeon)
	var wall_tiles := collect_walls(floor_tiles)
	_floor_tiles = floor_tiles

	for pos in floor_tiles:
		set_cell(pos, SOURCE_ID, FLOOR_TILE)
	for pos in wall_tiles:
		set_cell(pos, SOURCE_ID, WALL_TILE)


# A room including its walls, in pixels.
func room_world_rect(room: Room) -> Rect2:
	var tiles := room.rect.grow(1)
	var tile_size := Vector2(tile_set.tile_size)
	return Rect2(position + Vector2(tiles.position) * tile_size, Vector2(tiles.size) * tile_size)


# What the player sees while in this room: the room with its walls, plus the
# paths leading out of it with their walls, so doors at the far end are visible.
func visible_tiles(room: Room, dungeon: Dungeon) -> Dictionary:
	var tiles := {}
	var area := room.rect.grow(1)
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			tiles[Vector2i(x, y)] = true

	for connection in dungeon.connections:
		if connection.from_room_id != room.id and connection.to_room_id != room.id:
			continue
		for tile in connection.path:
			tiles[tile] = true
			for offset in NEIGHBOURS:
				var n: Vector2i = tile + offset
				# Only the path's walls, not the floor of the room on the other side.
				if not _floor_tiles.has(n):
					tiles[n] = true
	return tiles


# Every walkable tile. Used as a set: only the keys matter.
func collect_floor(dungeon: Dungeon) -> Dictionary:
	var floor_tiles := {}
	for room in dungeon.rooms:
		for x in range(room.rect.position.x, room.rect.end.x):
			for y in range(room.rect.position.y, room.rect.end.y):
				floor_tiles[Vector2i(x, y)] = true
	for connection in dungeon.connections:
		for tile in connection.path:
			floor_tiles[tile] = true
	return floor_tiles


# A wall goes on every non-floor tile that touches floor (also diagonally).
func collect_walls(floor_tiles: Dictionary) -> Dictionary:
	var wall_tiles := {}
	for pos in floor_tiles:
		for offset in NEIGHBOURS:
			var n: Vector2i = pos + offset
			if not floor_tiles.has(n):
				wall_tiles[n] = true
	return wall_tiles
