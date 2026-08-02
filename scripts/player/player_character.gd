class_name PlayerCharacter
extends CharacterBody2D

signal died(death_position: Vector2)
signal respawned(respawn_position: Vector2)

enum MovementState { IDLE, WALK, RUN, ROLL }

const ROLL_DURATION := 0.28
const ROLL_COOLDOWN := 0.18
const RUN_STAMINA_PER_SECOND := 24.0
const ROLL_STAMINA_COST := 20.0
const STAMINA_RECOVERY_PER_SECOND := 19.0

var maximum_health := 100.0
var health := 100.0
var maximum_stamina := 100.0
var stamina := 100.0
var movement_state := MovementState.IDLE
var facing := Vector2.DOWN
var animation_time := 0.0
var attack_flash_remaining := 0.0

var _roll_time_remaining := 0.0
var _roll_cooldown_remaining := 0.0
var _roll_direction := Vector2.DOWN
var _knockback_velocity := Vector2.ZERO
var _combat_state := PlayerCombatState.new()


func _ready() -> void:
	add_to_group("player")
	EventBus.player_health_changed.emit(health, maximum_health)
	EventBus.player_stamina_changed.emit(stamina, maximum_stamina)
	_emit_state()


func _physics_process(delta: float) -> void:
	animation_time += delta
	attack_flash_remaining = maxf(0.0, attack_flash_remaining - delta)
	_combat_state.tick(delta)
	_roll_cooldown_remaining = maxf(0.0, _roll_cooldown_remaining - delta)
	if _combat_state.status == &"dead":
		velocity = Vector2.ZERO
	elif movement_state == MovementState.ROLL:
		_process_roll(delta)
	else:
		_process_standard_movement(delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 620.0 * delta)
	velocity += _knockback_velocity
	move_and_slide()


func take_damage(amount: float) -> void:
	receive_hit(amount, Vector2.ZERO, 0.0)


func receive_hit(attack_power: float, direction: Vector2, knockback: float) -> Dictionary:
	var result := _combat_state.apply_hit(health, maximum_health, attack_power, direction, knockback)
	if not bool(result["accepted"]):
		return result
	health = float(result["health"])
	_knockback_velocity += result["knockback"] as Vector2
	EventBus.player_health_changed.emit(health, maximum_health)
	EventBus.combat_feedback.emit("受到 %d 点伤害" % int(result["damage"]), false)
	if bool(result["died"]):
		died.emit(global_position)
	return result


func heal(amount: float) -> void:
	health = clampf(health + maxf(amount, 0.0), 0.0, maximum_health)
	EventBus.player_health_changed.emit(health, maximum_health)


func spend_stamina(amount: float) -> bool:
	var cost := maxf(amount, 0.0)
	if stamina < cost:
		return false
	_set_stamina(stamina - cost)
	return true


func restore_stamina(amount: float) -> void:
	_set_stamina(stamina + maxf(amount, 0.0))


func combat_state() -> PlayerCombatState:
	return _combat_state


func respawn_at(world_position: Vector2) -> void:
	global_position = world_position
	health = maximum_health
	stamina = maximum_stamina
	velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	_combat_state.respawn()
	_set_state(MovementState.IDLE)
	EventBus.player_health_changed.emit(health, maximum_health)
	EventBus.player_stamina_changed.emit(stamina, maximum_stamina)
	EventBus.combat_feedback.emit("已在安全位置重生", true)
	respawned.emit(world_position)


func state_name() -> StringName:
	match movement_state:
		MovementState.WALK:
			return &"WALK"
		MovementState.RUN:
			return &"RUN"
		MovementState.ROLL:
			return &"ROLL"
		_:
			return &"IDLE"


func debug_snapshot() -> Dictionary:
	return {
		"position": global_position,
		"state": state_name(),
		"health": health,
		"stamina": stamina,
		"defense": _combat_state.defense,
		"invulnerability": _combat_state.invulnerability_remaining,
		"death_count": _combat_state.death_count,
	}


func persistence_snapshot() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"health": health,
		"maximum_health": maximum_health,
		"stamina": stamina,
		"maximum_stamina": maximum_stamina,
		"combat_state": _combat_state.persistence_snapshot(),
	}


func restore_snapshot(snapshot: Dictionary) -> void:
	var position_value: Variant = snapshot.get("position", [])
	if position_value is Array and (position_value as Array).size() == 2:
		position = Vector2(float(position_value[0]), float(position_value[1]))
	maximum_health = maxf(float(snapshot.get("maximum_health", maximum_health)), 1.0)
	health = clampf(float(snapshot.get("health", maximum_health)), 0.0, maximum_health)
	maximum_stamina = maxf(float(snapshot.get("maximum_stamina", maximum_stamina)), 1.0)
	stamina = clampf(float(snapshot.get("stamina", maximum_stamina)), 0.0, maximum_stamina)
	_combat_state.restore_snapshot(snapshot.get("combat_state", {}) as Dictionary, position)


func _process_standard_movement(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not input_vector.is_zero_approx():
		facing = input_vector.normalized()
	if Input.is_action_just_pressed("roll") and _can_roll(input_vector):
		_start_roll(input_vector)
		return
	var wants_to_run := Input.is_action_pressed("run") and stamina > 0.0 and not input_vector.is_zero_approx()
	velocity = PlayerMotor.velocity_for(input_vector, wants_to_run)
	if wants_to_run:
		_set_state(MovementState.RUN)
		_set_stamina(stamina - RUN_STAMINA_PER_SECOND * delta)
	elif not input_vector.is_zero_approx():
		_set_state(MovementState.WALK)
		_set_stamina(stamina + STAMINA_RECOVERY_PER_SECOND * delta)
	else:
		_set_state(MovementState.IDLE)
		_set_stamina(stamina + STAMINA_RECOVERY_PER_SECOND * delta)


func _can_roll(input_vector: Vector2) -> bool:
	return _roll_cooldown_remaining <= 0.0 and stamina >= ROLL_STAMINA_COST and not input_vector.is_zero_approx()


func _start_roll(input_vector: Vector2) -> void:
	_roll_direction = input_vector.normalized()
	facing = _roll_direction
	_roll_time_remaining = ROLL_DURATION
	_set_stamina(stamina - ROLL_STAMINA_COST)
	_combat_state.grant_invulnerability(ROLL_DURATION)
	_set_state(MovementState.ROLL)
	velocity = _roll_direction * PlayerMotor.ROLL_SPEED


func _process_roll(delta: float) -> void:
	_roll_time_remaining -= delta
	var progress := clampf(_roll_time_remaining / ROLL_DURATION, 0.0, 1.0)
	velocity = _roll_direction * PlayerMotor.ROLL_SPEED * (0.72 + 0.28 * progress)
	if _roll_time_remaining <= 0.0:
		_roll_cooldown_remaining = ROLL_COOLDOWN
		velocity = Vector2.ZERO
		_set_state(MovementState.IDLE)


func _set_stamina(value: float) -> void:
	var previous := stamina
	stamina = clampf(value, 0.0, maximum_stamina)
	if not is_equal_approx(previous, stamina):
		EventBus.player_stamina_changed.emit(stamina, maximum_stamina)


func _set_state(next_state: MovementState) -> void:
	if movement_state == next_state:
		return
	movement_state = next_state
	_emit_state()


func _emit_state() -> void:
	EventBus.player_state_changed.emit(state_name())
