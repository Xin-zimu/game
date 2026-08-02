class_name MilestoneHud
extends Control

var _time_label: Label
var _objective_label: Label
var _boss_label: Label


func _ready() -> void:
	name = "MilestoneHud"
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.name = "MilestonePanel"
	UiLayout.top_right(panel, Vector2(298, 126), Vector2(UiLayout.EDGE_MARGIN, 306))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111815e8")
	style.border_color = Color("8f7a4f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	var title := Label.new()
	title.text = "生存里程碑"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("f2d06b"))
	column.add_child(title)
	_time_label = Label.new()
	_time_label.name = "TimeLabel"
	_time_label.text = "第 1 天 · 白天"
	_time_label.add_theme_font_size_override("font_size", 13)
	column.add_child(_time_label)
	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_objective_label.text = "目标：寻找世界中的古老遗迹"
	_objective_label.add_theme_font_size_override("font_size", 12)
	_objective_label.add_theme_color_override("font_color", Color("c8d4c6"))
	column.add_child(_objective_label)
	_boss_label = Label.new()
	_boss_label.name = "BossLabel"
	_boss_label.text = "遗迹守卫：未发现"
	_boss_label.add_theme_font_size_override("font_size", 12)
	_boss_label.add_theme_color_override("font_color", Color("b3c0b4"))
	column.add_child(_boss_label)
	EventBus.time_state_changed.connect(update_time)
	EventBus.milestone_state_changed.connect(update_milestone)


func update_time(snapshot: Dictionary) -> void:
	_time_label.text = "第 %d 天 · %s · %d%%" % [
		int(snapshot.get("day", 1)),
		String(snapshot.get("display_name", "白天")),
		roundi(float(snapshot.get("progress", 0.0)) * 100.0),
	]


func update_milestone(snapshot: Dictionary) -> void:
	var objective := String(snapshot.get("objective", "寻找世界中的古老遗迹"))
	if not bool(snapshot.get("ruin_discovered", false)) and snapshot.has("ruin_distance_pixels"):
		objective += " · %s %.1f区块" % [String(snapshot.get("ruin_direction", "")), float(snapshot["ruin_distance_pixels"]) / float(WorldCoordinates.CHUNK_SIZE * WorldCoordinates.TILE_SIZE)]
	_objective_label.text = "目标：%s" % objective
	if bool(snapshot.get("reward_claimed", false)):
		_boss_label.text = "遗迹守卫：已击败 · 核心已领取"
	elif bool(snapshot.get("boss_defeated", false)):
		_boss_label.text = "遗迹守卫：已击败 · 等待领取"
	elif bool(snapshot.get("boss_active", false)):
		_boss_label.text = "遗迹守卫：%d/%d · %s" % [
			roundi(float(snapshot.get("boss_health", 0.0))),
			roundi(float(snapshot.get("boss_maximum_health", 180.0))),
			String(snapshot.get("boss_state", "DORMANT")),
		]
	elif bool(snapshot.get("ruin_discovered", false)):
		_boss_label.text = "遗迹守卫：等待挑战"
	else:
		_boss_label.text = "遗迹守卫：未发现"
