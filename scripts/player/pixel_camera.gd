class_name PixelCamera
extends Camera2D


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 9.0
	limit_smoothed = true
	limit_left = -1160
	limit_right = 1160
	limit_top = -760
	limit_bottom = 760
	enabled = true
