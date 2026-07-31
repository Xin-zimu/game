class_name DebugPanel
extends PanelContainer

var _label: Label
var _elapsed := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 18)
	position = Vector2(-264, 18)
	custom_minimum_size = Vector2(246, 0)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color("d8f3dc"))
	add_child(_label)
	_update_text()
	visible = bool(SettingsManager.get_value("accessibility/show_fps", true))
	EventBus.settings_changed.connect(_on_settings_changed)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.25:
		_elapsed = 0.0
		_update_text()


func _update_text() -> void:
	if _label == null:
		return
	var player_line := ""
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("debug_snapshot"):
		var snapshot: Dictionary = player.debug_snapshot()
		var player_position: Vector2 = snapshot["position"]
		player_line = "\nPLAYER  %d, %d  %s" % [player_position.x, player_position.y, snapshot["state"]]
	_label.text = "INFINITE FRONTIER  v%s\nFPS  %d\nSCENE  %s\nMEM  %.1f MB%s" % [
		GameVersion.VERSION,
		Engine.get_frames_per_second(),
		get_tree().current_scene.name if get_tree().current_scene else "Boot",
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		player_line,
	]


func _on_settings_changed(key: StringName, value: Variant) -> void:
	if key == &"accessibility/show_fps":
		visible = bool(value)
