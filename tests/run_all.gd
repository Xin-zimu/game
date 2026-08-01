extends Node

var _failures: Array[String] = []
var _passes := 0


func _ready() -> void:
	print("=== Infinite Frontier test suite v%s ===" % GameVersion.VERSION)
	_test_project_resources()
	_test_version_contract()
	_test_event_bus_contract()
	_test_settings_round_trip()
	_test_scene_transition_contract()
	_test_player_motor_frame_independence()
	_test_world_seed_contract()
	_test_world_coordinate_contract()
	_test_biome_catalog_contract()
	_test_deterministic_generation()
	_test_biome_regions()
	_test_stream_planner()
	_test_chunk_seams()
	_test_background_generation()
	await _test_player_scene_contract()
	await _test_chunk_renderer()
	await _test_generation_hud_layout()
	await _test_main_menu_layout()
	_finish()


func _test_project_resources() -> void:
	_assert_true(ResourceLoader.exists("res://scenes/main/main.tscn"), "main scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/main/game.tscn"), "game scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/player/player.tscn"), "player scene exists")
	_assert_true(ResourceLoader.exists("res://assets/branding/icon.svg"), "application icon exists")


func _test_version_contract() -> void:
	_assert_equal(GameVersion.VERSION, "0.5.0", "version constant")
	_assert_true(GameVersion.SAVE_VERSION >= 1, "save version initialized")
	_assert_equal(GameVersion.GENERATION_VERSION, 3, "generation version incremented")


func _test_event_bus_contract() -> void:
	_assert_true(EventBus.has_signal("scene_change_requested"), "scene signal exists")
	_assert_true(EventBus.has_signal("settings_changed"), "settings signal exists")
	_assert_true(EventBus.has_signal("notification_requested"), "notification signal exists")


func _test_settings_round_trip() -> void:
	var original: Variant = SettingsManager.get_value("accessibility/reduce_motion", false)
	SettingsManager.set_value("accessibility/reduce_motion", not bool(original), false)
	_assert_equal(SettingsManager.get_value("accessibility/reduce_motion"), not bool(original), "settings mutate")
	SettingsManager.set_value("accessibility/reduce_motion", original, false)
	_assert_true(SettingsManager.save_settings(), "settings save")


func _test_scene_transition_contract() -> void:
	_assert_true(ResourceLoader.exists(GameManager.MAIN_MENU_SCENE), "manager main scene path")
	_assert_true(ResourceLoader.exists(GameManager.GAME_SCENE), "manager game scene path")


func _test_player_motor_frame_independence() -> void:
	var direction := Vector2(1.0, 0.35)
	var at_30 := PlayerMotor.integrated_distance(direction, false, 30, 1.0)
	var at_60 := PlayerMotor.integrated_distance(direction, false, 60, 1.0)
	var at_120 := PlayerMotor.integrated_distance(direction, false, 120, 1.0)
	_assert_true(at_30.is_equal_approx(at_60) and at_60.is_equal_approx(at_120), "movement is frame-rate independent at 30/60/120 FPS")
	_assert_true(is_equal_approx(PlayerMotor.velocity_for(Vector2.ONE, false).length(), PlayerMotor.WALK_SPEED), "diagonal movement is normalized")
	_assert_true(PlayerMotor.velocity_for(Vector2.RIGHT, true).length() > PlayerMotor.velocity_for(Vector2.RIGHT, false).length(), "run speed exceeds walk speed")


func _test_world_seed_contract() -> void:
	var stable_seed := WorldSeed.from_text("无尽边境")
	_assert_equal(stable_seed, 6266252184503203218, "text seed has a platform-stable fixture")
	_assert_equal(WorldSeed.from_text("无尽边境"), stable_seed, "same text produces same 64-bit seed")
	_assert_equal(WorldSeed.from_text("-42"), -42, "numeric text preserves numeric seed")
	_assert_true(WorldSeed.derive(stable_seed, &"elevation") != WorldSeed.derive(stable_seed, &"detail"), "derived systems use independent seeds")
	_assert_true(WorldSeed.for_chunk(stable_seed, &"surface", Vector2i(-1, -1), &"terrain") != WorldSeed.for_chunk(stable_seed, &"surface", Vector2i(0, -1), &"terrain"), "coordinate seeds include signed chunk coordinates")


