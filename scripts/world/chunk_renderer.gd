class_name ChunkRenderer
extends TileMapLayer

const TERRAIN_COLORS := [
	Color("183f5a"),
	Color("2f738a"),
	Color("c9ad6b"),
	Color("3f7148"),
]
const NOISE_STEPS := 16

static var _shared_tile_set: TileSet
static var _shared_source_id := -1

var _chunk: ChunkData
var _show_noise := false
var _show_boundary := true
var _boundary_overlay: ChunkBoundaryOverlay


func _ready() -> void:
	z_index = -20
	_ensure_shared_tile_set()
	tile_set = _shared_tile_set
	_boundary_overlay = ChunkBoundaryOverlay.new()
	add_child(_boundary_overlay)


func apply_chunk(chunk: ChunkData) -> void:
	_chunk = chunk
	position = WorldCoordinates.tile_to_world_pixel(chunk.chunk_position * WorldCoordinates.CHUNK_SIZE)
	_render()


func set_debug_options(show_noise: bool, show_boundary: bool) -> void:
	var noise_changed := _show_noise != show_noise
	_show_noise = show_noise
	_show_boundary = show_boundary
	if _boundary_overlay != null:
		_boundary_overlay.visible = _show_boundary
	if noise_changed:
		_render()


func _render() -> void:
	clear()
	if _chunk == null or _shared_source_id < 0:
		return
	for local_y in WorldCoordinates.CHUNK_SIZE:
		for local_x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(local_x, local_y)
			var atlas_index: int
			if _show_noise:
				atlas_index = TERRAIN_COLORS.size() + mini(int(_chunk.elevation_at(local) * NOISE_STEPS), NOISE_STEPS - 1)
			else:
				atlas_index = int(_chunk.tile_at(local))
			set_cell(local, _shared_source_id, Vector2i(atlas_index, 0), 0)


static func _ensure_shared_tile_set() -> void:
	if _shared_tile_set != null:
		return
	_shared_tile_set = TileSet.new()
	_shared_tile_set.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
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
	_shared_source_id = _shared_tile_set.add_source(atlas)


static func _paint_tile(image: Image, tile_index: int, base_color: Color) -> void:
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
