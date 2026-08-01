class_name TerrainGenerator
extends RefCounted

var _world_seed: int
var _catalog: BiomeCatalog
var _continental_noise := FastNoiseLite.new()
var _elevation_noise := FastNoiseLite.new()
var _erosion_noise := FastNoiseLite.new()
var _temperature_noise := FastNoiseLite.new()
var _moisture_noise := FastNoiseLite.new()
var _detail_noise := FastNoiseLite.new()


func _init(world_seed: int, biome_config_path := BiomeCatalog.DEFAULT_CONFIG_PATH) -> void:
	_world_seed = world_seed
	_catalog = BiomeCatalog.new(biome_config_path)
	_configure_noise(_continental_noise, &"continentalness", 0.0045, 3)
	_configure_noise(_elevation_noise, &"elevation", 0.0140, 4)
	_configure_noise(_erosion_noise, &"erosion", 0.0075, 3)
	_configure_noise(_temperature_noise, &"temperature", 0.0032, 3)
	_configure_noise(_moisture_noise, &"moisture", 0.0042, 3)
	_configure_noise(_detail_noise, &"detail", 0.0550, 2)


func generate_chunk(chunk_position: Vector2i, world_layer: StringName = &"surface") -> ChunkData:
	var result := ChunkData.new()
	result.chunk_position = chunk_position
	result.world_layer = world_layer
	result.world_seed = _world_seed
	var cell_count := WorldCoordinates.CHUNK_SIZE * WorldCoordinates.CHUNK_SIZE
	result.base_tiles.resize(cell_count)
	result.continental_map.resize(cell_count)
	result.elevation_map.resize(cell_count)
	result.erosion_map.resize(cell_count)
	result.temperature_map.resize(cell_count)
	result.moisture_map.resize(cell_count)
	result.biome_map.resize(cell_count)
	for local_y in WorldCoordinates.CHUNK_SIZE:
		for local_x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(local_x, local_y)
			var world_tile := WorldCoordinates.chunk_local_to_tile(chunk_position, local)
			var continental := continental_at(world_tile)
			var erosion := erosion_at(world_tile)
			var elevation := elevation_at(world_tile)
			var temperature := temperature_at(world_tile, elevation)
			var moisture := moisture_at(world_tile, continental)
			var terrain := _terrain_with_cleanup(world_tile, elevation)
			var biome := _biome_with_cleanup(world_tile, terrain, temperature, moisture, elevation, erosion)
			var index := local_y * WorldCoordinates.CHUNK_SIZE + local_x
			result.base_tiles[index] = terrain
			result.continental_map[index] = _quantize(continental)
			result.elevation_map[index] = _quantize(elevation)
			result.erosion_map[index] = _quantize(erosion)
			result.temperature_map[index] = _quantize(temperature)
			result.moisture_map[index] = _quantize(moisture)
			result.biome_map[index] = biome
	result.finalize_checksum()
	return result


func continental_at(world_tile: Vector2i) -> float:
	return _normalized_noise(_continental_noise, world_tile)


func erosion_at(world_tile: Vector2i) -> float:
	return _normalized_noise(_erosion_noise, world_tile)


func elevation_at(world_tile: Vector2i) -> float:
	var continental := continental_at(world_tile)
	var elevation := _normalized_noise(_elevation_noise, world_tile)
	var erosion := erosion_at(world_tile)
	var detail := _normalized_noise(_detail_noise, world_tile)
	return clampf(continental * 0.50 + elevation * 0.32 + (1.0 - erosion) * 0.10 + detail * 0.08, 0.0, 1.0)


func temperature_at(world_tile: Vector2i, elevation := -1.0) -> float:
	var resolved_elevation := elevation if elevation >= 0.0 else elevation_at(world_tile)
	var base_temperature := _normalized_noise(_temperature_noise, world_tile)
	var altitude_cooling := maxf(resolved_elevation - 0.56, 0.0) * 0.72
	return clampf(base_temperature - altitude_cooling, 0.0, 1.0)


func moisture_at(world_tile: Vector2i, continental := -1.0) -> float:
	var resolved_continental := continental if continental >= 0.0 else continental_at(world_tile)
	var base_moisture := _normalized_noise(_moisture_noise, world_tile)
	var ocean_influence := maxf(0.48 - resolved_continental, 0.0) * 0.28
	return clampf(base_moisture + ocean_influence, 0.0, 1.0)


func biome_at(world_tile: Vector2i) -> int:
	var elevation := elevation_at(world_tile)
	var terrain := _terrain_with_cleanup(world_tile, elevation)
	return _biome_with_cleanup(
		world_tile,
		terrain,
		temperature_at(world_tile, elevation),
		moisture_at(world_tile, continental_at(world_tile)),
		elevation,
		erosion_at(world_tile)
	)


