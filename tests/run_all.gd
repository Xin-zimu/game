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
	_test_resource_catalog_contract()
	_test_deterministic_generation()
	_test_biome_regions()
	_test_resource_generation()
	_test_resource_harvest_state()
	await _test_save_system()
	_test_stream_planner()
	_test_chunk_seams()
	_test_background_generation()
	await _test_player_scene_contract()
	await _test_chunk_renderer()
	await _test_drop_pool()
	await _test_generation_hud_layout()
	await _test_resource_hud_layout()
	await _test_main_menu_layout()
	_finish()


func _test_project_resources() -> void:
	_assert_true(ResourceLoader.exists("res://scenes/main/main.tscn"), "main scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/main/game.tscn"), "game scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/player/player.tscn"), "player scene exists")
	_assert_true(ResourceLoader.exists("res://assets/branding/icon.svg"), "application icon exists")


func _test_version_contract() -> void:
	_assert_equal(GameVersion.VERSION, "0.7.0", "version constant")
	_assert_equal(GameVersion.SAVE_VERSION, 2, "save version incremented for the V0.7 format")
	_assert_equal(GameVersion.GENERATION_VERSION, 4, "generation version incremented")


func _test_event_bus_contract() -> void:
	_assert_true(EventBus.has_signal("scene_change_requested"), "scene signal exists")
	_assert_true(EventBus.has_signal("settings_changed"), "settings signal exists")
	_assert_true(EventBus.has_signal("notification_requested"), "notification signal exists")
	_assert_true(EventBus.has_signal("resource_prompt_changed"), "resource prompt signal exists")
	_assert_true(EventBus.has_signal("inventory_changed"), "inventory signal exists")
	_assert_true(EventBus.has_signal("save_status_changed"), "save status signal exists")


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


func _test_resource_catalog_contract() -> void:
	var catalog := ResourceCatalog.new()
	_assert_true(catalog.is_valid(), "external resource configuration loads and validates")
	_assert_equal(catalog.resource_count(), 5, "resource catalog contains tree, rock, grass, flower and berry bush")
	for resource_id in ResourceCatalog.REQUIRED_RESOURCE_IDS:
		_assert_true(catalog.has_resource(resource_id), "catalog contains stable resource ID %s" % resource_id)
	_assert_equal(catalog.tool_ids(), [&"hands", &"axe", &"pickaxe"], "tool order is data-driven and stable")
	_assert_equal(catalog.required_tool_for_code(catalog.code_for_id(&"tree")), &"axe", "trees require an axe")
	_assert_equal(catalog.required_tool_for_code(catalog.code_for_id(&"rock")), &"pickaxe", "rocks require a pickaxe")
	_assert_true(catalog.candidate_code_for_biome(&"deep_ocean", 0.0) < 0, "deep ocean has no resource rule")
	_assert_true(catalog.drop_pool_capacity() == 32 and catalog.max_resources_per_chunk() == 128, "resource and drop limits come from configuration")


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
	_assert_equal(first.checksum, "25b17b18822faa6c", "generation v4 checksum fixture remains stable")
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
	if represented_types < 2:
		var nearby_counts := PackedInt32Array([0, 0, 0, 0])
		for offset_y in range(-1, 2):
			for offset_x in range(-1, 2):
				var nearby := first_generator.generate_chunk(showcase_chunk + Vector2i(offset_x, offset_y)).terrain_counts()
				for terrain_index in nearby_counts.size():
					nearby_counts[terrain_index] += nearby[terrain_index]
		represented_types = 0
		for count in nearby_counts:
			represented_types += 1 if count > 0 else 0
	_assert_true(represented_types >= 2, "start region contains a visible terrain transition")
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


