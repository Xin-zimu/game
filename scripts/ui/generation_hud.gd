class_name GenerationHud
extends Control

var _seed_label: Label
var _world_label: Label
var _seed_text := ""
var _seed_value := 0
var _chunk := Vector2i.ZERO
var _checksum := ""
var _mode := "地形"


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_panel()
	_refresh()


func configure(seed_text: String, seed_value: int, chunk: Vector2i, checksum: String) -> void:
	_seed_text = seed_text
	_seed_value = seed_value
	_chunk = chunk
	_checksum = checksum
	_refresh()


func set_view_mode(mode_name: String) -> void:
	_mode = mode_name
	_refresh()


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(354, 24)
	panel.custom_minimum_size = Vector2(572, 86)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("08171ee8")
	style.border_color = Color("477c91")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	_seed_label = Label.new()
	_seed_label.add_theme_color_override("font_color", Color("d9eee2"))
	column.add_child(_seed_label)
	_world_label = Label.new()
	_world_label.add_theme_font_size_override("font_size", 14)
	_world_label.add_theme_color_override("font_color", Color("8fb6c5"))
	column.add_child(_world_label)


func _refresh() -> void:
	if _seed_label == null or _world_label == null:
		return
	_seed_label.text = "种子  %s  →  %d" % [_seed_text, _seed_value]
	_world_label.text = "区块  (%d, %d)   校验  %s   视图  %s" % [_chunk.x, _chunk.y, _checksum, _mode]
