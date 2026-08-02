class_name RuinPlanner
extends RefCounted

const ORIGIN_CHUNK := Vector2i(-1, -4)

var _world_seed := 0
var _catalog: MilestoneCatalog
var _biomes := BiomeCatalog.new()


func _init(world_seed: int, catalog := MilestoneCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog


func plan() -> Dictionary:
	if _catalog == null or not _catalog.is_valid():
		return {}
	var minimum_radius := int(_catalog.ruin_value("search_minimum_chunk_radius", 3))
	var maximum_radius := int(_catalog.ruin_value("search_maximum_chunk_radius", 6))
	var preferred := _catalog.ruin_value("preferred_biomes", []) as Array
	var generator := TerrainGenerator.new(_world_seed)
	var best: Dictionary = {}
	var best_rank := 1000000
	var best_score := 0x7fffffffffffffff
	for y in range(-maximum_radius, maximum_radius + 1):
		for x in range(-maximum_radius, maximum_radius + 1):
			var distance := maxi(absi(x), absi(y))
			if distance < minimum_radius or distance > maximum_radius:
				continue
			var chunk_coordinate := ORIGIN_CHUNK + Vector2i(x, y)
			var world_tile: Vector2i = _land_sample_in_chunk(generator, chunk_coordinate)
			if world_tile == Vector2i(0x7fffffff, 0x7fffffff):
				continue
			var biome_id := String(_biomes.id_for_code(generator.biome_at(world_tile)))
			var rank := preferred.find(biome_id)
			if rank < 0:
				rank = preferred.size() + 1
			var score := WorldSeed.from_text("%d|ruin|%d|%d" % [_world_seed, chunk_coordinate.x, chunk_coordinate.y]) & 0x7fffffffffffffff
			if rank > best_rank or (rank == best_rank and score >= best_score):
				continue
			best_rank = rank
			best_score = score
			best = {
				"id": "ruin_0",
				"chunk": chunk_coordinate,
				"world_tile": world_tile,
				"world_position": WorldCoordinates.tile_to_world_pixel(world_tile, true),
				"biome_id": biome_id,
				"stable_score": score,
			}
	return best


func _land_sample_in_chunk(generator: TerrainGenerator, chunk_coordinate: Vector2i) -> Vector2i:
	var origin := chunk_coordinate * WorldCoordinates.CHUNK_SIZE
	var samples := [
		Vector2i(16, 16), Vector2i(8, 8), Vector2i(24, 8), Vector2i(8, 24), Vector2i(24, 24),
		Vector2i(16, 8), Vector2i(16, 24), Vector2i(8, 16), Vector2i(24, 16),
	]
	for local in samples:
		var world_tile: Vector2i = origin + (local as Vector2i)
		if generator.terrain_at(world_tile) == ChunkData.Terrain.LAND:
			return world_tile
	return Vector2i(0x7fffffff, 0x7fffffff)
