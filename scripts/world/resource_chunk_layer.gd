class_name ResourceChunkLayer
extends TileMapLayer

const HIT_DURATION_MSEC := 160

static var _shared_tile_set: TileSet
static var _shared_source_id := -1

var _chunk: ChunkData
var _collected_resources: Dictionary = {}
var _key_to_index: Dictionary = {}
var _hit_deadlines: Dictionary = {}


func _ready() -> void:
	z_index = 4
	_ensure_shared_tile_set()
	tile_set = _shared_tile_set
	set_process(false)


func apply_chunk(chunk: ChunkData, collected_resources: Dictionary) -> void:
	_chunk = chunk
	_collected_resources = collected_resources
	_key_to_index.clear()
	for index in chunk.resource_count():
		_key_to_index[chunk.resource_key_at(index)] = index
	refresh_all()


func refresh_all() -> void:
	clear()
	if _chunk == null or _shared_source_id < 0:
		return
	for index in _chunk.resource_count():
		var key := _chunk.resource_key_at(index)
		if _collected_resources.has(key):
			continue
		set_cell(_chunk.resource_local_at(index), _shared_source_id, Vector2i(_chunk.resource_code_at(index), 0), 0)


func play_hit(resource_key: String, destroyed: bool) -> void:
	if not _key_to_index.has(resource_key):
		return
	var index := int(_key_to_index[resource_key])
	var local := _chunk.resource_local_at(index)
	if destroyed:
		_hit_deadlines.erase(resource_key)
		erase_cell(local)
		return
	set_cell(local, _shared_source_id, Vector2i(_chunk.resource_code_at(index), 1), 0)
	_hit_deadlines[resource_key] = Time.get_ticks_msec() + HIT_DURATION_MSEC
	set_process(true)


func visible_resource_count() -> int:
	return get_used_cells().size()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	for key_value in _hit_deadlines.keys():
		var key := String(key_value)
		if int(_hit_deadlines[key]) > now:
			continue
		_hit_deadlines.erase(key)
		if _collected_resources.has(key) or not _key_to_index.has(key):
			continue
		var index := int(_key_to_index[key])
		set_cell(_chunk.resource_local_at(index), _shared_source_id, Vector2i(_chunk.resource_code_at(index), 0), 0)
	if _hit_deadlines.is_empty():
		set_process(false)


static func _ensure_shared_tile_set() -> void:
	if _shared_tile_set != null:
		return
	var catalog := ResourceCatalog.new()
	_shared_tile_set = TileSet.new()
	_shared_tile_set.tile_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_tile_set.add_physics_layer(0)
	_shared_tile_set.set_physics_layer_collision_layer(0, 1)
	_shared_tile_set.set_physics_layer_collision_mask(0, 2)
	var image := Image.create(
		WorldCoordinates.TILE_SIZE * catalog.resource_count(),
		WorldCoordinates.TILE_SIZE * 2,
		false,
		Image.FORMAT_RGBA8
	)
	image.fill(Color.TRANSPARENT)
	for code in catalog.resource_count():
		_paint_resource(image, code, false, catalog.color_for_code(code))
		_paint_resource(image, code, true, catalog.color_for_code(code).lightened(0.32))
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i.ONE * WorldCoordinates.TILE_SIZE
	_shared_source_id = _shared_tile_set.add_source(atlas)
	for code in catalog.resource_count():
		for row in 2:
			atlas.create_tile(Vector2i(code, row))
			if catalog.is_solid(code):
				var tile_data := atlas.get_tile_data(Vector2i(code, row), 0)
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2(-9, -7), Vector2(9, -7), Vector2(9, 12), Vector2(-9, 12),
				]))


static func _paint_resource(image: Image, code: int, hit: bool, base_color: Color) -> void:
	var origin := Vector2i(code * WorldCoordinates.TILE_SIZE, WorldCoordinates.TILE_SIZE if hit else 0)
	match code:
		0:
			_fill_rect(image, origin + Vector2i(13, 18), Vector2i(6, 13), Color("73482e"))
			_fill_rect(image, origin + Vector2i(7, 7), Vector2i(18, 15), base_color.darkened(0.08))
			_fill_rect(image, origin + Vector2i(10, 3), Vector2i(12, 20), base_color)
			_fill_rect(image, origin + Vector2i(5, 11), Vector2i(22, 7), base_color)
		1:
			_fill_rect(image, origin + Vector2i(7, 15), Vector2i(19, 13), base_color.darkened(0.12))
			_fill_rect(image, origin + Vector2i(11, 10), Vector2i(12, 16), base_color)
			_fill_rect(image, origin + Vector2i(14, 12), Vector2i(6, 3), base_color.lightened(0.22))
		2:
			for x in [8, 13, 18, 23]:
				_draw_line(image, origin + Vector2i(x, 27), origin + Vector2i(x - 3, 15 + posmod(x, 4)), base_color)
		3:
			_draw_line(image, origin + Vector2i(16, 28), origin + Vector2i(16, 15), Color("5b8f48"))
			_fill_rect(image, origin + Vector2i(12, 10), Vector2i(9, 9), base_color)
			_fill_rect(image, origin + Vector2i(15, 13), Vector2i(3, 3), Color("f2d36b"))
		4:
			_fill_rect(image, origin + Vector2i(7, 14), Vector2i(19, 13), base_color)
			_fill_rect(image, origin + Vector2i(10, 10), Vector2i(13, 13), base_color.lightened(0.08))
			for berry in [Vector2i(11, 15), Vector2i(20, 14), Vector2i(15, 20), Vector2i(23, 21)]:
				_fill_rect(image, origin + berry, Vector2i(3, 3), Color("c94f69") if not hit else Color("ffd6df"))


static func _fill_rect(image: Image, origin: Vector2i, size: Vector2i, color: Color) -> void:
	for y in size.y:
		for x in size.x:
			image.set_pixelv(origin + Vector2i(x, y), color)


static func _draw_line(image: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var points := Geometry2D.bresenham_line(from, to)
	for point in points:
		if point.x >= 0 and point.y >= 0 and point.x < image.get_width() and point.y < image.get_height():
			image.set_pixelv(point, color)
