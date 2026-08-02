class_name EnemySpawnPlanner
extends RefCounted

var _world_seed: int
var _catalog: EnemyCatalog
var _biome_catalog := BiomeCatalog.new()
var _terrain_generator: TerrainGenerator
var _resource_generator: ResourceGenerator
var _cache: Dictionary = {}


func _init(world_seed: int, catalog := EnemyCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	_terrain_generator = TerrainGenerator.new(world_seed)
	_resource_generator = ResourceGenerator.new(world_seed)


func candidates_for_chunk(chunk_position: Vector2i) -> Array[Dictionary]:
	if _cache.has(chunk_position):
		return (_cache[chunk_position] as Array).duplicate(true)
	var result: Array[Dictionary] = []
	var occupied_tiles := {}
	for slot in _catalog.candidate_slots_per_chunk():
		var stable_hash := WorldSeed.from_text("%d|enemy-spawn|%d|%d|%d" % [_world_seed, chunk_position.x, chunk_position.y, slot])
		var spawn_roll := float(stable_hash & 0xffff) / 65536.0
		if spawn_roll >= _catalog.spawn_chance():
			continue
		var local := Vector2i(2 + posmod(int(stable_hash >> 16), WorldCoordinates.CHUNK_SIZE - 4), 2 + posmod(int(stable_hash >> 32), WorldCoordinates.CHUNK_SIZE - 4))
		var world_tile := WorldCoordinates.chunk_local_to_tile(chunk_position, local)
		if occupied_tiles.has(world_tile) or _terrain_generator.terrain_at(world_tile) != ChunkData.Terrain.LAND:
			continue
		if not _resource_generator.candidate_at_world_tile(world_tile, _terrain_generator).is_empty():
			continue
		var biome_id := _biome_catalog.id_for_code(_terrain_generator.biome_at(world_tile))
		var enemy_roll := float((stable_hash >> 48) & 0xffff) / 65536.0
		var enemy_id := _catalog.enemy_id_for_biome(biome_id, enemy_roll)
		if enemy_id.is_empty():
			continue
		occupied_tiles[world_tile] = true
		result.append({
			"spawn_id": "surface:%d:%d:%s" % [world_tile.x, world_tile.y, enemy_id],
			"enemy_id": enemy_id,
			"biome_id": biome_id,
			"chunk_position": chunk_position,
			"world_tile": world_tile,
			"world_position": WorldCoordinates.tile_to_world_pixel(world_tile, true),
		})
		if result.size() >= _catalog.maximum_per_chunk():
			break
	_cache[chunk_position] = result.duplicate(true)
	return result


func cache_size() -> int:
	return _cache.size()


func retain_chunks(coordinates: Array[Vector2i]) -> void:
	var keep := {}
	for coordinate in coordinates:
		keep[coordinate] = true
	for coordinate_value in _cache.keys():
		if not keep.has(coordinate_value):
			_cache.erase(coordinate_value)