func _test_resource_generation() -> void:
	var seed := WorldSeed.from_text("无尽边境")
	var generator := TerrainGenerator.new(seed)
	var catalog := ResourceCatalog.new()
	var chunks: Array[ChunkData] = []
	var represented := PackedInt32Array()
	represented.resize(catalog.resource_count())
	var keys := {}
	var water_safe := true
	var capped := true
	for chunk_y in range(-5, 0):
		for chunk_x in range(-3, 2):
			var chunk := generator.generate_chunk(Vector2i(chunk_x, chunk_y))
			chunks.append(chunk)
			capped = capped and chunk.resource_count() <= catalog.max_resources_per_chunk()
			for index in chunk.resource_count():
				var local := chunk.resource_local_at(index)
				var terrain := chunk.tile_at(local)
				water_safe = water_safe and terrain != ChunkData.Terrain.DEEP_WATER and terrain != ChunkData.Terrain.SHALLOW_WATER
				represented[chunk.resource_code_at(index)] += 1
				keys[chunk.resource_key_at(index)] = true
	_assert_true(water_safe, "resources never spawn in deep or shallow water")
	_assert_true(capped, "resource counts remain under the configured per-chunk limit")
	for resource_code in catalog.resource_count():
		_assert_true(represented[resource_code] > 0, "deterministic region contains %s" % catalog.display_name_for_code(resource_code))
	var all_spawns: Array[Dictionary] = []
	for chunk in chunks:
		for index in chunk.resource_count():
			all_spawns.append({"tile": chunk.resource_world_tile_at(index), "code": chunk.resource_code_at(index)})
	var spacing_valid := true
	for first_index in all_spawns.size():
		for second_index in range(first_index + 1, all_spawns.size()):
			var first := all_spawns[first_index]
			var second := all_spawns[second_index]
			var required := maxi(catalog.minimum_distance_for_code(int(first["code"])), catalog.minimum_distance_for_code(int(second["code"])))
			if (first["tile"] as Vector2i).distance_squared_to(second["tile"] as Vector2i) < required * required:
				spacing_valid = false
	_assert_true(spacing_valid, "minimum spacing holds within and across chunk borders")
	_assert_equal(keys.size(), all_spawns.size(), "resource world keys are unique across chunks")
	var showcase := generator.generate_chunk(Vector2i(-1, -4))
	var repeated := TerrainGenerator.new(seed).generate_chunk(Vector2i(-1, -4))
	_assert_true(showcase.resource_codes == repeated.resource_codes and showcase.resource_local_x == repeated.resource_local_x and showcase.resource_local_y == repeated.resource_local_y, "resource bytes are deterministic across generator restarts")
	var spawn := generator.find_land_near(showcase)
	_assert_true(not showcase.has_resource_at(WorldCoordinates.tile_to_local(spawn)), "initial player spawn avoids resource collision")


func _test_resource_harvest_state() -> void:
	var catalog := ResourceCatalog.new()
	var state := ResourceHarvestState.new()
	var tree_code := catalog.code_for_id(&"tree")
	var key := "-7:12:%d" % tree_code
	var wrong_tool := state.hit(key, tree_code, &"hands", catalog)
	_assert_true(not bool(wrong_tool["accepted"]) and String(wrong_tool["reason"]) == "wrong_tool", "wrong tool cannot damage a resource")
	var first_hit := state.hit(key, tree_code, &"axe", catalog)
	var second_hit := state.hit(key, tree_code, &"axe", catalog)
	var final_hit := state.hit(key, tree_code, &"axe", catalog)
	_assert_true(bool(first_hit["accepted"]) and not bool(first_hit["destroyed"]) and int(first_hit["remaining"]) == 2, "resource durability decreases by tool power")
	_assert_true((first_hit["drops"] as Array).is_empty() and (second_hit["drops"] as Array).is_empty(), "resource does not drop items before destruction")
	_assert_true(bool(final_hit["destroyed"]) and state.collected_resources.has(key), "final valid hit records the resource difference")
	var drops := final_hit["drops"] as Array
	_assert_equal(drops.size(), 1, "destroyed tree resolves one controlled drop stack")
	var tree_drop := drops[0] as Dictionary
	_assert_equal(tree_drop["item_id"], &"wood", "tree produces the correct item")
	_assert_true(int(tree_drop["quantity"]) >= 2 and int(tree_drop["quantity"]) <= 4, "tree drop quantity stays inside configured bounds")
	var duplicate := state.hit(key, tree_code, &"axe", catalog)
	_assert_true(not bool(duplicate["accepted"]) and (duplicate["drops"] as Array).is_empty(), "same resource cannot drop twice")
	state.collect_item(tree_drop["item_id"] as StringName, int(tree_drop["quantity"]))
	_assert_equal(state.quantity(&"wood"), int(tree_drop["quantity"]), "automatic pickup target inventory accepts resolved quantity")


