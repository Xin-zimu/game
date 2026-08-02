class_name EnemyHud
extends Control

var _population_label: Label
var _types_label: Label
var _states_label: Label


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_panel()
	EventBus.enemy_state_changed.connect(_on_enemy_state_changed)


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "EnemyPanel"
	UiLayout.top_right(panel, Vector2(298, 108), Vector2(UiLayout.EDGE_MARGIN, 154))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111018e8")
	style.border_color = Color("745f8f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	_population_label = Label.new()
	_population_label.name = "EnemyPopulationLabel"
	_population_label.text = "敌人  0/18  ·  休眠 0"
	_population_label.add_theme_color_override("font_color", Color("d7c6ef"))
	column.add_child(_population_label)
	_types_label = Label.new()
	_types_label.name = "EnemyTypesLabel"
	_types_label.text = "史莱姆 0  野狼 0  蝙蝠 0"
	_types_label.add_theme_font_size_override("font_size", 13)
	_types_label.add_theme_color_override("font_color", Color("b7adb9"))
	column.add_child(_types_label)
	_states_label = Label.new()
	_states_label.name = "EnemyStatesLabel"
	_states_label.text = "状态  等待生成"
	_states_label.add_theme_font_size_override("font_size", 12)
	_states_label.add_theme_color_override("font_color", Color("918d9c"))
	column.add_child(_states_label)


func _on_enemy_state_changed(value: Dictionary) -> void:
	var counts := value.get("counts", {}) as Dictionary
	var states := value.get("states", {}) as Dictionary
	_population_label.text = "敌人  %d/%d  ·  休眠 %d" % [int(value.get("active", 0)), int(value.get("maximum", 0)), int(value.get("sleeping", 0))]
	_types_label.text = "史莱姆 %d  野狼 %d  蝙蝠 %d" % [int(counts.get("slime", 0)), int(counts.get("wolf", 0)), int(counts.get("cave_bat", 0))]
	var parts: Array[String] = []
	for state_name in ["CHASE", "ATTACK", "RETURN", "HURT"]:
		if int(states.get(state_name, 0)) > 0:
			parts.append("%s %d" % [state_name, int(states[state_name])])
	_states_label.text = "状态  %s" % (" · ".join(parts) if not parts.is_empty() else "游荡 / 休眠")