func _test_world_coordinate_contract() -> void:
	_assert_equal(WorldCoordinates.tile_to_chunk(Vector2i(31, 31)), Vector2i(0, 0), "positive tile maps to origin chunk")
	_assert_equal(WorldCoordinates.tile_to_chunk(Vector2i(-1, -1)), Vector2i(-1, -1), "negative edge maps with floor division")
	_assert_equal(WorldCoordinates.tile_to_chunk(Vector2i(-33, 64)), Vector2i(-2, 2), "negative multi-chunk coordinate maps correctly")
	_assert_equal(WorldCoordinates.tile_to_local(Vector2i(-1, -33)), Vector2i(31, 31), "negative tile has positive local coordinate")
	var tile := Vector2i(-65, 97)
	_assert_equal(WorldCoordinates.chunk_local_to_tile(WorldCoordinates.tile_to_chunk(tile), WorldCoordinates.tile_to_local(tile)), tile, "chunk/local conversion round trips")
	_assert_equal(WorldCoordinates.chunk_key(&"surface", Vector2i(-2, 3)), "surface_-2_3", "chunk key preserves layer and signs")


func _test_biome_catalog_contract() -> void:
	var catalog := BiomeCatalog.new()
	_assert_true(catalog.is_valid(), "external biome configuration loads and validates")
	_assert_equal(catalog.biome_count(), 9, "catalog contains six land biomes plus coast and two ocean depths")
	for biome_id in BiomeCatalog.REQUIRED_IDS:
		_assert_true(catalog.has_biome(biome_id), "catalog contains stable biome ID %s" % biome_id)
	_assert_true(catalog.threshold("deep_water") < catalog.threshold("shallow_water") and catalog.threshold("shallow_water") < catalog.threshold("coast"), "data-driven terrain thresholds are ordered")
	_assert_equal(catalog.classify_land(0.12, 0.50, 0.52, 0.50), catalog.code_for_id(&"snowfield"), "temperature rule selects snowfield")
	_assert_equal(catalog.classify_land(0.80, 0.12, 0.52, 0.50), catalog.code_for_id(&"desert"), "hot dry rule selects desert")
	_assert_equal(catalog.classify_land(0.62, 0.82, 0.52, 0.50), catalog.code_for_id(&"swamp"), "warm wet lowland rule selects swamp")
	_assert_equal(catalog.classify_land(0.52, 0.78, 0.64, 0.72), catalog.code_for_id(&"forest"), "wet rule selects forest outside swamp")
	_assert_equal(catalog.classify_land(0.52, 0.42, 0.82, 0.40), catalog.code_for_id(&"mountain"), "high low-erosion rule selects mountain")
	_assert_equal(catalog.classify_land(0.70, 0.30, 0.52, 0.50), catalog.code_for_id(&"plains"), "transition band routes a biome edge through plains")


