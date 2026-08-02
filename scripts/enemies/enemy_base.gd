class_name EnemyBase
extends CharacterBody2D

signal defeated(spawn_id: String, enemy_id: StringName, world_position: Vector2, drops: Array)

var definition: EnemyDefinition
var stable_spawn_id := ""
var health := 1.0
var sleeping := false

var _player: PlayerCharacter
var _home_position := Vector2.ZERO
var _state_machine: EnemyStateMachine
var _logic_sleep_distance := 920.0
var _knockback_velocity := Vector2.ZERO
var _wander_direction := Vector2.RIGHT
var _wander_cycle := 0
var _avoidance_direction := Vector2.ZERO
var _avoidance_remaining := 0.0
var _flash_remaining := 0.0
var _death_remaining := 0.0
var _drops_emitted := false


func configure(next_definition: EnemyDefinition, player: PlayerCharacter, spawn_id: String, home_position: Vector2, logic_sleep_distance: float) -> void:
	definition = next_definition
	_player = player
	stable_spawn_id = spawn_id
	_home_position = home_position
	global_position = home_position
	_logic_sleep_distance = logic_sleep_distance
	health = definition.maximum_health
	_state_machine = EnemyStateMachine.new(definition)
	_choose_wander_direction()


func _ready() -> void:
	name = "Enemy_%s" % stable_spawn_id.replace(":", "_")
	add_to_group("enemies")
	z_index = 7
	collision_layer = 8
	collision_mask = 1
	var collision := CollisionShape2D.new()
	collision.name = "EnemyCollisionShape2D"
	var capsule := CapsuleShape2D.new()
	capsule.radius = 10.0
	capsule.height = 24.0
	collision.shape = capsule
	add_child(collision)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if definition == null or _player == null or _state_machine == null:
		velocity = Vector2.ZERO
		return
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	if _state_machine.state == EnemyStateMachine.State.DEAD:
		_process_death(delta)
		return
	var player_distance := global_position.distance_to(_player.global_position)
	if player_distance > _logic_sleep_distance:
		sleeping = true
		velocity = Vector2.ZERO
		return
	sleeping = false
	var previous_state := _state_machine.state
	var result := _state_machine.tick(delta, player_distance, global_position.distance_to(_home_position))
	if previous_state != _state_machine.state and _state_machine.state == EnemyStateMachine.State.WANDER:
		_choose_wander_direction()
	if bool(result["attack_ready"]):
		_attack_player()
	_process_motion(delta)
	queue_redraw()


func receive_attack(payload: Dictionary) -> Dictionary:
	if definition == null or _state_machine == null or _state_machine.state == EnemyStateMachine.State.DEAD:
		return {"accepted": false, "died": true, "damage": 0, "health": health}
	var damage := DamageCalculator.calculate(float(payload.get("damage", 0.0)), definition.defense)
	health = maxf(0.0, health - float(damage))
	_knockback_velocity += (payload.get("direction", Vector2.ZERO) as Vector2).normalized() * float(payload.get("knockback", 0.0))
	_flash_remaining = 0.14
	var died := health <= 0.0
	if died:
		_state_machine.die()
		collision_layer = 0
		_death_remaining = 0.62
		_emit_defeat_once()
	else:
		_state_machine.hurt()
	EventBus.combat_feedback.emit("%s受到 %d 点伤害" % [definition.display_name, damage], true)
	queue_redraw()
	return {"accepted": true, "died": died, "damage": damage, "health": health}


func state_name() -> StringName:
	return _state_machine.state_name() if _state_machine != null else &"IDLE"


func complex_tick_count() -> int:
	return _state_machine.complex_tick_count if _state_machine != null else 0


func home_position() -> Vector2:
	return _home_position


func debug_snapshot() -> Dictionary:
	return {
		"spawn_id": stable_spawn_id,
		"enemy_id": definition.enemy_id if definition != null else &"",
		"state": state_name(),
		"health": health,
		"sleeping": sleeping,
		"position": global_position,
		"home": _home_position,
		"complex_ticks": complex_tick_count(),
	}


