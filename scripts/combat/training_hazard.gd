class_name TrainingHazard
extends Area2D

const ATTACK_POWER := 24.0
const ATTACK_INTERVAL := 0.75

var _cooldown := 0.0


func _ready() -> void:
	name = "CombatTrainingHazard"
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 17.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return
	for body in get_overlapping_bodies():
		if body is PlayerCharacter:
			var player := body as PlayerCharacter
			var direction := (player.global_position - global_position).normalized()
			var result := player.receive_hit(ATTACK_POWER, direction, 175.0)
			if bool(result.get("accepted", false)):
				_cooldown = ATTACK_INTERVAL
				break


func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.10, 0.02, 0.02, 0.35))
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var direction := Vector2.from_angle(angle)
		var tangent := direction.rotated(PI * 0.5)
		var points := PackedVector2Array([direction * 8.0 - tangent * 5.0, direction * 24.0, direction * 8.0 + tangent * 5.0])
		draw_colored_polygon(points, Color("b94d45"))
	draw_circle(Vector2.ZERO, 9.0, Color("6d2728"))