func _test_deterministic_generation() -> void:
	var seed := WorldSeed.from_text("无尽边境")
	var first_generator := TerrainGenerator.new(seed)
	var showcase_chunk := Vector2i(-1, -4)
	var first := first_generator.generate_chunk(showcase_chunk)
	var repeated := TerrainGenerator.new(seed).generate_chunk(showcase_chunk)
	_assert_equal(first.checksum, repeated.checksum, "same seed and coordinate survive generator restart")
	_assert_true(first.base_tiles == repeated.base_tiles, "deterministic tile bytes match exactly")
	_assert_equal(first.base_tiles.size(), 1024, "chunk contains 32×32 base tiles")
	_assert_equal(first.continental_map.size(), 1024, "chunk contains 32×32 continental samples")
	_assert_equal(first.elevation_map.size(), 1024, "chunk contains 32×32 elevation samples")
	_assert_equal(first.erosion_map.size(), 1024, "chunk contains 32×32 erosion samples")
	_assert_equal(first.temperature_map.size(), 1024, "chunk contains 32×32 temperature samples")
	_assert_equal(first.moisture_map.size(), 1024, "chunk contains 32×32 moisture samples")
	_assert_equal(first.biome_map.size(), 1024, "chunk contains 32×32 biome samples")
	_assert_equal(first.checksum, "47c1e52c4fe80f9c", "generation v3 checksum fixture remains stable")
	var other_seed := TerrainGenerator.new(WorldSeed.from_text("另一片边境")).generate_chunk(showcase_chunk)
	_assert_true(first.checksum != other_seed.checksum, "different seeds produce different chunks")
	var chunk_a := Vector2i(-3, 2)
	var chunk_b := Vector2i(4, -5)
	var order_one := TerrainGenerator.new(seed)
	var a_then_b_a := order_one.generate_chunk(chunk_a).checksum
	var a_then_b_b := order_one.generate_chunk(chunk_b).checksum
	var order_two := TerrainGenerator.new(seed)
	var b_then_a_b := order_two.generate_chunk(chunk_b).checksum
	var b_then_a_a := order_two.generate_chunk(chunk_a).checksum
	_assert_true(a_then_b_a == b_then_a_a and a_then_b_b == b_then_a_b, "chunk generation is independent of request order")
	var counts := first.terrain_counts()
	_assert_equal(counts[0] + counts[1] + counts[2] + counts[3], 1024, "terrain histogram accounts for every tile")
	var represented_types := 0
	for count in counts:
		if count > 0:
			represented_types += 1
	_assert_true(represented_types >= 2, "showcase chunk contains a visible terrain transition")
	var isolated_tiles := 0
	for y in range(1, WorldCoordinates.CHUNK_SIZE - 1):
		for x in range(1, WorldCoordinates.CHUNK_SIZE - 1):
			var local := Vector2i(x, y)
			var terrain := first.tile_at(local)
			var matching_neighbors := 0
			for offset_y in range(-1, 2):
				for offset_x in range(-1, 2):
					if offset_x == 0 and offset_y == 0:
						continue
					if first.tile_at(local + Vector2i(offset_x, offset_y)) == terrain:
						matching_neighbors += 1
			if matching_neighbors == 0:
				isolated_tiles += 1
	_assert_equal(isolated_tiles, 0, "coast cleanup removes isolated single-tile noise")


func _test_biome_regions() -> void:
	var catalog := BiomeCatalog.new()
	var generator := TerrainGenerator.new(WorldSeed.from_text("无尽边境"))
	var broad_counts := PackedInt32Array()
	broad_counts.resize(catalog.biome_count())
	for y in range(-2048, 2049, 64):
		for x in range(-2048, 2049, 64):
			broad_counts[generator.biome_at(Vector2i(x, y))] += 1
	for biome_code in catalog.biome_count():
		_assert_true(broad_counts[biome_code] > 0, "broad deterministic scan contains %s" % catalog.display_name_for_code(biome_code))
	var origin := Vector2i(-96, -144)
	var side := 96
	var cells := PackedByteArray()
	cells.resize(side * side)
	for y in side:
		for x in side:
			cells[y * side + x] = generator.biome_at(origin + Vector2i(x, y))
	var matching_edges := 0
	var total_edges := 0
	var isolated_cells := 0
	for y in side:
		for x in side:
			var biome_code := cells[y * side + x]
			if x + 1 < side:
				total_edges += 1
				matching_edges += 1 if biome_code == cells[y * side + x + 1] else 0
			if y + 1 < side:
				total_edges += 1
				matching_edges += 1 if biome_code == cells[(y + 1) * side + x] else 0
			if x > 0 and y > 0 and x + 1 < side and y + 1 < side:
				var matching_neighbors := 0
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					matching_neighbors += 1 if biome_code == cells[(y + offset.y) * side + x + offset.x] else 0
				isolated_cells += 1 if matching_neighbors == 0 else 0
	_assert_true(float(matching_edges) / float(total_edges) > 0.90, "biomes form large continuous regions instead of random fragments")
	_assert_true(isolated_cells <= 4, "biome transition cleanup limits isolated single cells")


