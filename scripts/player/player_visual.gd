class_name PlayerVisual
extends Node2D


func _process(_delta: float) -> void:
	var player := get_parent() as PlayerCharacter
	if player == null:
		return
	rotation = sin(player.animation_time * 28.0) * 0.2 if player.movement_state == PlayerCharacter.MovementState.ROLL else 0.0
	queue_redraw()


func _draw() -> void:
	var player := get_parent() as PlayerCharacter
	if player == null:
		return
	var moving := player.movement_state != PlayerCharacter.MovementState.IDLE
	var bob := sin(player.animation_time * (13.0 if moving else 4.0)) * (2.0 if moving else 0.7)
	var accent := Color("f5c96a") if player.movement_state != PlayerCharacter.MovementState.RUN else Color("ffdf85")
	if player.attack_flash_remaining > 0.0:
		accent = Color("fff2b0")
	if player.combat_state().invulnerability_remaining > 0.0 and int(player.animation_time * 20.0) % 2 == 0:
		modulate = Color(1.0, 1.0, 1.0, 0.42)
	else:
		modulate = Color.WHITE
	_draw_ellipse_shape(Vector2(0, 13), Vector2(15, 6), Color(0, 0, 0, 0.28))
	var body := PackedVector2Array([
		Vector2(-10, 4 + bob), Vector2(-7, -10 + bob), Vector2(0, -16 + bob),
		Vector2(7, -10 + bob), Vector2(10, 4 + bob), Vector2(5, 13 + bob),
		Vector2(-5, 13 + bob),
	])
	draw_colored_polygon(body, Color("315f4b"))
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, Color("9ed0ac"), 2.0, true)
	draw_circle(Vector2(0, -17 + bob), 8.0, Color("d9b48b"))
	draw_arc(Vector2(0, -17 + bob), 8.0, PI, TAU, 16, Color("172c2a"), 5.0)
	var facing_tip := player.facing.normalized() * 13.0 + Vector2(0, -2 + bob)
	draw_line(Vector2(0, -2 + bob), facing_tip, accent, 3.0, true)
	draw_circle(facing_tip, 2.2, accent)


func _draw_ellipse_shape(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 20:
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
