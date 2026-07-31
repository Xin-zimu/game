class_name PixelCamera
extends Camera2D


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 9.0
	limit_smoothed = true
	zoom = Vector2.ONE * 1.5
	enabled = true


func configure_limits(world_rect: Rect2) -> void:
	limit_left = floori(world_rect.position.x)
	limit_right = ceili(world_rect.end.x)
	limit_top = floori(world_rect.position.y)
	limit_bottom = ceili(world_rect.end.y)
	position = Vector2.ZERO
