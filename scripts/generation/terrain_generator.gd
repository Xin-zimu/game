class_name TerrainGenerator
extends RefCounted

const DEEP_WATER_LEVEL := 0.28
const SHALLOW_WATER_LEVEL := 0.36
const BEACH_LEVEL := 0.42

var _world_seed: int
var _elevation_noise := FastNoiseLite.new()
var _continental_noise := FastNoiseLite.new()
var _detail_noise := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	_world_seed = world_seed
	_configure_noise(_continental_noise, &"continentalness", 0.010, 3)
	_configure_noise(_elevation_noise, &"elevation", 0.028, 4)
	_configure_noise(_detail_noise, &"detail", 0.085, 2)


func generate_chunk(chunk_position: Vector2i, world_layer: StringName = &"surface") -> ChunkData:
	var result := ChunkData.new()
	result.chunk_position = chunk_position
	result.world_layer = world_layer
	result.world_seed = _world_seed
	result.base_tiles.resize(WorldCoordinates.CHUNK_SIZE * WorldCoordinates.CHUNK_SIZE)
	result.elevation_map.resize(WorldCoordinates.CHUNK_SIZE * WorldCoordinates.CHUNK_SIZE)
	for local_y in WorldCoordinates.CHUNK_SIZE:
		for local_x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(local_x, local_y)
			var world_tile := WorldCoordinates.chunk_local_to_tile(chunk_position, local)
			var elevation := elevation_at(world_tile)
			var index := local_y * WorldCoordinates.CHUNK_SIZE + local_x
			result.elevation_map[index] = clampi(roundi(elevation * 255.0), 0, 255)
			result.base_tiles[index] = _terrain_with_cleanup(world_tile, elevation)
	result.finalize_checksum()
	return result


func elevation_at(world_tile: Vector2i) -> float:
	var continental := _normalized_noise(_continental_noise, world_tile)
	var elevation := _normalized_noise(_elevation_noise, world_tile)
	var detail := _normalized_noise(_detail_noise, world_tile)
	return clampf(continental * 0.54 + elevation * 0.36 + detail * 0.10, 0.0, 1.0)


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
			if neighbor_elevation >= BEACH_LEVEL:
				land_neighbors += 1
			terrain_neighbors[_classify(neighbor_elevation)] += 1
	var center_terrain := _classify(elevation)
	var majority_terrain := center_terrain
	var majority_count := 0
	for terrain_index in terrain_neighbors.size():
		if terrain_neighbors[terrain_index] > majority_count:
			majority_count = terrain_neighbors[terrain_index]
			majority_terrain = terrain_index
	if majority_count >= 6 and majority_terrain != center_terrain:
		return majority_terrain
	if elevation >= BEACH_LEVEL and land_neighbors <= 1:
		return ChunkData.Terrain.SHALLOW_WATER
	if elevation < BEACH_LEVEL and land_neighbors >= 7:
		return ChunkData.Terrain.BEACH
	return _classify(elevation)


func _classify(elevation: float) -> ChunkData.Terrain:
	if elevation < DEEP_WATER_LEVEL:
		return ChunkData.Terrain.DEEP_WATER
	if elevation < SHALLOW_WATER_LEVEL:
		return ChunkData.Terrain.SHALLOW_WATER
	if elevation < BEACH_LEVEL:
		return ChunkData.Terrain.BEACH
	return ChunkData.Terrain.LAND


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
