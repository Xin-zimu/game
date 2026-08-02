class_name GraveMarker
extends Node2D

var grave_id := 0


func configure(next_grave_id: int, world_position: Vector2) -> void:
	grave_id = next_grave_id
	position = world_position
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var pulse := 0.75 + sin(Time.get_ticks_msec() * 0.004 + float(grave_id)) * 0.12
	draw_circle(Vector2(0, 11), 14.0, Color(0.02, 0.03, 0.03, 0.35))
	draw_rect(Rect2(-9, -15, 18, 27), Color("70777b"), true)
	draw_rect(Rect2(-12, -18, 24, 7), Color("9da3a5"), true)
	draw_line(Vector2(-4, -8), Vector2(4, -8), Color("263238"), 2.0)
	draw_line(Vector2(0, -12), Vector2(0, 0), Color("263238"), 2.0)
	draw_arc(Vector2.ZERO, 22.0 + pulse * 2.0, 0.0, TAU, 24, Color(0.85, 0.72, 0.38, pulse), 2.0)