func _test_save_system() -> void:
	SaveManager.clear_current_world()
	_assert_true(SaveManager.create_world("自动测试边境", "存档种子-070"), "world creation writes initial metadata and player state")
	var root := SaveManager.current_world_root_absolute()
	_assert_true(FileAccess.file_exists(root.path_join("world.json")) and FileAccess.file_exists(root.path_join("player.json")), "new world contains metadata and player documents")
	var metadata := _read_json_for_test(root.path_join("world.json"))
	_assert_equal(int(metadata.get("save_version", 0)), 2, "world metadata records save format 2")
	_assert_equal(int(metadata.get("generation_version", 0)), 4, "world metadata records generation format 4")
	_assert_equal(String(metadata.get("world_name", "")), "自动测试边境", "world metadata preserves the world name")
	_assert_equal(String(metadata.get("seed_text", "")), "存档种子-070", "world metadata preserves the text seed")
	var chunks_path := root.path_join("chunks/surface")
	_assert_equal(_json_file_count(chunks_path), 0, "new unmodified world creates no chunk difference file")
	var initial_player := SaveManager.loaded_player_snapshot()
	var empty_state := {"collected_resources": [], "inventory": {}, "active_tool": "hands"}
	_assert_true(SaveManager.request_save(initial_player, empty_state, 1.25, false), "automatic save request accepts an immutable snapshot")
	SaveManager.flush_pending_save()
	_assert_equal(_json_file_count(chunks_path), 0, "saving an unmodified world still creates no chunk difference file")
	var player := initial_player.duplicate(true)
	player["position"] = [-2048.5, 1024.25]
	player["health"] = 73.0
	player["stamina"] = 41.0
	var removed_keys := ["-1:-129:0", "33:65:1"]
	var changed_state := {
		"collected_resources": removed_keys,
		"inventory": {"wood": 7, "stone": 3},
		"active_tool": "axe",
	}
	var dispatch_started := Time.get_ticks_usec()
	_assert_true(SaveManager.request_save(player, changed_state, 42.5, false), "changed world dispatches an autosave")
	var dispatch_ms := float(Time.get_ticks_usec() - dispatch_started) / 1000.0
	_assert_true(dispatch_ms < 50.0, "autosave snapshot dispatch does not block the main thread")
	SaveManager.flush_pending_save()
	_assert_true(SaveManager.last_save_duration_ms < 500.0, "background save completes without a visible-length stall")
	_assert_equal(_json_file_count(chunks_path), 2, "only the two modified chunks create difference files")
	var world_id := SaveManager.current_world_id()
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "saved world reloads after manager state is cleared")
	var restored_player := SaveManager.loaded_player_snapshot()
	_assert_equal(restored_player["position"], [-2048.5, 1024.25], "player position restores exactly")
	_assert_equal(float(restored_player["health"]), 73.0, "player health restores exactly")
	_assert_equal(float(restored_player["stamina"]), 41.0, "player stamina restores exactly")
	var restored_world_state := SaveManager.loaded_world_state_snapshot()
	var restored_removed := restored_world_state["collected_resources"] as Array
	_assert_true(restored_removed.has(removed_keys[0]) and restored_removed.has(removed_keys[1]), "destroyed resources restore from chunk differences")
	_assert_equal(int((restored_world_state["inventory"] as Dictionary).get("wood", 0)), 7, "V0.6 pickup counts restore as player attributes")
	_assert_equal(String(restored_world_state["active_tool"]), "axe", "active tool restores with player attributes")
	var restored_harvest := ResourceHarvestState.new()
	restored_harvest.restore_snapshot(restored_removed, restored_world_state["inventory"] as Dictionary)
	_assert_true(restored_harvest.collected_resources.has(removed_keys[0]), "restored collected key prevents a generated resource from reappearing")
	_assert_true(SaveManager.request_save(restored_player, restored_world_state, 44.0, true), "manual save requests a backup")
	SaveManager.flush_pending_save()
	_assert_true(_directory_count(root.path_join("backups")) >= 1, "manual save creates a recoverable backup directory")
	var corrupt_file := FileAccess.open(root.path_join("world.json"), FileAccess.WRITE)
	corrupt_file.store_string("{broken save")
	corrupt_file.flush()
	corrupt_file = null
	SaveManager.clear_current_world()
	_assert_true(not SaveManager.load_world(world_id), "corrupted world metadata is rejected")
	_assert_true("损坏" in SaveManager.last_error and "world.json" in SaveManager.last_error, "corrupted save reports a clear file-specific error")
	SaveManager.clear_current_world()
	_remove_test_save_tree(root)


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
	_assert_equal(renderer.visible_resource_count(), chunk.resource_count(), "resource TileMapLayer renders every generated resource without per-tile nodes")
	var resource_layer: ResourceChunkLayer
	for child in renderer.get_children():
		if child is ResourceChunkLayer:
			resource_layer = child as ResourceChunkLayer
			break
	_assert_true(resource_layer != null and resource_layer.tile_set.get_physics_layers_count() == 1, "resource TileMapLayer owns a shared collision layer")
	var solid_collision_found := false
	if resource_layer != null:
		var catalog := ResourceCatalog.new()
		for index in chunk.resource_count():
			if not catalog.is_solid(chunk.resource_code_at(index)):
				continue
			var local := chunk.resource_local_at(index)
			var source := resource_layer.tile_set.get_source(resource_layer.get_cell_source_id(local)) as TileSetAtlasSource
			var tile_data := source.get_tile_data(resource_layer.get_cell_atlas_coords(local), 0)
			solid_collision_found = tile_data.get_collision_polygons_count(0) > 0
			break
	_assert_true(solid_collision_found, "solid trees, rocks or berry bushes expose physical collision polygons")
	if chunk.resource_count() > 0:
		var collected := {chunk.resource_key_at(0): true}
		renderer.set_collected_resources(collected)
		_assert_equal(renderer.visible_resource_count(), chunk.resource_count() - 1, "collected resource remains hidden when a chunk renderer refreshes")
	renderer.set_debug_options(ChunkRenderer.ViewMode.BIOME, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "biome debug view preserves cell coverage")
	renderer.set_debug_options(ChunkRenderer.ViewMode.CLIMATE, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "climate debug view preserves cell coverage")
	renderer.set_debug_options(ChunkRenderer.ViewMode.ELEVATION, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "elevation debug view preserves cell coverage")
	renderer.queue_free()


