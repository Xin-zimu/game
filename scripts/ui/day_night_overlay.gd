class_name DayNightOverlay
extends ColorRect


func _ready() -> void:
	name = "DayNightOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.TRANSPARENT


func apply_time(snapshot: Dictionary) -> void:
	color = snapshot.get("overlay", Color.TRANSPARENT) as Color
