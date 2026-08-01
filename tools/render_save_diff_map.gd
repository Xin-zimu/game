extends SceneTree

const START_CHUNK := Vector2i(-2, -5)
const REGION_CHUNKS := Vector2i(4, 4)
const PIXELS_PER_TILE := 4
const OUTPUT_PATH := "res://releases/v0.7.0/SCREENSHOTS/save-difference-map.png"


func _init() -> void:
	var seed := WorldSeed.from_text("无尽边境")
	var generator := TerrainGenerator.new(seed)
	var biome_catalog := BiomeCatalog.new()
	var resource_catalog := ResourceCatalog.new()
	var harvest_state := ResourceHarvestState.new()
	var collected: Array[String] = []
	var inventory := {"wood": 12, "stone": 7, "fiber": 4}
	var chunks: Array[ChunkData] = []
	for chunk_y in REGION_CHUNKS.y:
		for chunk_x in REGION_CHUNKS.x:
			var chunk := generator.generate_chunk(START_CHUNK + Vector2i(chunk_x, chunk_y))
			chunks.append(chunk)
			for index in chunk.resource_count():
				var world_tile := chunk.resource_world_tile_at(index)
				if posmod(abs(world_tile.x * 31 + world_tile.y * 17 + chunk.resource_code_at(index) * 13), 9) == 0:
					collected.append(chunk.resource_key_at(index))
	harvest_state.restore_snapshot(collected, inventory)
	var tiles_wide := REGION_CHUNKS.x * WorldCoordinates.CHUNK_SIZE
	var tiles_high := REGION_CHUNKS.y * WorldCoordinates.CHUNK_SIZE
	var image := Image.create(tiles_wide * PIXELS_PER_TILE, tiles_high * PIXELS_PER_TILE, false, Image.FORMAT_RGBA8)
	var visible_count := 0
	var removed_count := 0
	for chunk_index in chunks.size():
		var chunk := chunks[chunk_index]
		var chunk_x := chunk_index % REGION_CHUNKS.x
		@warning_ignore("integer_division")
		var chunk_y := chunk_index / REGION_CHUNKS.x
		for local_y in WorldCoordinates.CHUNK_SIZE:
			for local_x in WorldCoordinates.CHUNK_SIZE:
				var local := Vector2i(local_x, local_y)
				var map_tile := Vector2i(chunk_x * WorldCoordinates.CHUNK_SIZE + local_x, chunk_y * WorldCoordinates.CHUNK_SIZE + local_y)
				_fill_tile(image, map_tile, biome_catalog.color_for_code(chunk.biome_at(local)).darkened(0.34))
		for index in chunk.resource_count():
			var local := chunk.resource_local_at(index)
			var map_tile := Vector2i(chunk_x * WorldCoordinates.CHUNK_SIZE + local.x, chunk_y * WorldCoordinates.CHUNK_SIZE + local.y)
			if harvest_state.collected_resources.has(chunk.resource_key_at(index)):
				_draw_removed(image, map_tile)
				removed_count += 1
			else:
				_draw_resource(image, map_tile, resource_catalog.color_for_code(chunk.resource_code_at(index)))
				visible_count += 1
	_draw_chunk_guides(image)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		printerr("Unable to save V0.7 difference map: %s" % error_string(error))
		quit(1)
		return
	print("SAVE_DIFF_MAP | chunks=%dx%d visible=%d removed=%d inventory=%s output=%s" % [
		REGION_CHUNKS.x,
		REGION_CHUNKS.y,
		visible_count,
		removed_count,
		inventory,
		OUTPUT_PATH,
	])
	quit(0)


func _fill_tile(image: Image, tile: Vector2i, color: Color) -> void:
	var origin := tile * PIXELS_PER_TILE
	for y in PIXELS_PER_TILE:
		for x in PIXELS_PER_TILE:
			image.set_pixelv(origin + Vector2i(x, y), color)


func _draw_resource(image: Image, tile: Vector2i, color: Color) -> void:
	var origin := tile * PIXELS_PER_TILE
	for y in range(1, PIXELS_PER_TILE - 1):
		for x in range(1, PIXELS_PER_TILE - 1):
			image.set_pixelv(origin + Vector2i(x, y), color.lightened(0.18))


func _draw_removed(image: Image, tile: Vector2i) -> void:
	var origin := tile * PIXELS_PER_TILE
	var marker := Color("f05b55")
	for index in PIXELS_PER_TILE:
		image.set_pixelv(origin + Vector2i(index, index), marker)
		image.set_pixelv(origin + Vector2i(PIXELS_PER_TILE - 1 - index, index), marker)


func _draw_chunk_guides(image: Image) -> void:
	var step := WorldCoordinates.CHUNK_SIZE * PIXELS_PER_TILE
	var guide := Color("f4df9a80")
	for x in range(0, image.get_width(), step):
		for y in image.get_height():
			image.set_pixel(x, y, guide)
	for y in range(0, image.get_height(), step):
		for x in image.get_width():
			image.set_pixel(x, y, guide)
