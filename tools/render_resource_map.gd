extends SceneTree

const START_CHUNK := Vector2i(-3, -5)
const REGION_CHUNKS := Vector2i(6, 6)
const PIXELS_PER_TILE := 3
const OUTPUT_PATH := "res://releases/v0.6.0/SCREENSHOTS/resource-distribution.png"


func _init() -> void:
	var seed := WorldSeed.from_text("无尽边境")
	var generator := TerrainGenerator.new(seed)
	var biome_catalog := BiomeCatalog.new()
	var resource_catalog := ResourceCatalog.new()
	var tiles_wide := REGION_CHUNKS.x * WorldCoordinates.CHUNK_SIZE
	var tiles_high := REGION_CHUNKS.y * WorldCoordinates.CHUNK_SIZE
	var image := Image.create(tiles_wide * PIXELS_PER_TILE, tiles_high * PIXELS_PER_TILE, false, Image.FORMAT_RGBA8)
	var counts := PackedInt32Array()
	counts.resize(resource_catalog.resource_count())
	for chunk_y in REGION_CHUNKS.y:
		for chunk_x in REGION_CHUNKS.x:
			var coordinate := START_CHUNK + Vector2i(chunk_x, chunk_y)
			var chunk := generator.generate_chunk(coordinate)
			for local_y in WorldCoordinates.CHUNK_SIZE:
				for local_x in WorldCoordinates.CHUNK_SIZE:
					var local := Vector2i(local_x, local_y)
					var biome_color := biome_catalog.color_for_code(chunk.biome_at(local)).darkened(0.30)
					var map_tile := Vector2i(chunk_x * WorldCoordinates.CHUNK_SIZE + local_x, chunk_y * WorldCoordinates.CHUNK_SIZE + local_y)
					_fill_tile(image, map_tile, biome_color)
			for index in chunk.resource_count():
				var code := chunk.resource_code_at(index)
				counts[code] += 1
				var local := chunk.resource_local_at(index)
				var map_tile := Vector2i(chunk_x * WorldCoordinates.CHUNK_SIZE + local.x, chunk_y * WorldCoordinates.CHUNK_SIZE + local.y)
				_fill_resource(image, map_tile, resource_catalog.color_for_code(code))
	_draw_chunk_guides(image)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		printerr("Unable to save V0.6 resource distribution map: %s" % error_string(error))
		quit(1)
		return
	print("RESOURCE_MAP | chunks=%dx%d origin=%s counts=%s output=%s" % [
		REGION_CHUNKS.x,
		REGION_CHUNKS.y,
		START_CHUNK,
		counts,
		OUTPUT_PATH,
	])
	quit(0)


func _fill_tile(image: Image, tile: Vector2i, color: Color) -> void:
	var origin := tile * PIXELS_PER_TILE
	for y in PIXELS_PER_TILE:
		for x in PIXELS_PER_TILE:
			image.set_pixelv(origin + Vector2i(x, y), color)


func _fill_resource(image: Image, tile: Vector2i, color: Color) -> void:
	var origin := tile * PIXELS_PER_TILE
	for y in PIXELS_PER_TILE:
		for x in PIXELS_PER_TILE:
			image.set_pixelv(origin + Vector2i(x, y), color.lightened(0.20) if x == 1 and y == 0 else color)


func _draw_chunk_guides(image: Image) -> void:
	var step := WorldCoordinates.CHUNK_SIZE * PIXELS_PER_TILE
	var guide := Color("f4df9a80")
	for x in range(0, image.get_width(), step):
		for y in image.get_height():
			image.set_pixel(x, y, guide)
	for y in range(0, image.get_height(), step):
		for x in image.get_width():
			image.set_pixel(x, y, guide)
