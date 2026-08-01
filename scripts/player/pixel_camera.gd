class_name PixelCamera
extends Camera2D


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 9.0
	limit_smoothed = true
	enabled = true


func configure_limits(world_rect: Rect2) -> void:
	limit_left = floori(world_rect.position.x)
	limit_right = ceili(world_rect.end.x)
	limit_top = floori(world_rect.position.y)
	limit_bottom = ceili(world_rect.end.y)
	position = Vector2.ZERO


func configure_unbounded() -> void:
	limit_left = -1000000000
	limit_right = 1000000000
	limit_top = -1000000000
	limit_bottom = 1000000000
	zoom = Vector2.ONE
	position = Vector2.ZERO
