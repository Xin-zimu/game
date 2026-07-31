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
	_test_deterministic_generation()
	await _test_player_scene_contract()
	await _test_single_chunk_renderer()
	await _test_main_menu_layout()
	_finish()


func _test_project_resources() -> void:
	_assert_true(ResourceLoader.exists("res://scenes/main/main.tscn"), "main scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/main/game.tscn"), "game scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/player/player.tscn"), "player scene exists")
	_assert_true(ResourceLoader.exists("res://assets/branding/icon.svg"), "application icon exists")


func _test_version_contract() -> void:
	_assert_equal(GameVersion.VERSION, "0.3.0", "version constant")
	_assert_true(GameVersion.SAVE_VERSION >= 1, "save version initialized")
	_assert_equal(GameVersion.GENERATION_VERSION, 2, "generation version incremented")


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


func _test_deterministic_generation() -> void:
	var seed := WorldSeed.from_text("无尽边境")
	var first_generator := TerrainGenerator.new(seed)
	var showcase_chunk := Vector2i(-1, -4)
	var first := first_generator.generate_chunk(showcase_chunk)
	var repeated := TerrainGenerator.new(seed).generate_chunk(showcase_chunk)
	_assert_equal(first.checksum, repeated.checksum, "same seed and coordinate survive generator restart")
	_assert_true(first.base_tiles == repeated.base_tiles, "deterministic tile bytes match exactly")
	_assert_equal(first.base_tiles.size(), 1024, "chunk contains 32×32 base tiles")
	_assert_equal(first.elevation_map.size(), 1024, "chunk contains 32×32 elevation samples")
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
	_assert_equal(represented_types, 4, "showcase chunk contains deep water, shallow water, beach and land")
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


func _test_single_chunk_renderer() -> void:
	var renderer := SingleChunkRenderer.new()
	add_child(renderer)
	await get_tree().process_frame
	var chunk := TerrainGenerator.new(WorldSeed.from_text("无尽边境")).generate_chunk(Vector2i(-1, -4))
	renderer.apply_chunk(chunk)
	_assert_equal(renderer.get_used_cells().size(), 1024, "TileMapLayer renders every chunk tile")
	renderer.toggle_noise_view()
	_assert_equal(renderer.get_used_cells().size(), 1024, "noise debug view preserves cell coverage")
	_assert_equal(renderer.view_mode_name(), "噪声", "noise debug view toggles explicitly")
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
