class_name CombatTargetDummy
extends CharacterBody2D

const MAXIMUM_HEALTH := 60.0
const DEFENSE := 3.0

var health := MAXIMUM_HEALTH
var hit_count := 0
var last_attack_id := 0
var _home_position := Vector2.ZERO
var _reset_remaining := 0.0
var _knockback_velocity := Vector2.ZERO
var _flash_remaining := 0.0


func _ready() -> void:
	name = "CombatTrainingDummy"
	collision_layer = 8
	collision_mask = 1
	_home_position = position
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11.0
	capsule.height = 30.0
	shape.shape = capsule
	add_child(shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	if _reset_remaining > 0.0:
		_reset_remaining -= delta
		if _reset_remaining <= 0.0:
			health = MAXIMUM_HEALTH
			position = _home_position
			visible = true
			collision_layer = 8
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	velocity = _knockback_velocity
	move_and_slide()
	queue_redraw()


func receive_attack(payload: Dictionary) -> Dictionary:
	if _reset_remaining > 0.0:
		return {"accepted": false, "died": true, "damage": 0}
	var damage := DamageCalculator.calculate(float(payload.get("damage", 0.0)), DEFENSE)
	health = maxf(0.0, health - float(damage))
	hit_count += 1
	last_attack_id = int(payload.get("attack_id", 0))
	_knockback_velocity += (payload.get("direction", Vector2.ZERO) as Vector2).normalized() * float(payload.get("knockback", 0.0))
	_flash_remaining = 0.12
	var died := health <= 0.0
	if died:
		visible = false
		collision_layer = 0
		_reset_remaining = 1.0
	EventBus.combat_feedback.emit("训练目标受到 %d 点伤害" % damage, true)
	return {"accepted": true, "died": died, "damage": damage, "health": health}


func debug_snapshot() -> Dictionary:
	return {"health": health, "hit_count": hit_count, "last_attack_id": last_attack_id, "knockback": _knockback_velocity}


func _draw() -> void:
	var body_color := Color("e7c575") if _flash_remaining <= 0.0 else Color.WHITE
	draw_circle(Vector2(0, 12), 14.0, Color(0, 0, 0, 0.28))
	draw_rect(Rect2(-10, -15, 20, 29), body_color, true)
	draw_rect(Rect2(-14, -19, 28, 6), Color("8b5d36"), true)
	draw_line(Vector2(-6, -4), Vector2(6, 5), Color("4b3826"), 3.0)
	draw_line(Vector2(6, -4), Vector2(-6, 5), Color("4b3826"), 3.0)
	draw_rect(Rect2(-18, -27, 36, 5), Color("16221d"), true)
	draw_rect(Rect2(-18, -27, 36.0 * health / MAXIMUM_HEALTH, 5), Color("d46657"), true)
