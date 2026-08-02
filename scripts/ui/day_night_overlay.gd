class_name DayNightOverlay
extends ColorRect

var _player: Node2D
var _torch_enabled := false


func _ready() -> void:
	name = "DayNightOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.TRANSPARENT
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform bool light_enabled = false;
uniform vec2 light_center = vec2(0.5);
uniform float inner_radius = 0.075;
uniform float outer_radius = 0.19;
void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 delta = UV - light_center;
	delta.x *= aspect;
	float distance_to_light = length(delta);
	float shadow = light_enabled ? smoothstep(inner_radius, outer_radius, distance_to_light) : 1.0;
	COLOR = vec4(COLOR.rgb, COLOR.a * shadow);
}
"""
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	material = shader_material
	set_process(true)


func configure_player(player: Node2D) -> void:
	_player = player


func set_torch_enabled(enabled: bool) -> void:
	_torch_enabled = enabled
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("light_enabled", enabled)


func torch_enabled() -> bool:
	return _torch_enabled


func _process(_delta: float) -> void:
	if not _torch_enabled or _player == null or get_viewport() == null or not material is ShaderMaterial:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var screen_position := get_viewport().get_canvas_transform() * _player.global_position
	(material as ShaderMaterial).set_shader_parameter("light_center", screen_position / viewport_size)


func apply_time(snapshot: Dictionary) -> void:
	color = snapshot.get("overlay", Color.TRANSPARENT) as Color
