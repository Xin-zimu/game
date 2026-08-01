class_name PlayerCharacter
extends CharacterBody2D

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

var _roll_time_remaining := 0.0
var _roll_cooldown_remaining := 0.0
var _roll_direction := Vector2.DOWN


func _ready() -> void:
	add_to_group("player")
	EventBus.player_health_changed.emit(health, maximum_health)
	EventBus.player_stamina_changed.emit(stamina, maximum_stamina)
	_emit_state()


func _physics_process(delta: float) -> void:
	animation_time += delta
	_roll_cooldown_remaining = maxf(0.0, _roll_cooldown_remaining - delta)
	if movement_state == MovementState.ROLL:
		_process_roll(delta)
	else:
		_process_standard_movement(delta)
	move_and_slide()


func take_damage(amount: float) -> void:
	health = clampf(health - maxf(amount, 0.0), 0.0, maximum_health)
	EventBus.player_health_changed.emit(health, maximum_health)


func heal(amount: float) -> void:
	health = clampf(health + maxf(amount, 0.0), 0.0, maximum_health)
	EventBus.player_health_changed.emit(health, maximum_health)


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
	}


func persistence_snapshot() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"health": health,
		"maximum_health": maximum_health,
		"stamina": stamina,
		"maximum_stamina": maximum_stamina,
	}


func restore_snapshot(snapshot: Dictionary) -> void:
	var position_value: Variant = snapshot.get("position", [])
	if position_value is Array and (position_value as Array).size() == 2:
		position = Vector2(float(position_value[0]), float(position_value[1]))
	maximum_health = maxf(float(snapshot.get("maximum_health", maximum_health)), 1.0)
	health = clampf(float(snapshot.get("health", maximum_health)), 0.0, maximum_health)
	maximum_stamina = maxf(float(snapshot.get("maximum_stamina", maximum_stamina)), 1.0)
	stamina = clampf(float(snapshot.get("stamina", maximum_stamina)), 0.0, maximum_stamina)


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
