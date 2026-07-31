class_name ObstacleVisual
extends Node2D

var obstacle_size := Vector2(80, 80)
var obstacle_color := Color("29483a")


func configure(size_value: Vector2, color_value: Color) -> void:
	obstacle_size = size_value
	obstacle_color = color_value
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-obstacle_size * 0.5, obstacle_size)
	draw_rect(Rect2(rect.position + Vector2(5, 7), rect.size), Color(0, 0, 0, 0.22))
	draw_rect(rect, obstacle_color)
	draw_rect(rect.grow(-6), obstacle_color.lightened(0.12), false, 3.0)
	for x in range(int(rect.position.x + 12), int(rect.end.x - 6), 18):
		draw_line(Vector2(x, rect.position.y + 8), Vector2(x, rect.end.y - 8), obstacle_color.darkened(0.16), 2.0)
