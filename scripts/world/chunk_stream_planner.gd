class_name ChunkStreamPlanner
extends RefCounted

const ACTIVE_RADIUS := 2
const PRELOAD_RADIUS := 3
const CACHE_RADIUS := 4


static func coordinates_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			result.append(Vector2i(x, y))
	return result


static func chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	var delta := (a - b).abs()
	return maxi(delta.x, delta.y)


static func priority_score(chunk: Vector2i, center: Vector2i, movement_direction: Vector2i) -> float:
	var delta := chunk - center
	var distance := Vector2(delta).length()
	if movement_direction != Vector2i.ZERO:
		var direction_bias := Vector2(delta).dot(Vector2(movement_direction).normalized())
		distance -= direction_bias * 0.18
	return distance


static func trim_to_cache_radius(chunk_coordinates: Array[Vector2i], center: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for chunk in chunk_coordinates:
		if chebyshev_distance(chunk, center) <= CACHE_RADIUS:
			result.append(chunk)
	return result