func _test_drop_pool() -> void:
	var pool := WorldDropPool.new()
	pool.configure(2)
	add_child(pool)
	await get_tree().process_frame
	_assert_true(pool.spawn_drop(&"wood", 2, Vector2(10, 10)), "drop pool activates a free object")
	_assert_true(pool.spawn_drop(&"stone", 1, Vector2(80, 10)), "drop pool activates a second free object")
	_assert_true(not pool.spawn_drop(&"berry", 1, Vector2(150, 10)), "drop pool refuses an unmergeable overflow")
	_assert_true(pool.spawn_drop(&"wood", 3, Vector2(12, 10)), "full pool merges a matching item stack")
	_assert_equal(pool.active_count(), 2, "drop object count remains capped at pool capacity")
	pool._process(0.25)
	var pickup := pool.collect_near(Vector2(10, 10), 24.0)
	_assert_equal(pickup.size(), 1, "automatic pickup collects only nearby mature drops")
	_assert_equal(int((pickup[0] as Dictionary)["quantity"]), 5, "merged drop stack preserves total quantity")
	_assert_equal(pool.active_count(), 1, "picked-up object returns to the pool")
	pool.queue_free()


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
	player.restore_snapshot({"position": [-96.5, 160.25], "health": 64.0, "maximum_health": 120.0, "stamina": 33.0, "maximum_stamina": 80.0})
	_assert_equal(player.position, Vector2(-96.5, 160.25), "player restore applies signed position")
	_assert_true(player.health == 64.0 and player.maximum_health == 120.0 and player.stamina == 33.0 and player.maximum_stamina == 80.0, "player restore applies health and stamina attributes")
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