func _test_stream_planner() -> void:
	var center := Vector2i(-12, 7)
	_assert_equal(ChunkStreamPlanner.coordinates_in_radius(center, ChunkStreamPlanner.ACTIVE_RADIUS).size(), 25, "active radius contains at most 25 chunks")
	_assert_equal(ChunkStreamPlanner.coordinates_in_radius(center, ChunkStreamPlanner.PRELOAD_RADIUS).size(), 49, "preload radius contains at most 49 chunks")
	var ahead := center + Vector2i(3, 0)
	var behind := center + Vector2i(-3, 0)
	_assert_true(ChunkStreamPlanner.priority_score(ahead, center, Vector2i.RIGHT) < ChunkStreamPlanner.priority_score(behind, center, Vector2i.RIGHT), "movement direction receives queue priority")
	var simulated_cache: Array[Vector2i] = []
	var peak_cache := 0
	for minute_step in 1800:
		var simulated_center := Vector2i(minute_step - 900, -17)
		for coordinate in ChunkStreamPlanner.coordinates_in_radius(simulated_center, ChunkStreamPlanner.PRELOAD_RADIUS):
			if not simulated_cache.has(coordinate):
				simulated_cache.append(coordinate)
		simulated_cache = ChunkStreamPlanner.trim_to_cache_radius(simulated_cache, simulated_center)
		peak_cache = maxi(peak_cache, simulated_cache.size())
	_assert_true(peak_cache <= 81 and simulated_cache.size() <= 81, "30-minute traversal simulation keeps cache bounded to 9×9")


func _test_chunk_seams() -> void:
	var generator := TerrainGenerator.new(WorldSeed.from_text("无尽边境"))
	var left_coordinate := Vector2i(-1, -4)
	var right_coordinate := Vector2i(0, -4)
	var left := generator.generate_chunk(left_coordinate)
	var right := generator.generate_chunk(right_coordinate)
	var seam_coordinates_correct := true
	var samples_match_global_field := true
	var biome_samples_match_global_field := true
	for y in WorldCoordinates.CHUNK_SIZE:
		var left_world := WorldCoordinates.chunk_local_to_tile(left_coordinate, Vector2i(31, y))
		var right_world := WorldCoordinates.chunk_local_to_tile(right_coordinate, Vector2i(0, y))
		seam_coordinates_correct = seam_coordinates_correct and left_world + Vector2i.RIGHT == right_world
		var left_expected := clampi(roundi(generator.elevation_at(left_world) * 255.0), 0, 255)
		var right_expected := clampi(roundi(generator.elevation_at(right_world) * 255.0), 0, 255)
		samples_match_global_field = samples_match_global_field and left.elevation_map[y * 32 + 31] == left_expected and right.elevation_map[y * 32] == right_expected
		biome_samples_match_global_field = biome_samples_match_global_field and left.biome_at(Vector2i(31, y)) == generator.biome_at(left_world) and right.biome_at(Vector2i(0, y)) == generator.biome_at(right_world)
	_assert_true(seam_coordinates_correct, "adjacent chunk border tiles are consecutive world coordinates")
	_assert_true(samples_match_global_field, "both sides of a seam sample the same global noise field")
	_assert_true(biome_samples_match_global_field, "both sides of a seam sample the same global biome field")
	var original_checksum := left.checksum
	generator.generate_chunk(Vector2i(120, -75))
	_assert_equal(generator.generate_chunk(left_coordinate).checksum, original_checksum, "evicted region regenerates identically on return")


func _test_background_generation() -> void:
	var job := ChunkGenerationJob.new(WorldSeed.from_text("线程边境"), Vector2i(-9, 11))
	var task_id := WorkerThreadPool.add_task(job.execute, false, "test_chunk_generation")
	var error := WorkerThreadPool.wait_for_task_completion(task_id)
	_assert_equal(error, OK, "background chunk task completes successfully")
	_assert_equal(job.worker_task_id, task_id, "chunk data was generated on the worker pool")
	_assert_true(job.result is ChunkData and not job.result.has_method("add_child"), "background task returns pure ChunkData without scene-tree APIs")


