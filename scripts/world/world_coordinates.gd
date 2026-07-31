class_name WorldCoordinates
extends RefCounted

const CHUNK_SIZE := 32
const TILE_SIZE := 32


static func tile_to_chunk(tile: Vector2i) -> Vector2i:
	return Vector2i(_floor_div(tile.x, CHUNK_SIZE), _floor_div(tile.y, CHUNK_SIZE))


static func tile_to_local(tile: Vector2i) -> Vector2i:
	return Vector2i(posmod(tile.x, CHUNK_SIZE), posmod(tile.y, CHUNK_SIZE))


static func chunk_local_to_tile(chunk: Vector2i, local: Vector2i) -> Vector2i:
	return chunk * CHUNK_SIZE + local


static func world_pixel_to_tile(world_pixel: Vector2) -> Vector2i:
	return Vector2i(floori(world_pixel.x / TILE_SIZE), floori(world_pixel.y / TILE_SIZE))


static func tile_to_world_pixel(tile: Vector2i, centered := false) -> Vector2:
	var pixel := Vector2(tile * TILE_SIZE)
	if centered:
		pixel += Vector2.ONE * TILE_SIZE * 0.5
	return pixel


static func chunk_pixel_rect(chunk: Vector2i) -> Rect2:
	var top_left := tile_to_world_pixel(chunk * CHUNK_SIZE)
	return Rect2(top_left, Vector2.ONE * CHUNK_SIZE * TILE_SIZE)


static func chunk_key(layer: StringName, chunk: Vector2i) -> String:
	return "%s_%d_%d" % [layer, chunk.x, chunk.y]


static func _floor_div(value: int, divisor: int) -> int:
	@warning_ignore("integer_division")
	var quotient: int = value / divisor
	if value < 0 and value % divisor != 0:
		quotient -= 1
	return quotient
