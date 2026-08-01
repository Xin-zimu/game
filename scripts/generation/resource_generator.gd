class_name ResourceGenerator
extends RefCounted

var _world_seed: int
var _catalog: ResourceCatalog
var _biome_catalog: BiomeCatalog
var _candidate_cache: Dictionary = {}


func _init(world_seed: int, catalog := ResourceCatalog.new(), biome_catalog := BiomeCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	_biome_catalog = biome_catalog


func generate_for_chunk(chunk_position: Vector2i, terrain_generator: TerrainGenerator) -> Array[Dictionary]:
	_candidate_cache.clear()
	var result: Array[Dictionary] = []
	var cell_size := _catalog.candidate_cell_size()
	var first_tile := chunk_position * WorldCoordinates.CHUNK_SIZE
	var last_tile := first_tile + Vector2i.ONE * (WorldCoordinates.CHUNK_SIZE - 1)
	var first_cell := Vector2i(floori(float(first_tile.x) / cell_size), floori(float(first_tile.y) / cell_size))
	var last_cell := Vector2i(floori(float(last_tile.x) / cell_size), floori(float(last_tile.y) / cell_size))
	for cell_y in range(first_cell.y, last_cell.y + 1):
		for cell_x in range(first_cell.x, last_cell.x + 1):
			var cell := Vector2i(cell_x, cell_y)
			var candidate := _candidate_at_cell(cell, terrain_generator)
			if candidate.is_empty() or not _candidate_is_accepted(cell, candidate, terrain_generator):
				continue
			var world_tile := candidate["world_tile"] as Vector2i
			if world_tile.x < first_tile.x or world_tile.y < first_tile.y or world_tile.x > last_tile.x or world_tile.y > last_tile.y:
				continue
			result.append({
				"local": world_tile - first_tile,
				"world_tile": world_tile,
				"code": int(candidate["code"]),
				"variant": int(candidate["variant"]),
			})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_local := a["local"] as Vector2i
		var b_local := b["local"] as Vector2i
		return a_local.y < b_local.y or (a_local.y == b_local.y and a_local.x < b_local.x)
	)
	if result.size() > _catalog.max_resources_per_chunk():
		result.resize(_catalog.max_resources_per_chunk())
	return result


func candidate_at_world_tile(world_tile: Vector2i, terrain_generator: TerrainGenerator) -> Dictionary:
	var cell_size := _catalog.candidate_cell_size()
	var cell := Vector2i(floori(float(world_tile.x) / cell_size), floori(float(world_tile.y) / cell_size))
	var candidate := _candidate_at_cell(cell, terrain_generator)
	if candidate.is_empty() or candidate["world_tile"] != world_tile:
		return {}
	return candidate if _candidate_is_accepted(cell, candidate, terrain_generator) else {}


func resource_key(world_tile: Vector2i, resource_code: int) -> String:
	return "%d:%d:%d" % [world_tile.x, world_tile.y, resource_code]


func _candidate_at_cell(cell: Vector2i, terrain_generator: TerrainGenerator) -> Dictionary:
	if _candidate_cache.has(cell):
		return _candidate_cache[cell] as Dictionary
	var stable_hash := WorldSeed.from_text("%d|resource-cell|%d|%d|generation:%d" % [
		_world_seed,
		cell.x,
		cell.y,
		GameVersion.GENERATION_VERSION,
	])
	var cell_size := _catalog.candidate_cell_size()
	var world_tile := cell * cell_size + Vector2i(
		int(stable_hash & 0xffff) % cell_size,
		int((stable_hash >> 16) & 0xffff) % cell_size
	)
	var terrain := terrain_generator.terrain_at(world_tile)
	if terrain == ChunkData.Terrain.DEEP_WATER or terrain == ChunkData.Terrain.SHALLOW_WATER:
		_candidate_cache[cell] = {}
		return {}
	var biome_code := terrain_generator.biome_at(world_tile)
	var biome_id := _biome_catalog.id_for_code(biome_code)
	var roll := float((stable_hash >> 32) & 0xffffff) / 16777216.0
	var resource_code := _catalog.candidate_code_for_biome(biome_id, roll)
	if resource_code < 0:
		_candidate_cache[cell] = {}
		return {}
	var candidate := {
		"world_tile": world_tile,
		"code": resource_code,
		"variant": int((stable_hash >> 56) & 0x03),
		"rank": stable_hash,
		"minimum_distance": _catalog.minimum_distance_for_code(resource_code),
	}
	_candidate_cache[cell] = candidate
	return candidate


func _candidate_is_accepted(cell: Vector2i, candidate: Dictionary, terrain_generator: TerrainGenerator) -> bool:
	var cell_radius := ceili(float(_catalog.maximum_minimum_distance()) / _catalog.candidate_cell_size()) + 1
	var world_tile := candidate["world_tile"] as Vector2i
	var rank := int(candidate["rank"])
	for offset_y in range(-cell_radius, cell_radius + 1):
		for offset_x in range(-cell_radius, cell_radius + 1):
			if offset_x == 0 and offset_y == 0:
				continue
			var other_cell := cell + Vector2i(offset_x, offset_y)
			var other := _candidate_at_cell(other_cell, terrain_generator)
			if other.is_empty():
				continue
			var other_tile := other["world_tile"] as Vector2i
			var required_distance := maxi(int(candidate["minimum_distance"]), int(other["minimum_distance"]))
			if world_tile.distance_squared_to(other_tile) >= required_distance * required_distance:
				continue
			var other_rank := int(other["rank"])
			if other_rank < rank or (other_rank == rank and _cell_precedes(other_cell, cell)):
				return false
	return true


func _cell_precedes(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