func _process_motion(delta: float) -> void:
	_avoidance_remaining = maxf(0.0, _avoidance_remaining - delta)
	var desired := Vector2.ZERO
	match _state_machine.state:
		EnemyStateMachine.State.WANDER:
			desired = _wander_direction
		EnemyStateMachine.State.CHASE:
			desired = global_position.direction_to(_player.global_position)
		EnemyStateMachine.State.RETURN:
			desired = global_position.direction_to(_home_position)
		_:
			desired = Vector2.ZERO
	if _avoidance_remaining > 0.0 and not _avoidance_direction.is_zero_approx():
		desired = (desired * 0.35 + _avoidance_direction * 0.65).normalized()
	var speed := definition.move_speed
	if definition.profile == &"hop":
		speed *= 0.60 + maxf(sin(Time.get_ticks_msec() * 0.010), 0.0) * 0.85
	elif definition.profile == &"pounce" and _state_machine.state == EnemyStateMachine.State.CHASE:
		speed *= 1.12
	elif definition.profile == &"flight":
		speed *= 0.90 + sin(Time.get_ticks_msec() * 0.008 + float(stable_spawn_id.hash() & 31)) * 0.10
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 440.0 * delta)
	velocity = desired * speed + _knockback_velocity
	move_and_slide()
	if get_slide_collision_count() > 0 and not desired.is_zero_approx():
		var collision := get_slide_collision(0)
		var turn := -1.0 if (stable_spawn_id.hash() & 1) == 0 else 1.0
		_avoidance_direction = collision.get_normal().rotated(turn * PI * 0.5).normalized()
		_avoidance_remaining = 0.48


func _attack_player() -> void:
	if _player == null or _player.combat_state().status == &"dead":
		return
	var direction := global_position.direction_to(_player.global_position)
	var result := _player.receive_hit(definition.attack_power, direction, definition.knockback)
	if bool(result.get("accepted", false)):
		EventBus.combat_feedback.emit("%s发动攻击" % definition.display_name, false)


func _choose_wander_direction() -> void:
	var stable_hash := WorldSeed.from_text("%s|wander|%d" % [stable_spawn_id, _wander_cycle])
	_wander_cycle += 1
	var angle := float(stable_hash & 0xffff) / 65536.0 * TAU
	_wander_direction = Vector2.from_angle(angle)


func _emit_defeat_once() -> void:
	if _drops_emitted:
		return
	_drops_emitted = true
	var catalog := EnemyCatalog.new()
	defeated.emit(stable_spawn_id, definition.enemy_id, global_position, catalog.resolve_drops(definition.enemy_id, stable_spawn_id))


func _process_death(delta: float) -> void:
	velocity = Vector2.ZERO
	_death_remaining -= delta
	modulate.a = clampf(_death_remaining / 0.62, 0.0, 1.0)
	if _death_remaining <= 0.0:
		queue_free()


func _draw() -> void:
	if definition == null:
		return
	var body_color := Color.WHITE if _flash_remaining > 0.0 else definition.color
	draw_circle(Vector2(0, 11), 13.0, Color(0, 0, 0, 0.24))
	match definition.profile:
		&"hop":
			draw_circle(Vector2(0, 2), 13.0, body_color)
			draw_rect(Rect2(-13, 2, 26, 10), body_color, true)
			draw_circle(Vector2(-5, 0), 2.0, Color("15251d"))
			draw_circle(Vector2(5, 0), 2.0, Color("15251d"))
		&"pounce":
			var wolf := PackedVector2Array([Vector2(-15, 7), Vector2(-11, -7), Vector2(-5, -13), Vector2(0, -7), Vector2(9, -12), Vector2(15, -3), Vector2(12, 9), Vector2(-7, 11)])
			draw_colored_polygon(wolf, body_color)
			draw_circle(Vector2(8, -4), 2.0, Color("f1d36b"))
		&"flight":
			var flap := 5.0 + sin(Time.get_ticks_msec() * 0.016) * 5.0
			draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(-18, -flap), Vector2(-12, 9), Vector2(0, 5)]), body_color)
			draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(18, -flap), Vector2(12, 9), Vector2(0, 5)]), body_color)
			draw_circle(Vector2.ZERO, 7.0, body_color.lightened(0.08))
			draw_circle(Vector2(-2, -1), 1.5, Color("e36b67"))
	if health < definition.maximum_health:
		draw_rect(Rect2(-16, -25, 32, 4), Color("17201d"), true)
		draw_rect(Rect2(-16, -25, 32.0 * health / definition.maximum_health, 4), Color("d56358"), true)
