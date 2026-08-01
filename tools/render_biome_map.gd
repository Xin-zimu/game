extends SceneTree

const MAP_SIZE := 384
const SAMPLE_SCALE := 4
const WORLD_ORIGIN := Vector2i(-768, -768)


func _initialize() -> void:
	var output_path := "res://releases/v0.5.0/SCREENSHOTS/biome-debug-map.png"
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		output_path = user_args[0]
	var catalog := BiomeCatalog.new()
	if not catalog.is_valid():
		printerr("Unable to render biome map: %s" % catalog.error_message())
		quit(1)
		return
	var generator := TerrainGenerator.new(WorldSeed.from_text("无尽边境"))
	var image := Image.create(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RGBA8)
	for y in MAP_SIZE:
		for x in MAP_SIZE:
			var world_tile := WORLD_ORIGIN + Vector2i(x, y) * SAMPLE_SCALE
			var biome_code := generator.biome_at(world_tile)
			var color := catalog.color_for_code(biome_code, true)
			if x % 64 == 0 or y % 64 == 0:
				color = color.darkened(0.12)
			image.set_pixel(x, y, color)
	var error := image.save_png(output_path)
	if error != OK:
		printerr("Unable to save biome map to %s: %s" % [output_path, error_string(error)])
		quit(1)
		return
	print("Biome debug map saved: %s (%d×%d pixels, %d world tiles per pixel)" % [output_path, MAP_SIZE, MAP_SIZE, SAMPLE_SCALE])
	quit(0)