func _test_resource_hud_layout() -> void:
	var hud := ResourceHud.new()
	add_child(hud)
	await get_tree().process_frame
	EventBus.active_tool_changed.emit(&"axe", "斧头")
	EventBus.inventory_changed.emit({"wood": 4, "stone": 2, "fiber": 1})
	EventBus.resource_prompt_changed.emit("[E] 采集树木 · 耐久 3")
	await get_tree().process_frame
	var panel := hud.find_child("ResourcePanel", true, false) as Control
	var tool_label := hud.find_child("ToolLabel", true, false) as Label
	var inventory_label := hud.find_child("InventoryLabel", true, false) as Label
	var prompt_label := hud.find_child("ResourcePromptLabel", true, false) as Label
	_assert_true(panel != null and tool_label != null and inventory_label != null and prompt_label != null, "resource HUD tool, inventory and prompt nodes exist")
	if panel != null and tool_label != null and inventory_label != null:
		_assert_true(panel.get_global_rect().encloses(tool_label.get_global_rect()), "active tool stays inside resource panel")
		_assert_true(panel.get_global_rect().encloses(inventory_label.get_global_rect()), "inventory summary stays inside resource panel")
	hud.queue_free()


func _test_main_menu_layout() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var menu_scene := packed.instantiate() as Control
	add_child(menu_scene)
	await get_tree().process_frame
	var panel := menu_scene.find_child("MenuPanel", true, false) as Control
	var version_label := menu_scene.find_child("VersionLabel", true, false) as Control
	var footer := menu_scene.find_child("OfflineFooter", true, false) as Control
	var world_panel := menu_scene.find_child("WorldCreationPanel", true, false) as Control
	var world_name := menu_scene.find_child("WorldNameInput", true, false) as LineEdit
	var seed_input := menu_scene.find_child("SeedInput", true, false) as LineEdit
	var continue_button := menu_scene.find_child("ContinueButton", true, false) as Button
	_assert_true(panel != null and version_label != null and footer != null, "menu layout nodes exist")
	_assert_true(world_panel != null and world_name != null and seed_input != null and continue_button != null, "world creation and continue controls exist")
	if panel != null and version_label != null and footer != null:
		_assert_true(panel.get_global_rect().encloses(version_label.get_global_rect()), "version label stays inside menu panel")
		_assert_true(panel.get_global_rect().encloses(footer.get_global_rect()), "footer stays inside menu panel")
	menu_scene.queue_free()


func _read_json_for_test(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _json_file_count(path: String) -> int:
	var directory := DirAccess.open(path)
	if directory == null:
		return 0
	var result := 0
	for filename in directory.get_files():
		result += 1 if filename.ends_with(".json") else 0
	return result


func _directory_count(path: String) -> int:
	var directory := DirAccess.open(path)
	return directory.get_directories().size() if directory != null else 0


func _remove_test_save_tree(path: String) -> void:
	var saves_root := ProjectSettings.globalize_path(SaveManager.SAVE_ROOT)
	if not path.begins_with(saves_root.path_join("world_")):
		push_error("Refusing to remove a path outside the test save root: %s" % path)
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		DirAccess.remove_absolute(path.path_join(filename))
	for dirname in directory.get_directories():
		_remove_test_save_tree(path.path_join(dirname))
	DirAccess.remove_absolute(path)


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
