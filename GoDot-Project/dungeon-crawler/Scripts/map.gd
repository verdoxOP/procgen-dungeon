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
	# Weak walls are separate WeakWall nodes, so leave their tiles empty.
	for corridor in dungeon.corridors:
		for tile in corridor.weak_walls:
			wall_tiles.erase(tile)
	_floor_tiles = floor_tiles

	for pos in floor_tiles:
		set_cell(pos, SOURCE_ID, FLOOR_TILE)
	for pos in wall_tiles:
		set_cell(pos, SOURCE_ID, WALL_TILE)


# Turns a tile into floor, e.g. after a weak wall is broken.
func open_tile(pos: Vector2i) -> void:
	_floor_tiles[pos] = true
	set_cell(pos, SOURCE_ID, FLOOR_TILE)


# A rectangle of tiles in pixels.
func tiles_world_rect(tiles: Rect2i) -> Rect2:
	var tile_size := Vector2(tile_set.tile_size)
	return Rect2(position + Vector2(tiles.position) * tile_size, Vector2(tiles.size) * tile_size)


# A room including its walls, in pixels.
func room_world_rect(room: Room) -> Rect2:
	return tiles_world_rect(room.rect.grow(1))


# A corridor including its walls, in pixels.
func corridor_world_rect(corridor: Corridor) -> Rect2:
	return tiles_world_rect(corridor.bounds().grow(1))


# What the player sees while in this room: the room with its walls, plus the
# paths leading out of it with their walls, so doors at the far end are visible.
# Corridors only show up once one of their weak walls is broken.
func visible_tiles(room: Room, dungeon: Dungeon) -> Dictionary:
	var tiles := {}
	var area := room.rect.grow(1)
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			tiles[Vector2i(x, y)] = true

	for connection in dungeon.connections:
		if connection.from_room_id == room.id or connection.to_room_id == room.id:
			add_path_with_walls(tiles, connection.path)
	for corridor in dungeon.corridors:
		if (corridor.from_room_id == room.id or corridor.to_room_id == room.id) and is_opened(corridor):
			add_path_with_walls(tiles, corridor.path)
	return tiles


# What the player sees while in a corridor: just the corridor and its walls.
func corridor_visible_tiles(corridor: Corridor) -> Dictionary:
	var tiles := {}
	add_path_with_walls(tiles, corridor.path)
	return tiles


func add_path_with_walls(tiles: Dictionary, path: Array[Vector2i]) -> void:
	for tile in path:
		tiles[tile] = true
		for offset in NEIGHBOURS:
			var n: Vector2i = tile + offset
			# Only the path's walls, not the floor of the room on the other side.
			if not _floor_tiles.has(n):
				tiles[n] = true


# True once at least one weak wall of the corridor is broken.
func is_opened(corridor: Corridor) -> bool:
	for tile in corridor.weak_walls:
		if _floor_tiles.has(tile):
			return true
	return false


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
	# Corridor tiles are floor too, except the weak walls (those open when broken).
	for corridor in dungeon.corridors:
		for tile in corridor.path:
			if not corridor.weak_walls.has(tile):
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
