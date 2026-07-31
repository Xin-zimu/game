class_name ChunkData
extends RefCounted

enum Terrain {
	DEEP_WATER,
	SHALLOW_WATER,
	BEACH,
	LAND,
}

var chunk_position := Vector2i.ZERO
var world_layer: StringName = &"surface"
var generation_version := GameVersion.GENERATION_VERSION
var world_seed := 0
var base_tiles := PackedByteArray()
var elevation_map := PackedByteArray()
var checksum := ""


func tile_at(local: Vector2i) -> Terrain:
	if not _is_local_valid(local):
		push_error("Chunk local coordinate is outside 32×32 bounds: %s" % local)
		return Terrain.DEEP_WATER
	return base_tiles[_index(local)] as Terrain


func elevation_at(local: Vector2i) -> float:
	if not _is_local_valid(local):
		push_error("Chunk local coordinate is outside 32×32 bounds: %s" % local)
		return 0.0
	return float(elevation_map[_index(local)]) / 255.0


func terrain_counts() -> PackedInt32Array:
	var counts := PackedInt32Array([0, 0, 0, 0])
	for terrain_value in base_tiles:
		counts[terrain_value] += 1
	return counts


func finalize_checksum() -> void:
	var context := HashingContext.new()
	var error := context.start(HashingContext.HASH_SHA256)
	if error != OK:
		push_error("Unable to initialize chunk checksum: %s" % error_string(error))
		checksum = "invalid"
		return
	context.update(("%d|%s|%d|%d|%d|" % [
		world_seed,
		world_layer,
		chunk_position.x,
		chunk_position.y,
		generation_version,
	]).to_utf8_buffer())
	context.update(base_tiles)
	context.update(elevation_map)
	checksum = context.finish().hex_encode().substr(0, 16)


func _index(local: Vector2i) -> int:
	return local.y * WorldCoordinates.CHUNK_SIZE + local.x


func _is_local_valid(local: Vector2i) -> bool:
	return local.x >= 0 and local.y >= 0 and local.x < WorldCoordinates.CHUNK_SIZE and local.y < WorldCoordinates.CHUNK_SIZE
