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
var continental_map := PackedByteArray()
var elevation_map := PackedByteArray()
var erosion_map := PackedByteArray()
var temperature_map := PackedByteArray()
var moisture_map := PackedByteArray()
var biome_map := PackedByteArray()
var resource_codes := PackedByteArray()
var resource_local_x := PackedByteArray()
var resource_local_y := PackedByteArray()
var resource_variants := PackedByteArray()
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


func continental_at(local: Vector2i) -> float:
	return _sample_map(continental_map, local, "continental")


func erosion_at(local: Vector2i) -> float:
	return _sample_map(erosion_map, local, "erosion")


func temperature_at(local: Vector2i) -> float:
	return _sample_map(temperature_map, local, "temperature")


func moisture_at(local: Vector2i) -> float:
	return _sample_map(moisture_map, local, "moisture")


func biome_at(local: Vector2i) -> int:
	if not _is_local_valid(local):
		push_error("Chunk local coordinate is outside 32×32 bounds: %s" % local)
		return 0
	return int(biome_map[_index(local)])


func terrain_counts() -> PackedInt32Array:
	var counts := PackedInt32Array([0, 0, 0, 0])
	for terrain_value in base_tiles:
		counts[terrain_value] += 1
	return counts


func biome_counts(biome_count: int) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(biome_count)
	for biome_value in biome_map:
		if biome_value < biome_count:
			counts[biome_value] += 1
	return counts


func resource_count() -> int:
	return resource_codes.size()


func add_resource(local: Vector2i, resource_code: int, variant: int) -> void:
	if not _is_local_valid(local):
		push_error("Cannot add resource outside 32×32 chunk bounds: %s" % local)
		return
	resource_codes.append(resource_code)
	resource_local_x.append(local.x)
	resource_local_y.append(local.y)
	resource_variants.append(variant)


func resource_local_at(index: int) -> Vector2i:
	if index < 0 or index >= resource_count():
		push_error("Resource index is outside chunk resource array: %d" % index)
		return Vector2i.ZERO
	return Vector2i(resource_local_x[index], resource_local_y[index])


func resource_world_tile_at(index: int) -> Vector2i:
	return WorldCoordinates.chunk_local_to_tile(chunk_position, resource_local_at(index))


func resource_code_at(index: int) -> int:
	if index < 0 or index >= resource_count():
		push_error("Resource index is outside chunk resource array: %d" % index)
		return 0
	return int(resource_codes[index])


func resource_variant_at(index: int) -> int:
	if index < 0 or index >= resource_count():
		push_error("Resource index is outside chunk resource array: %d" % index)
		return 0
	return int(resource_variants[index])


func has_resource_at(local: Vector2i) -> bool:
	for index in resource_count():
		if resource_local_x[index] == local.x and resource_local_y[index] == local.y:
			return true
	return false


func resource_key_at(index: int) -> String:
	var world_tile := resource_world_tile_at(index)
	return "%d:%d:%d" % [world_tile.x, world_tile.y, resource_code_at(index)]


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
	context.update(continental_map)
	context.update(elevation_map)
	context.update(erosion_map)
	context.update(temperature_map)
	context.update(moisture_map)
	context.update(biome_map)
	context.update(resource_codes)
	context.update(resource_local_x)
	context.update(resource_local_y)
	context.update(resource_variants)
	checksum = context.finish().hex_encode().substr(0, 16)


func _sample_map(values: PackedByteArray, local: Vector2i, map_name: String) -> float:
	if not _is_local_valid(local):
		push_error("Chunk local coordinate is outside 32×32 bounds for %s map: %s" % [map_name, local])
		return 0.0
	return float(values[_index(local)]) / 255.0


func _index(local: Vector2i) -> int:
	return local.y * WorldCoordinates.CHUNK_SIZE + local.x


func _is_local_valid(local: Vector2i) -> bool:
	return local.x >= 0 and local.y >= 0 and local.x < WorldCoordinates.CHUNK_SIZE and local.y < WorldCoordinates.CHUNK_SIZE
