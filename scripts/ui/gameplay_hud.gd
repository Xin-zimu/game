class_name GameplayHud
extends Control

var _health_fill: ColorRect
var _stamina_fill: ColorRect
var _state_label: Label
var _coordinate_label: Label


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_stamina_changed.connect(_on_stamina_changed)
	EventBus.player_state_changed.connect(_on_state_changed)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var world_tile := WorldCoordinates.world_pixel_to_tile(player.global_position)
		_coordinate_label.text = "世界格  X %d   Y %d" % [world_tile.x, world_tile.y]


func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.name = "GameplayPanel"
	UiLayout.top_left(panel, Vector2(310, 130), Vector2(UiLayout.EDGE_MARGIN, UiLayout.EDGE_MARGIN))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("08171ee8")
	style.border_color = Color("3b7056")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	column.add_child(_make_bar_row("生命", Color("c85858"), "health"))
	column.add_child(_make_bar_row("体力", Color("e2ba59"), "stamina"))
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 16)
	column.add_child(info)
	_state_label = Label.new()
	_state_label.text = "状态  IDLE"
	_state_label.add_theme_color_override("font_color", Color("8fd0a6"))
	info.add_child(_state_label)
	_coordinate_label = Label.new()
	_coordinate_label.text = "世界格  X 0   Y 0"
	_coordinate_label.add_theme_color_override("font_color", Color("8fa79b"))
	info.add_child(_coordinate_label)
	var hints := Label.new()
	hints.name = "ControlHintsLabel"
	UiLayout.top_center(hints, Vector2(760, 28), UiLayout.EDGE_MARGIN)
	hints.text = "WASD 移动 · J/左键 攻击 · E 交互 · Q 工具 · I 背包 · C 制作 · 1–8 快捷栏 · Ctrl+S 保存"
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hints.add_theme_font_size_override("font_size", 15)
	hints.add_theme_color_override("font_color", Color("dce9df"))
	add_child(hints)


func _make_bar_row(label_text: String, color: Color, kind: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 24)
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(42, 0)
	label.add_theme_color_override("font_color", Color("dce9df"))
	row.add_child(label)
	var track := ColorRect.new()
	track.color = Color("15231f")
	track.custom_minimum_size = Vector2(215, 14)
	track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(track)
	var fill := ColorRect.new()
	fill.color = color
	track.add_child(fill)
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if kind == "health":
		_health_fill = fill
	else:
		_stamina_fill = fill
	return row


func _on_health_changed(current: float, maximum: float) -> void:
	if _health_fill != null:
		_health_fill.scale.x = current / maximum


func _on_stamina_changed(current: float, maximum: float) -> void:
	if _stamina_fill != null:
		_stamina_fill.scale.x = current / maximum


func _on_state_changed(state: StringName) -> void:
	if _state_label != null:
		_state_label.text = "状态  %s" % state
