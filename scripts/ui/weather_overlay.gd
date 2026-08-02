class_name WeatherOverlay
extends Control

var _tint := Color.TRANSPARENT
var _particle_style: StringName = &"none"
var _particle_color := Color.TRANSPARENT
var _particle_count := 0
var _particle_speed := 0.0
var _offset := 0.0


func _ready() -> void:
	name = "WeatherOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func apply_weather(snapshot: Dictionary) -> void:
	_tint = snapshot.get("tint", Color.TRANSPARENT) as Color
	_particle_style = StringName(snapshot.get("particle_style", &"none"))
	_particle_color = snapshot.get("particle_color", Color.TRANSPARENT) as Color
	_particle_count = maxi(0, int(snapshot.get("particle_count", 0)))
	_particle_speed = maxf(0.0, float(snapshot.get("particle_speed", 0.0)))
	queue_redraw()


func particle_style() -> StringName:
	return _particle_style


func particle_count() -> int:
	return _particle_count


func _process(delta: float) -> void:
	if _particle_count <= 0:
		return
	_offset = fposmod(_offset + delta * _particle_speed, 4096.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _tint)
	if _particle_count <= 0 or _particle_style == &"none" or size.x <= 0.0 or size.y <= 0.0:
		return
	for index in _particle_count:
		var seed_x := posmod(index * 89 + 37, 997)
		var seed_y := posmod(index * 151 + 71, 991)
		var x := fposmod(float(seed_x) / 997.0 * size.x + (_offset * 0.34 if _particle_style == &"sand" else 0.0), size.x)
		var y := fposmod(float(seed_y) / 991.0 * size.y + _offset, size.y)
		match _particle_style:
			&"rain":
				draw_line(Vector2(x, y), Vector2(x - 4.0, y + 13.0), _particle_color, 2.0)
			&"snow":
				draw_circle(Vector2(x + sin(float(index)) * 4.0, y), 2.0 if index % 3 else 3.0, _particle_color)
			&"sand":
				draw_line(Vector2(x, y), Vector2(x + 17.0, y + 3.0), _particle_color, 2.0)
