class_name RuinGuardian
extends CharacterBody2D

signal defeated
signal health_changed(current: float, maximum: float, state: StringName)

var _catalog: MilestoneCatalog
var _player: PlayerCharacter
var _health := 1.0
var _state: StringName = &"DORMANT"
var _cooldown_remaining := 0.0
var _windup_remaining := 0.0
var _attack_committed := false
var _flash_remaining := 0.0
var _death_remaining := 0.0


func configure(catalog: MilestoneCatalog, player: PlayerCharacter) -> void:
	_catalog = catalog
	_player = player
	_health = float(_catalog.boss_value("maximum_health", 180.0))


func _ready() -> void:
	name = "RuinGuardian"
	add_to_group("bosses")
	z_index = 9
	collision_layer = 8
	collision_mask = 1
	var shape_node := CollisionShape2D.new()
	shape_node.name = "GuardianCollisionShape2D"
	var shape := CapsuleShape2D.new()
	shape.radius = 15.0
	shape.height = 35.0
	shape_node.shape = shape
	add_child(shape_node)
	health_changed.emit(_health, maximum_health(), _state)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	if _state == &"DEAD":
		_death_remaining -= delta
		modulate.a = clampf(_death_remaining / 0.8, 0.0, 1.0)
		if _death_remaining <= 0.0:
			queue_free()
		return
	if _player == null:
		return
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	var distance := global_position.distance_to(_player.global_position)
	var detection := float(_catalog.boss_value("detection_range", 320.0))
	var attack_range := float(_catalog.boss_value("attack_range", 48.0))
	if _state == &"SLAM":
		velocity = Vector2.ZERO
		_windup_remaining -= delta
		if _windup_remaining <= 0.0 and not _attack_committed:
			_attack_committed = true
			_attack_player()
		if _windup_remaining <= -0.22:
			_state = &"CHASE"
	elif distance <= attack_range and _cooldown_remaining <= 0.0:
		_state = &"SLAM"
		_windup_remaining = float(_catalog.boss_value("attack_windup", 0.34))
		_attack_committed = false
	elif distance <= detection:
		_state = &"CHASE"
		velocity = global_position.direction_to(_player.global_position) * float(_catalog.boss_value("move_speed", 58.0))
		move_and_slide()
	else:
		_state = &"DORMANT"
		velocity = Vector2.ZERO
	health_changed.emit(_health, maximum_health(), _state)
	queue_redraw()


func receive_attack(payload: Dictionary) -> Dictionary:
	if _state == &"DEAD":
		return {"accepted": false, "died": true, "damage": 0, "health": _health}
	var damage := DamageCalculator.calculate(float(payload.get("damage", 0.0)), float(_catalog.boss_value("defense", 4.0)))
	_health = maxf(0.0, _health - float(damage))
	_flash_remaining = 0.13
	var direction := (payload.get("direction", Vector2.ZERO) as Vector2).normalized()
	velocity += direction * float(payload.get("knockback", 0.0)) * 0.35
	var died := _health <= 0.0
	if died:
		_state = &"DEAD"
		collision_layer = 0
		_death_remaining = 0.8
		defeated.emit()
	else:
		_state = &"HURT"
	EventBus.combat_feedback.emit("遗迹守卫受到 %d 点伤害" % damage, true)
	health_changed.emit(_health, maximum_health(), _state)
	queue_redraw()
	return {"accepted": true, "died": died, "damage": damage, "health": _health}


func maximum_health() -> float:
	return float(_catalog.boss_value("maximum_health", 180.0)) if _catalog != null else 1.0


func health() -> float:
	return _health


func state_name() -> StringName:
	return _state


func _attack_player() -> void:
	_cooldown_remaining = float(_catalog.boss_value("attack_cooldown", 1.55))
	if _player.combat_state().status == &"dead":
		return
	var result := _player.receive_hit(
		float(_catalog.boss_value("attack_power", 22.0)),
		global_position.direction_to(_player.global_position),
		float(_catalog.boss_value("knockback", 175.0))
	)
	if bool(result.get("accepted", false)):
		EventBus.combat_feedback.emit("遗迹守卫发动震地攻击", false)


func _draw() -> void:
	var body := Color.WHITE if _flash_remaining > 0.0 else Color("8b8171")
	draw_circle(Vector2(0, 15), 20.0, Color(0, 0, 0, 0.27))
	draw_rect(Rect2(-18, -14, 36, 35), body, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-23, -13), Vector2(-12, -28), Vector2(0, -18), Vector2(12, -28), Vector2(23, -13)]), body.darkened(0.08))
	draw_circle(Vector2(-7, -4), 3.0, Color("f0c95d"))
	draw_circle(Vector2(7, -4), 3.0, Color("f0c95d"))
	draw_rect(Rect2(-25, -38, 50, 5), Color("171e1b"), true)
	draw_rect(Rect2(-25, -38, 50.0 * _health / maximum_health(), 5), Color("d46657"), true)
