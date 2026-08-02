class_name PlayerCombatState
extends RefCounted

const SCHEMA_VERSION := 1
const HIT_INVULNERABILITY_SECONDS := 0.55
const RESPAWN_INVULNERABILITY_SECONDS := 0.9

var defense := 0.0
var invulnerability_remaining := 0.0
var death_count := 0
var status: StringName = &"alive"
var respawn_position := Vector2.ZERO
var last_error := ""


func tick(delta: float) -> void:
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - maxf(delta, 0.0))


func apply_hit(current_health: float, maximum_health: float, attack_power: float, direction: Vector2, knockback: float) -> Dictionary:
	if status == &"dead" or invulnerability_remaining > 0.0:
		return {"accepted": false, "died": status == &"dead", "health": current_health, "damage": 0, "knockback": Vector2.ZERO}
	var damage := DamageCalculator.calculate(attack_power, defense)
	var next_health := clampf(current_health - float(damage), 0.0, maxf(maximum_health, 1.0))
	var died := next_health <= 0.0
	if died:
		status = &"dead"
		death_count += 1
		invulnerability_remaining = 0.0
	else:
		invulnerability_remaining = HIT_INVULNERABILITY_SECONDS
	var push_direction := direction.normalized()
	return {
		"accepted": true,
		"died": died,
		"health": next_health,
		"damage": damage,
		"knockback": push_direction * maxf(knockback, 0.0),
	}


func respawn() -> void:
	status = &"alive"
	invulnerability_remaining = RESPAWN_INVULNERABILITY_SECONDS


func grant_invulnerability(duration: float) -> void:
	invulnerability_remaining = maxf(invulnerability_remaining, maxf(duration, 0.0))


func persistence_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"defense": defense,
		"invulnerability_remaining": invulnerability_remaining,
		"death_count": death_count,
		"status": String(status),
		"respawn_position": [respawn_position.x, respawn_position.y],
	}


func restore_snapshot(value: Dictionary, fallback_position := Vector2.ZERO) -> bool:
	if value.is_empty():
		defense = 0.0
		invulnerability_remaining = 0.0
		death_count = 0
		status = &"alive"
		respawn_position = fallback_position
		last_error = ""
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION:
		last_error = "战斗状态版本无效"
		return false
	var position_value: Variant = value.get("respawn_position", [])
	if not position_value is Array or (position_value as Array).size() != 2:
		last_error = "重生位置必须包含两个坐标"
		return false
	var restored_status := StringName(value.get("status", "alive"))
	if not [&"alive", &"dead"].has(restored_status):
		last_error = "玩家战斗状态无效"
		return false
	var restored_defense := float(value.get("defense", 0.0))
	var restored_invulnerability := float(value.get("invulnerability_remaining", 0.0))
	var restored_deaths := int(value.get("death_count", 0))
	if restored_defense < 0.0 or restored_invulnerability < 0.0 or restored_deaths < 0:
		last_error = "玩家战斗数值无效"
		return false
	defense = restored_defense
	invulnerability_remaining = restored_invulnerability
	death_count = restored_deaths
	status = restored_status
	respawn_position = Vector2(float(position_value[0]), float(position_value[1]))
	last_error = ""
	return true
