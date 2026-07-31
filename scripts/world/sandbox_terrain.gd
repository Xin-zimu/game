class_name SandboxTerrain
extends Node2D

const WORLD_RECT := Rect2(-1200, -800, 2400, 1600)
const CELL_SIZE := 32


func _ready() -> void:
	z_index = -20
	queue_redraw()


func _draw() -> void:
	draw_rect(WORLD_RECT, Color("173e32"))
	for y in range(int(WORLD_RECT.position.y), int(WORLD_RECT.end.y), CELL_SIZE):
		for x in range(int(WORLD_RECT.position.x), int(WORLD_RECT.end.x), CELL_SIZE):
			var parity := posmod((x / CELL_SIZE) as int + (y / CELL_SIZE) as int, 2)
			var color := Color("1d4a39") if parity == 0 else Color("204f3d")
			draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), color)
	var river := PackedVector2Array([
		Vector2(620, -800), Vector2(850, -800), Vector2(790, -420),
		Vector2(930, -100), Vector2(820, 230), Vector2(900, 800),
		Vector2(650, 800), Vector2(680, 270), Vector2(580, -80),
		Vector2(650, -430),
	])
	draw_colored_polygon(river, Color("255d73"))
	for index in 42:
		var px := -1080 + posmod(index * 173, 1940)
		var py := -700 + posmod(index * 257, 1400)
		if px < 560 or px > 940:
			var flower := Color("f5c96a") if index % 3 == 0 else Color("84c69b")
			draw_circle(Vector2(px, py), 2.0, flower)
	draw_rect(WORLD_RECT, Color("7eb28d"), false, 5.0)
