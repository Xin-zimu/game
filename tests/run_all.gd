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
	await _test_main_menu_layout()
	_finish()


func _test_project_resources() -> void:
	_assert_true(ResourceLoader.exists("res://scenes/main/main.tscn"), "main scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/main/game.tscn"), "game scene exists")
	_assert_true(ResourceLoader.exists("res://assets/branding/icon.svg"), "application icon exists")


func _test_version_contract() -> void:
	_assert_equal(GameVersion.VERSION, "0.1.0", "version constant")
	_assert_true(GameVersion.SAVE_VERSION >= 1, "save version initialized")
	_assert_true(GameVersion.GENERATION_VERSION >= 1, "generation version initialized")


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
