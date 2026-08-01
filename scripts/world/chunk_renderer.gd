class_name ChunkRenderer
extends TileMapLayer

enum ViewMode {
	TERRAIN,
	BIOME,
	CLIMATE,
	ELEVATION,
}

const FIELD_STEPS := 16
const CLIMATE_STEPS := 8

static var _shared_tile_set: TileSet
static var _shared_source_id := -1
static var _biome_count := 0
static var _biome_debug_offset := 0
static var _elevation_offset := 0
static var _climate_offset := 0

var _chunk: ChunkData
var _view_mode := ViewMode.TERRAIN
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


func set_debug_options(view_mode: ViewMode, show_boundary: bool) -> void:
	var mode_changed := _view_mode != view_mode
	_view_mode = view_mode
	_show_boundary = show_boundary
	if _boundary_overlay != null:
		_boundary_overlay.visible = _show_boundary
	if mode_changed:
		_render()


static func view_mode_name(view_mode: ViewMode) -> String:
	match view_mode:
		ViewMode.BIOME:
			return "群系"
		ViewMode.CLIMATE:
			return "气候"
		ViewMode.ELEVATION:
			return "海拔"
		_:
			return "地形"


func _render() -> void:
	clear()
	if _chunk == null or _shared_source_id < 0:
		return
	for local_y in WorldCoordinates.CHUNK_SIZE:
		for local_x in WorldCoordinates.CHUNK_SIZE:
			var local := Vector2i(local_x, local_y)
			var atlas_index := _atlas_index_for(local)
			set_cell(local, _shared_source_id, Vector2i(atlas_index, 0), 0)


func _atlas_index_for(local: Vector2i) -> int:
	match _view_mode:
		ViewMode.BIOME:
			return _biome_debug_offset + _chunk.biome_at(local)
		ViewMode.CLIMATE:
			var temperature_step := mini(int(_chunk.temperature_at(local) * CLIMATE_STEPS), CLIMATE_STEPS - 1)
			var moisture_step := mini(int(_chunk.moisture_at(local) * CLIMATE_STEPS), CLIMATE_STEPS - 1)
			return _climate_offset + temperature_step * CLIMATE_STEPS + moisture_step
		ViewMode.ELEVATION:
			return _elevation_offset + mini(int(_chunk.elevation_at(local) * FIELD_STEPS), FIELD_STEPS - 1)
		_:
			return _chunk.biome_at(local)


static func _ensure_shared_tile_set() -> void:
	if _shared_tile_set != null:
		return
	var catalog := BiomeCatalog.new()
	_biome_count = catalog.biome_count()
	_biome_debug_offset = _biome_count
	_elevation_offset = _biome_debug_offset + _biome_count
	_climate_offset = _elevation_offset + FIELD_STEPS
	var tile_count := _climate_offset + CLIMATE_STEPS * CLIMATE_STEPS
	_shared_tile_set = TileSet.new()
	_shared_tile_set.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	var image := Image.create(WorldCoordinates.TILE_SIZE * tile_count, WorldCoordinates.TILE_SIZE, false, Image.FORMAT_RGBA8)
	for tile_index in tile_count:
		var base_color: Color
		var patterned := false
		if tile_index < _biome_count:
			base_color = catalog.color_for_code(tile_index)
			patterned = true
		elif tile_index < _elevation_offset:
			base_color = catalog.color_for_code(tile_index - _biome_debug_offset, true)
		elif tile_index < _climate_offset:
			var elevation_value := float(tile_index - _elevation_offset) / float(FIELD_STEPS - 1)
			base_color = Color(elevation_value, elevation_value, elevation_value)
		else:
			var climate_index := tile_index - _climate_offset
			var temperature := float(climate_index / CLIMATE_STEPS) / float(CLIMATE_STEPS - 1)
			var moisture := float(climate_index % CLIMATE_STEPS) / float(CLIMATE_STEPS - 1)
			base_color = _climate_color(temperature, moisture)
		_paint_tile(image, tile_index, base_color, patterned)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	for tile_index in tile_count:
		atlas.create_tile(Vector2i(tile_index, 0))
	_shared_source_id = _shared_tile_set.add_source(atlas)


static func _paint_tile(image: Image, tile_index: int, base_color: Color, patterned: bool) -> void:
	var origin_x := tile_index * WorldCoordinates.TILE_SIZE
	for y in WorldCoordinates.TILE_SIZE:
		for x in WorldCoordinates.TILE_SIZE:
			var color := base_color
			if patterned:
				var pattern := posmod(x * 3 + y * 5 + tile_index * 7, 23)
				if pattern == 0 or (tile_index <= 1 and y % 11 == 3):
					color = base_color.lightened(0.09)
				elif pattern == 11:
					color = base_color.darkened(0.07)
			image.set_pixel(origin_x + x, y, color)


static func _climate_color(temperature: float, moisture: float) -> Color:
	var dry_wet := Color("c7a267").lerp(Color("39745d"), moisture)
	var cold_hot := Color("7198c5").lerp(Color("ce7650"), temperature)
	return dry_wet.lerp(cold_hot, 0.42)