func _test_chunk_renderer() -> void:
	var renderer := ChunkRenderer.new()
	add_child(renderer)
	await get_tree().process_frame
	var chunk := TerrainGenerator.new(WorldSeed.from_text("无尽边境")).generate_chunk(Vector2i(-1, -4))
	renderer.apply_chunk(chunk)
	_assert_equal(renderer.get_used_cells().size(), 1024, "TileMapLayer renders every chunk tile")
	_assert_equal(renderer.get_used_rect(), Rect2i(0, 0, 32, 32), "chunk renderer uses bounded local TileMap coordinates")
	_assert_equal(renderer.position, WorldCoordinates.tile_to_world_pixel(Vector2i(-32, -128)), "chunk renderer node carries the world offset")
	renderer.set_debug_options(ChunkRenderer.ViewMode.BIOME, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "biome debug view preserves cell coverage")
	renderer.set_debug_options(ChunkRenderer.ViewMode.CLIMATE, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "climate debug view preserves cell coverage")
	renderer.set_debug_options(ChunkRenderer.ViewMode.ELEVATION, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "elevation debug view preserves cell coverage")
	renderer.queue_free()


func _test_player_scene_contract() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	add_child(player)
	await get_tree().physics_frame
	var collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	_assert_true(collision != null and collision.shape != null, "player has physical collision")
	_assert_true(camera != null and camera.position_smoothing_enabled, "camera smoothing enabled")
	player.take_damage(25.0)
	_assert_equal(player.health, 75.0, "player damage updates health")
	player.heal(10.0)
	_assert_equal(player.health, 85.0, "player healing clamps correctly")
	player.queue_free()


func _test_generation_hud_layout() -> void:
	var hud := GenerationHud.new()
	add_child(hud)
	await get_tree().process_frame
	hud.configure("无尽边境", WorldSeed.from_text("无尽边境"), Vector2i(-1, -4), "47c1e52c4fe80f9c")
	hud.update_streaming({
		"current_chunk": Vector2i(-1, -4),
		"current_checksum": "47c1e52c4fe80f9c",
		"view_mode": "群系",
		"biome_name": "森林",
		"temperature": 0.48,
		"moisture": 0.73,
		"elevation": 0.57,
		"erosion": 0.41,
		"active": 25,
		"preload": 24,
		"cache": 49,
		"peak_cache": 49,
	})
	await get_tree().process_frame
	var panel := hud.find_child("GenerationPanel", true, false) as Control
	var world_label := hud.find_child("WorldLabel", true, false) as Label
	var stream_label := hud.find_child("StreamLabel", true, false) as Label
	_assert_true(panel != null and world_label != null and stream_label != null, "generation HUD diagnostic nodes exist")
	if panel != null and world_label != null and stream_label != null:
		_assert_true(panel.get_global_rect().encloses(world_label.get_global_rect()), "biome and climate diagnostics stay inside generation panel")
		_assert_true(panel.get_global_rect().encloses(stream_label.get_global_rect()), "stream diagnostics stay inside generation panel")
	hud.queue_free()


func _test_main_menu_layout() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var menu_scene := packed.instantiate() as Control
	add_child(menu_scene)
	await get_tree().process_frame
	var panel := menu_scene.find_child("MenuPanel", true, false) as Control
	var version_label := menu_scene.find_child("VersionLabel", true, false) as Control
	var footer := menu_scene.find_child("OfflineFooter", true, false) as Control
	_assert_true(panel != null and version_label != null and footer != null, "menu layout nodes exist")
	if panel != null and version_label != null and footer != null:
		_assert_true(panel.get_global_rect().encloses(version_label.get_global_rect()), "version label stays inside menu panel")
		_assert_true(panel.get_global_rect().encloses(footer.get_global_rect()), "footer stays inside menu panel")
	menu_scene.queue_free()


func _assert_true(value: bool, label: String) -> void:
	if value:
		_passes += 1
		print("PASS | %s" % label)
	else:
		_failures.append(label)
		printerr("FAIL | %s" % label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	_assert_true(actual == expected, "%s (expected=%s actual=%s)" % [label, expected, actual])


func _finish() -> void:
	print("=== %d passed, %d failed ===" % [_passes, _failures.size()])
	if not _failures.is_empty():
		printerr("Failures: %s" % ", ".join(_failures))
		get_tree().quit(1)
	else:
		get_tree().quit(0)
