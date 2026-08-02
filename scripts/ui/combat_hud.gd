class_name CombatHud
extends Control

var _weapon_label: Label
var _combo_label: Label
var _cooldown_fill: ColorRect
var _feedback_label: Label
var _grave_label: Label
var _feedback_remaining := 0.0


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	EventBus.combat_status_changed.connect(_on_combat_status_changed)
	EventBus.combat_feedback.connect(_on_combat_feedback)
	EventBus.grave_state_changed.connect(_on_grave_state_changed)


func _process(delta: float) -> void:
	_feedback_remaining = maxf(0.0, _feedback_remaining - delta)
	if _feedback_remaining <= 0.0:
		_feedback_label.text = ""


func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.name = "CombatPanel"
	panel.position = Vector2(958, 24)
	panel.custom_minimum_size = Vector2(298, 116)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("120d12e8")
	style.border_color = Color("965448")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	_weapon_label = Label.new()
	_weapon_label.name = "CombatWeaponLabel"
	_weapon_label.text = "武器  徒手攻击"
	_weapon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_weapon_label.add_theme_color_override("font_color", Color("f0cc8d"))
	row.add_child(_weapon_label)
	_combo_label = Label.new()
	_combo_label.name = "CombatComboLabel"
	_combo_label.text = "连击 0/3"
	_combo_label.add_theme_color_override("font_color", Color("e78f74"))
	row.add_child(_combo_label)
	var track := ColorRect.new()
	track.name = "CombatCooldownTrack"
	track.color = Color("271c20")
	track.custom_minimum_size = Vector2(0, 9)
	column.add_child(track)
	_cooldown_fill = ColorRect.new()
	_cooldown_fill.name = "CombatCooldownFill"
	_cooldown_fill.color = Color("d16b55")
	_cooldown_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.add_child(_cooldown_fill)
	_grave_label = Label.new()
	_grave_label.name = "CombatGraveLabel"
	_grave_label.text = "墓碑  0"
	_grave_label.add_theme_font_size_override("font_size", 13)
	_grave_label.add_theme_color_override("font_color", Color("aeb9b2"))
	column.add_child(_grave_label)
	_feedback_label = Label.new()
	_feedback_label.name = "CombatFeedbackLabel"
	_feedback_label.position = Vector2(430, 162)
	_feedback_label.custom_minimum_size = Vector2(420, 32)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 18)
	_feedback_label.add_theme_color_override("font_color", Color("f0cc8d"))
	add_child(_feedback_label)


func _on_combat_status_changed(value: Dictionary) -> void:
	_weapon_label.text = "武器  %s" % value.get("weapon_name", "徒手攻击")
	_combo_label.text = "连击 %d/%d" % [int(value.get("combo_index", 0)), int(value.get("combo_count", 1))]
	var total := maxf(float(value.get("cooldown_total", 1.0)), 0.001)
	_cooldown_fill.scale.x = clampf(float(value.get("cooldown_remaining", 0.0)) / total, 0.0, 1.0)


func _on_combat_feedback(message: String, successful: bool) -> void:
	_feedback_label.text = message
	_feedback_label.add_theme_color_override("font_color", Color("f0cc8d") if successful else Color("f09a8d"))
	_feedback_remaining = 1.8


func _on_grave_state_changed(value: Dictionary) -> void:
	_grave_label.text = "墓碑  %d · E 取回" % int(value.get("count", 0))
