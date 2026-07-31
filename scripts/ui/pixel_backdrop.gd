class_name PixelBackdrop
extends Control

const GRID_SIZE := 32


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07121d"))
	for y in range(0, int(size.y) + GRID_SIZE, GRID_SIZE):
		for x in range(0, int(size.x) + GRID_SIZE, GRID_SIZE):
			var alternate := ((x / GRID_SIZE) + (y / GRID_SIZE)) as int
			var color := Color("0a1924") if alternate % 2 == 0 else Color("0c1d29")
			draw_rect(Rect2(x, y, GRID_SIZE, GRID_SIZE), color)
	var horizon_y := size.y * 0.72
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon_y), Vector2(size.x * 0.16, horizon_y - 90),
		Vector2(size.x * 0.32, horizon_y - 24), Vector2(size.x * 0.48, horizon_y - 130),
		Vector2(size.x * 0.7, horizon_y - 38), Vector2(size.x * 0.86, horizon_y - 112),
		Vector2(size.x, horizon_y - 50), Vector2(size.x, size.y), Vector2(0, size.y)
	]), Color("15382f"))
	draw_rect(Rect2(0, horizon_y, size.x, size.y - horizon_y), Color("1f4a3a"))
	for x in range(0, int(size.x), 48):
		var height := 12 + ((x / 48) as int % 3) * 7
		draw_rect(Rect2(x, horizon_y - height, 28, height), Color("2d6b4e"))
