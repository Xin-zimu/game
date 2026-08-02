class_name AttackSequenceModel
extends RefCounted

const COMBO_RESET_SECONDS := 0.72

var cooldown_remaining := 0.0
var active_remaining := 0.0
var combo_remaining := 0.0
var combo_index := 0
var active_attack_id := 0
var last_error := ""

var _serial := 0
var _hit_target_ids: Dictionary = {}


func tick(delta: float) -> void:
	var step := maxf(delta, 0.0)
	cooldown_remaining = maxf(0.0, cooldown_remaining - step)
	active_remaining = maxf(0.0, active_remaining - step)
	combo_remaining = maxf(0.0, combo_remaining - step)
	if combo_remaining <= 0.0:
		combo_index = 0


func can_attack() -> bool:
	return cooldown_remaining <= 0.0


func request_attack(definition: WeaponDefinition, facing: Vector2) -> Dictionary:
	if definition == null:
		return _fail("攻击武器数据不存在")
	if not can_attack():
		return _fail("攻击仍在冷却")
	var direction := facing.normalized()
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	_serial += 1
	active_attack_id = _serial
	combo_index = 1 if combo_remaining <= 0.0 else posmod(combo_index, definition.combo_count()) + 1
	cooldown_remaining = definition.cooldown()
	active_remaining = definition.active_duration
	combo_remaining = COMBO_RESET_SECONDS
	_hit_target_ids.clear()
	last_error = ""
	var transform := hitbox_transform(direction, definition.attack_range)
	return {
		"ok": true,
		"attack_id": active_attack_id,
		"combo_index": combo_index,
		"direction": direction,
		"hitbox_position": transform["position"],
		"hitbox_rotation": transform["rotation"],
		"damage": definition.damage_for_combo(combo_index),
		"knockback": definition.knockback,
		"active_duration": definition.active_duration,
	}


func register_target_hit(target_id: int) -> bool:
	if active_remaining <= 0.0 or target_id <= 0 or _hit_target_ids.has(target_id):
		return false
	_hit_target_ids[target_id] = true
	return true


func active() -> bool:
	return active_remaining > 0.0


static func hitbox_transform(direction: Vector2, attack_range: float) -> Dictionary:
	var normalized := direction.normalized()
	if normalized.is_zero_approx():
		normalized = Vector2.DOWN
	return {
		"position": normalized * attack_range * 0.5,
		"rotation": normalized.angle(),
	}


func _fail(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "message": message}
