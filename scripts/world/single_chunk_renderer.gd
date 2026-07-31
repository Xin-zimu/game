class_name SingleChunkRenderer
extends TileMapLayer

signal view_mode_changed(mode_name: String)

const TERRAIN_COLORS := [
	Color("183f5a"),
	Color("2f738a"),
	Color("c9ad6b"),
	Color("3f7148"),
]
const NOISE_STEPS := 16

var _chunk: ChunkData
var _source_id := -1
var _show_noise := false


func _ready() -> void:
	z_index = -20
	tile_set = _build_tile_set()


func apply_chunk(chunk: ChunkData) -> void:
	_chunk = chunk
	_render()


func toggle_noise_view() -> void:
	_show_noise = not _show_noise
	_render()
	view_mode_changed.emit(view_mode_name())


func view_mode_name() -> String:
	return "噪声" if _show_noise else "地形"


func _render() -> void:
	clear()
	if _chunk == null or _source_id < 0:
		return
	for local_y in WorldCoordinates.CHUNK_SIZE:
		for local_x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(local_x, local_y)
			var world_tile := WorldCoordinates.chunk_local_to_tile(_chunk.chunk_position, local)
			var atlas_index: int
			if _show_noise:
				atlas_index = TERRAIN_COLORS.size() + mini(int(_chunk.elevation_at(local) * NOISE_STEPS), NOISE_STEPS - 1)
			else:
				atlas_index = int(_chunk.tile_at(local))
			set_cell(world_tile, _source_id, Vector2i(atlas_index, 0), 0)


func _build_tile_set() -> TileSet:
	var result := TileSet.new()
	result.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	var tile_count := TERRAIN_COLORS.size() + NOISE_STEPS
	var image := Image.create(WorldCoordinates.TILE_SIZE * tile_count, WorldCoordinates.TILE_SIZE, false, Image.FORMAT_RGBA8)
	for tile_index in tile_count:
		var base_color: Color
		if tile_index < TERRAIN_COLORS.size():
			base_color = TERRAIN_COLORS[tile_index]
		else:
			var value := float(tile_index - TERRAIN_COLORS.size()) / float(NOISE_STEPS - 1)
			base_color = Color(value, value, value)
		_paint_tile(image, tile_index, base_color)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	for tile_index in tile_count:
		atlas.create_tile(Vector2i(tile_index, 0))
	_source_id = result.add_source(atlas)
	return result


func _paint_tile(image: Image, tile_index: int, base_color: Color) -> void:
	var origin_x := tile_index * WorldCoordinates.TILE_SIZE
	for y in WorldCoordinates.TILE_SIZE:
		for x in WorldCoordinates.TILE_SIZE:
			var color := base_color
			if tile_index < TERRAIN_COLORS.size():
				var pattern := posmod(x * 3 + y * 5 + tile_index * 7, 19)
				if pattern == 0 or (tile_index <= ChunkData.Terrain.SHALLOW_WATER and y % 11 == 3):
					color = base_color.lightened(0.08)
				elif pattern == 9:
					color = base_color.darkened(0.06)
			image.set_pixel(origin_x + x, y, color)
