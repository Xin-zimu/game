class_name RuinEncounter
extends Node2D

signal milestone_changed(snapshot: Dictionary)

var _plan: Dictionary = {}
var _player: PlayerCharacter
var _state: MilestoneState
var _catalog: MilestoneCatalog
var _guardian: RuinGuardian
var _status_elapsed := 0.0


func configure(plan: Dictionary, player: PlayerCharacter, state: MilestoneState, catalog: MilestoneCatalog) -> void:
	_plan = plan.duplicate(true)
	_player = player
	_state = state
	_catalog = catalog
	global_position = _plan.get("world_position", Vector2.ZERO) as Vector2


func _ready() -> void:
	name = "CanonicalRuin"
	z_index = 5
	queue_redraw()
	_emit_state()


func _process(delta: float) -> void:
	if _player == null or _state == null:
		return
	var distance := global_position.distance_to(_player.global_position)
	_status_elapsed += delta
	if _status_elapsed >= 0.25:
		_status_elapsed = 0.0
		_emit_state()
	if distance <= float(_catalog.ruin_value("discovery_radius_pixels", 300.0)) and _state.discover_ruin():
		EventBus.combat_feedback.emit("发现古老遗迹", true)
		_emit_state()
	if distance <= float(_catalog.ruin_value("activation_radius_pixels", 235.0)) and not _state.boss_defeated and _guardian == null:
		_spawn_guardian()


func try_interact(inventory: InventoryModel) -> bool:
	if _player == null or global_position.distance_to(_player.global_position) > float(_catalog.ruin_value("interaction_radius_pixels", 82.0)):
		return false
	if not _state.boss_defeated:
		EventBus.interaction_feedback.emit("遗迹核心被守卫封锁", false)
		return true
	if _state.reward_claimed:
		EventBus.interaction_feedback.emit("遗迹核心已经取走", true)
		return true
	var result := inventory.add_item(_catalog.reward_item_id(), _catalog.reward_quantity())
	if int(result.get("accepted", 0)) != _catalog.reward_quantity():
		EventBus.interaction_feedback.emit("背包已满，远古核心仍留在遗迹中", false)
		return true
	_state.claim_reward()
	EventBus.interaction_feedback.emit("获得远古核心 · 首个生存闭环完成", true)
	_emit_state()
	return true


func prompt_text() -> String:
	if _player == null or global_position.distance_to(_player.global_position) > float(_catalog.ruin_value("interaction_radius_pixels", 82.0)):
		return ""
	if not _state.boss_defeated:
		return "[E] 遗迹核心 · 守卫封锁"
	if not _state.reward_claimed:
		return "[E] 领取远古核心"
	return "[E] 遗迹核心 · 已完成"


func persistence_snapshot() -> Dictionary:
	return _state.persistence_snapshot()


func guardian() -> RuinGuardian:
	return _guardian


func plan_snapshot() -> Dictionary:
	return _plan.duplicate(true)


func _spawn_guardian() -> void:
	_guardian = RuinGuardian.new()
	_guardian.configure(_catalog, _player)
	_guardian.position = Vector2(0, -62)
	_guardian.defeated.connect(_on_guardian_defeated)
	_guardian.health_changed.connect(_on_guardian_health_changed)
	add_child(_guardian)
	EventBus.combat_feedback.emit("遗迹守卫苏醒", false)
	_emit_state()


func _on_guardian_defeated() -> void:
	_state.defeat_boss()
	EventBus.combat_feedback.emit("遗迹守卫已被击败，核心封印解除", true)
	_emit_state()


func _on_guardian_health_changed(current: float, maximum: float, state_name: StringName) -> void:
	_emit_state({"boss_health": current, "boss_maximum_health": maximum, "boss_state": state_name})


func _emit_state(extra := {}) -> void:
	var snapshot := _state.persistence_snapshot()
	snapshot["objective"] = _state.objective_text()
	snapshot["ruin_position"] = global_position
	snapshot["ruin_biome"] = String(_plan.get("biome_id", ""))
	snapshot["boss_active"] = _guardian != null and is_instance_valid(_guardian) and not _state.boss_defeated
	if _player != null:
		var offset := global_position - _player.global_position
		snapshot["ruin_distance_pixels"] = offset.length()
		snapshot["ruin_direction"] = _direction_name(offset)
	for key in extra:
		snapshot[key] = extra[key]
	milestone_changed.emit(snapshot)
	EventBus.milestone_state_changed.emit(snapshot)


func _direction_name(offset: Vector2) -> String:
	if offset.length_squared() < 1.0:
		return "此处"
	var horizontal := "东" if offset.x > 0.0 else "西"
	var vertical := "南" if offset.y > 0.0 else "北"
	if absf(offset.x) < absf(offset.y) * 0.45:
		return vertical
	if absf(offset.y) < absf(offset.x) * 0.45:
		return horizontal
	return vertical + horizontal


func _draw() -> void:
	draw_circle(Vector2.ZERO, 75.0, Color(0.12, 0.13, 0.12, 0.58))
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var center := Vector2.from_angle(angle) * 58.0
		draw_rect(Rect2(center - Vector2(10, 17), Vector2(20, 34)), Color("71685b"), true)
	draw_circle(Vector2.ZERO, 28.0, Color("232827"))
	draw_circle(Vector2.ZERO, 18.0, Color("d6bb5b") if _state != null and _state.boss_defeated else Color("7f5860"))
	draw_circle(Vector2.ZERO, 8.0, Color("f4dc7d") if _state != null and _state.reward_claimed else Color("33282b"))