func find_land_near(chunk: ChunkData, preferred_local := Vector2i(16, 16)) -> Vector2i:
	for radius in range(0, WorldCoordinates.CHUNK_SIZE):
		for y in range(preferred_local.y - radius, preferred_local.y + radius + 1):
			for x in range(preferred_local.x - radius, preferred_local.x + radius + 1):
				var local := Vector2i(x, y)
				if local.x < 1 or local.y < 1 or local.x >= WorldCoordinates.CHUNK_SIZE - 1 or local.y >= WorldCoordinates.CHUNK_SIZE - 1:
					continue
				if chunk.tile_at(local) >= ChunkData.Terrain.BEACH:
					return WorldCoordinates.chunk_local_to_tile(chunk.chunk_position, local)
	return WorldCoordinates.chunk_local_to_tile(chunk.chunk_position, preferred_local)


func _terrain_with_cleanup(world_tile: Vector2i, elevation: float) -> ChunkData.Terrain:
	var land_neighbors := 0
	var terrain_neighbors := PackedInt32Array([0, 0, 0, 0])
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			var neighbor_elevation := elevation_at(world_tile + Vector2i(offset_x, offset_y))
			if neighbor_elevation >= _catalog.threshold("coast"):
				land_neighbors += 1
			terrain_neighbors[_classify_terrain(neighbor_elevation)] += 1
	var center_terrain := _classify_terrain(elevation)
	var majority_terrain := center_terrain
	var majority_count := 0
	for terrain_index in terrain_neighbors.size():
		if terrain_neighbors[terrain_index] > majority_count:
			majority_count = terrain_neighbors[terrain_index]
			majority_terrain = terrain_index
	if majority_count >= _catalog.cleanup_value("terrain_majority", 6) and majority_terrain != center_terrain:
		return majority_terrain as ChunkData.Terrain
	if elevation >= _catalog.threshold("coast") and land_neighbors <= _catalog.cleanup_value("island_land_neighbors_max", 1):
		return ChunkData.Terrain.SHALLOW_WATER
	if elevation < _catalog.threshold("coast") and land_neighbors >= _catalog.cleanup_value("inlet_land_neighbors_min", 7):
		return ChunkData.Terrain.BEACH
	return _classify_terrain(elevation)


func _biome_with_cleanup(world_tile: Vector2i, terrain: ChunkData.Terrain, temperature: float, moisture: float, elevation: float, erosion: float) -> int:
	if terrain != ChunkData.Terrain.LAND:
		return _catalog.code_for_surface(_surface_for_terrain(terrain))
	var center_biome := _catalog.classify_land(temperature, moisture, elevation, erosion)
	var counts := PackedInt32Array()
	counts.resize(_catalog.biome_count())
	counts[center_biome] += 1
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			var neighbor_tile := world_tile + Vector2i(offset_x, offset_y)
			var neighbor_elevation := elevation_at(neighbor_tile)
			if _classify_terrain(neighbor_elevation) != ChunkData.Terrain.LAND:
				continue
			var neighbor_biome := _catalog.classify_land(
				temperature_at(neighbor_tile, neighbor_elevation),
				moisture_at(neighbor_tile, continental_at(neighbor_tile)),
				neighbor_elevation,
				erosion_at(neighbor_tile)
			)
			counts[neighbor_biome] += 1
	var majority_biome := center_biome
	var majority_count := counts[center_biome]
	for biome_code in counts.size():
		if counts[biome_code] > majority_count:
			majority_count = counts[biome_code]
			majority_biome = biome_code
	if majority_count >= _catalog.cleanup_value("biome_majority", 5):
		return majority_biome
	return center_biome


func _classify_terrain(elevation: float) -> ChunkData.Terrain:
	if elevation < _catalog.threshold("deep_water"):
		return ChunkData.Terrain.DEEP_WATER
	if elevation < _catalog.threshold("shallow_water"):
		return ChunkData.Terrain.SHALLOW_WATER
	if elevation < _catalog.threshold("coast"):
		return ChunkData.Terrain.BEACH
	return ChunkData.Terrain.LAND


func _surface_for_terrain(terrain: ChunkData.Terrain) -> StringName:
	match terrain:
		ChunkData.Terrain.DEEP_WATER:
			return &"deep_water"
		ChunkData.Terrain.SHALLOW_WATER:
			return &"shallow_water"
		ChunkData.Terrain.BEACH:
			return &"coast"
		_:
			return &"land"


func _configure_noise(noise: FastNoiseLite, seed_domain: StringName, frequency: float, octaves: int) -> void:
	noise.seed = WorldSeed.to_noise_seed(WorldSeed.derive(_world_seed, seed_domain))
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5


func _normalized_noise(noise: FastNoiseLite, world_tile: Vector2i) -> float:
	return noise.get_noise_2d(world_tile.x, world_tile.y) * 0.5 + 0.5


func _quantize(value: float) -> int:
	return clampi(roundi(value * 255.0), 0, 255)
