class_name UiLayout
extends RefCounted

const EDGE_MARGIN := 24.0
const PANEL_GAP := 14.0
const HOTBAR_SIZE := Vector2(468.0, 84.0)
const HOTBAR_BOTTOM_MARGIN := 16.0
const PROMPT_SIZE := Vector2(720.0, 38.0)
const PROMPT_GAP := 12.0


static func top_left(control: Control, size: Vector2, offset: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + size.x
	control.offset_bottom = offset.y + size.y


static func top_center(control: Control, size: Vector2, top_margin: float) -> void:
	control.set_anchors_preset(Control.PRESET_CENTER_TOP)
	control.offset_left = -size.x * 0.5
	control.offset_top = top_margin
	control.offset_right = size.x * 0.5
	control.offset_bottom = top_margin + size.y


static func top_right(control: Control, size: Vector2, offset: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	control.offset_left = -offset.x - size.x
	control.offset_top = offset.y
	control.offset_right = -offset.x
	control.offset_bottom = offset.y + size.y


static func centered(control: Control, size: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_CENTER)
	control.offset_left = -size.x * 0.5
	control.offset_top = -size.y * 0.5
	control.offset_right = size.x * 0.5
	control.offset_bottom = size.y * 0.5


static func bottom_center(control: Control, size: Vector2, bottom_margin: float) -> void:
	control.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	control.offset_left = -size.x * 0.5
	control.offset_top = -bottom_margin - size.y
	control.offset_right = size.x * 0.5
	control.offset_bottom = -bottom_margin


static func interaction_prompt(control: Control) -> void:
	bottom_center(
		control,
		PROMPT_SIZE,
		HOTBAR_BOTTOM_MARGIN + HOTBAR_SIZE.y + PROMPT_GAP
	)
