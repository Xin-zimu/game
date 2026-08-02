class_name EnemyStateMachine
extends RefCounted

enum State {
	IDLE,
	WANDER,
	ALERT,
	CHASE,
	ATTACK,
	HURT,
	RETURN,
	DEAD,
}

const IDLE_DURATION := 1.15
const WANDER_DURATION := 2.35
const ALERT_DURATION := 0.28
const HURT_DURATION := 0.20
const HOME_REACHED_DISTANCE := 12.0

var state := State.IDLE
var state_elapsed := 0.0
var cooldown_remaining := 0.0
var attack_triggered := false
var complex_tick_count := 0

var _definition: EnemyDefinition


func _init(definition: EnemyDefinition) -> void:
	_definition = definition


func tick(delta: float, player_distance: float, home_distance: float) -> Dictionary:
	var safe_delta := maxf(delta, 0.0)
	state_elapsed += safe_delta
	cooldown_remaining = maxf(0.0, cooldown_remaining - safe_delta)
	complex_tick_count += 1
	var attack_ready := false
	match state:
		State.IDLE:
			if player_distance <= _definition.detection_range:
				_transition(State.ALERT)
			elif state_elapsed >= IDLE_DURATION:
				_transition(State.WANDER)
		State.WANDER:
			if player_distance <= _definition.detection_range:
				_transition(State.ALERT)
			elif state_elapsed >= WANDER_DURATION:
				_transition(State.IDLE)
		State.ALERT:
			if player_distance > _definition.disengage_range:
				_transition(State.RETURN)
			elif state_elapsed >= ALERT_DURATION:
				_transition(State.CHASE)
		State.CHASE:
			if player_distance > _definition.disengage_range or home_distance > _definition.return_distance:
				_transition(State.RETURN)
			elif player_distance <= _definition.attack_range and cooldown_remaining <= 0.0:
				_transition(State.ATTACK)
		State.ATTACK:
			if not attack_triggered and state_elapsed >= _definition.attack_windup:
				attack_triggered = true
				attack_ready = true
				cooldown_remaining = _definition.attack_cooldown
			if state_elapsed >= _definition.attack_windup + _definition.attack_recovery:
				_transition(State.CHASE)
		State.HURT:
			if state_elapsed >= HURT_DURATION:
				_transition(State.RETURN if home_distance > _definition.return_distance else State.CHASE)
		State.RETURN:
			if home_distance <= HOME_REACHED_DISTANCE:
				_transition(State.IDLE)
		State.DEAD:
			pass
	return {"state": state, "attack_ready": attack_ready}


func hurt() -> void:
	if state != State.DEAD:
		_transition(State.HURT)


func die() -> void:
	_transition(State.DEAD)


func state_name() -> StringName:
	match state:
		State.WANDER:
			return &"WANDER"
		State.ALERT:
			return &"ALERT"
		State.CHASE:
			return &"CHASE"
		State.ATTACK:
			return &"ATTACK"
		State.HURT:
			return &"HURT"
		State.RETURN:
			return &"RETURN"
		State.DEAD:
			return &"DEAD"
		_:
			return &"IDLE"


func _transition(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	state_elapsed = 0.0
	attack_triggered = false
