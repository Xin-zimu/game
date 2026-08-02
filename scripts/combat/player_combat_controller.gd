class_name PlayerCombatController
extends Node2D

var _player: PlayerCharacter
var _stream_manager: ChunkStreamManager
var _weapon_catalog := WeaponCatalog.new()
var _sequence := AttackSequenceModel.new()
var _hitbox: Area2D
var _shape: CollisionShape2D
var _active_payload: Dictionary = {}
var _durability_consumed := false


func configure(player: PlayerCharacter, stream_manager: ChunkStreamManager) -> void:
	_player = player
	_stream_manager = stream_manager


func _ready() -> void:
	z_index = 8
	_hitbox = Area2D.new()
	_hitbox.name = "PlayerAttackHitbox"
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 8
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	_hitbox.body_entered.connect(_on_body_entered)
	add_child(_hitbox)
	_shape = CollisionShape2D.new()
	_shape.name = "AttackCollisionShape2D"
	_hitbox.add_child(_shape)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_sequence.tick(delta)
	var active := _sequence.active()
	_hitbox.monitoring = active
	_shape.disabled = not active
	if active:
		for body in _hitbox.get_overlapping_bodies():
			_attempt_hit(body)
	else:
		_active_payload.clear()
	queue_redraw()
	_emit_status()


func request_attack() -> Dictionary:
	if _player == null or _stream_manager == null:
		return _fail("战斗系统尚未就绪")
	var definition := _weapon_catalog.weapon(_stream_manager.active_weapon_id())
	if definition == null:
		definition = _weapon_catalog.weapon(&"unarmed")
	if not _sequence.can_attack():
		return _fail("攻击仍在冷却")
	if not _player.spend_stamina(definition.stamina_cost):
		return _fail("体力不足，无法攻击")
	var result := _sequence.request_attack(definition, _player.facing)
	if not bool(result["ok"]):
		_player.restore_stamina(definition.stamina_cost)
		return result
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(definition.attack_range, definition.hitbox_width)
	_shape.shape = rectangle
	_shape.disabled = false
	_hitbox.position = result["hitbox_position"] as Vector2
	_hitbox.rotation = float(result["hitbox_rotation"])
	_hitbox.monitoring = true
	_active_payload = {
		"attack_id": int(result["attack_id"]),
		"combo_index": int(result["combo_index"]),
		"weapon_id": String(definition.weapon_id),
		"damage": float(result["damage"]),
		"direction": result["direction"],
		"knockback": float(result["knockback"]),
		"active_duration": float(result["active_duration"]),
	}
	_durability_consumed = false
	_player.attack_flash_remaining = definition.active_duration
	EventBus.attack_started.emit(_active_payload.duplicate(true))
	EventBus.combat_feedback.emit("%s · 第 %d 段" % [definition.display_name, int(result["combo_index"])], true)
	_emit_status()
	queue_redraw()
	return result


func sequence_model() -> AttackSequenceModel:
	return _sequence


func _on_body_entered(body: Node2D) -> void:
	_attempt_hit(body)


func _attempt_hit(target: Node) -> bool:
	if _active_payload.is_empty() or target == null or not target.has_method("receive_attack"):
		return false
	if not _sequence.register_target_hit(int(target.get_instance_id())):
		return false
	var result := target.call("receive_attack", _active_payload.duplicate(true)) as Dictionary
	if not bool(result.get("accepted", false)):
		return false
	if not _durability_consumed:
		_durability_consumed = true
		_stream_manager.consume_selected_weapon_durability()
	return true


func _emit_status() -> void:
	if _stream_manager == null:
		return
	var definition := _weapon_catalog.weapon(_stream_manager.active_weapon_id())
	if definition == null:
		definition = _weapon_catalog.weapon(&"unarmed")
	EventBus.combat_status_changed.emit({
		"weapon_id": String(definition.weapon_id),
		"weapon_name": definition.display_name,
		"combo_index": _sequence.combo_index,
		"combo_count": definition.combo_count(),
		"cooldown_remaining": _sequence.cooldown_remaining,
		"cooldown_total": definition.cooldown(),
		"active": _sequence.active(),
	})


func _draw() -> void:
	if not _sequence.active() or _active_payload.is_empty():
		return
	var direction := (_active_payload.get("direction", Vector2.DOWN) as Vector2).normalized()
	var center_angle := direction.angle()
	var progress := 1.0 - clampf(_sequence.active_remaining / maxf(float(_active_payload.get("active_duration", 0.12)), 0.01), 0.0, 1.0)
	var radius := 30.0 + progress * 12.0
	draw_arc(Vector2.ZERO, radius, center_angle - 0.75, center_angle + 0.75, 18, Color("f5d278"), 4.0)


func _fail(message: String) -> Dictionary:
	EventBus.combat_feedback.emit(message, false)
	return {"ok": false, "message": message}
