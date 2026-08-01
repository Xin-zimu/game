class_name ResourceHud
extends Control

var _catalog := ResourceCatalog.new()
var _tool_label: Label
var _inventory_label: Label
var _feedback_label: Label
var _prompt_label: Label
var _feedback_remaining := 0.0


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	EventBus.resource_prompt_changed.connect(_on_resource_prompt_changed)
	EventBus.active_tool_changed.connect(_on_active_tool_changed)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	EventBus.interaction_feedback.connect(_on_interaction_feedback)
	_on_active_tool_changed(&"hands", _catalog.tool_display_name(&"hands"))
	_on_inventory_changed({})


func _process(delta: float) -> void:
	if _feedback_remaining <= 0.0:
		return
	_feedback_remaining -= delta
	if _feedback_remaining <= 0.0:
		_feedback_label.text = ""


func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.name = "ResourcePanel"
	panel.position = Vector2(24, 168)
	panel.custom_minimum_size = Vector2(310, 116)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("08171ee8")
	style.border_color = Color("8b6d47")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	_tool_label = Label.new()
	_tool_label.name = "ToolLabel"
	_tool_label.add_theme_color_override("font_color", Color("e2c178"))
	column.add_child(_tool_label)
	_inventory_label = Label.new()
	_inventory_label.name = "InventoryLabel"
	_inventory_label.add_theme_font_size_override("font_size", 13)
	_inventory_label.add_theme_color_override("font_color", Color("b9d3c1"))
	column.add_child(_inventory_label)
	_feedback_label = Label.new()
	_feedback_label.name = "FeedbackLabel"
	_feedback_label.add_theme_font_size_override("font_size", 13)
	_feedback_label.add_theme_color_override("font_color", Color("e9b86c"))
	column.add_child(_feedback_label)
	_prompt_label = Label.new()
	_prompt_label.name = "ResourcePromptLabel"
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_label.offset_left = 330
	_prompt_label.offset_right = -330
	_prompt_label.offset_top = -116
	_prompt_label.offset_bottom = -78
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_prompt_label.add_theme_color_override("font_color", Color("fff1bd"))
	add_child(_prompt_label)


func _on_resource_prompt_changed(text: String) -> void:
	_prompt_label.text = text


func _on_active_tool_changed(_tool_id: StringName, display_name: String) -> void:
	_tool_label.text = "当前工具  %s  ·  Q 切换" % display_name


func _on_inventory_changed(inventory: Dictionary) -> void:
	var parts: Array[String] = []
	for item_id in ["wood", "stone", "fiber", "wildflower", "berry"]:
		parts.append("%s %d" % [_catalog.item_display_name(StringName(item_id)), int(inventory.get(item_id, 0))])
	_inventory_label.text = "背包  " + "  ".join(parts)


func _on_interaction_feedback(message: String, successful: bool) -> void:
	_feedback_label.text = message
	_feedback_label.add_theme_color_override("font_color", Color("8fd0a6") if successful else Color("e9b86c"))
	_feedback_remaining = 2.0
