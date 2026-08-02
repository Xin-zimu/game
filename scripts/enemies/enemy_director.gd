class_name EnemyDirector
extends Node2D

var _world_seed := 0
var _player: PlayerCharacter
var _drop_pool: WorldDropPool
var _catalog := EnemyCatalog.new()
var _planner: EnemySpawnPlanner
var _active: Dictionary = {}
var _cooldowns: Dictionary = {}
var _population_elapsed := 0.0
var _spawn_cursor := 0


func configure(world_seed: int, player: PlayerCharacter, drop_pool: WorldDropPool) -> void:
	_world_seed = world_seed
	_player = player
	_drop_pool = drop_pool
	_planner = EnemySpawnPlanner.new(world_seed, _catalog)


func _ready() -> void:
	name = "EnemyDirector"
	z_index = 6
	if _player == null or _drop_pool == null or not _catalog.is_valid():
		push_error("EnemyDirector requires a player, drop pool and valid enemy catalog.")
		set_process(false)
		return
	population_step()


func _process(delta: float) -> void:
	for spawn_id_value in _cooldowns.keys():
		var spawn_id := String(spawn_id_value)
		_cooldowns[spawn_id] = maxf(0.0, float(_cooldowns[spawn_id]) - delta)
		if float(_cooldowns[spawn_id]) <= 0.0:
			_cooldowns.erase(spawn_id)
	_population_elapsed += delta
	if _population_elapsed >= float(_catalog.population_value("population_tick_seconds", 0.45)):
		_population_elapsed = 0.0
		population_step()


func population_step() -> void:
	if _player == null or _planner == null:
		return
	_despawn_far_enemies()
	if _active.size() < _catalog.maximum_active():
		_spawn_from_nearby_chunks()
	_emit_metrics()


func active_count() -> int:
	return _active.size()


func sleeping_count() -> int:
	var result := 0
	for enemy_value in _active.values():
		var enemy := enemy_value as EnemyBase
		if is_instance_valid(enemy) and enemy.sleeping:
			result += 1
	return result


func maximum_active() -> int:
	return _catalog.maximum_active()


func active_snapshots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy_value in _active.values():
		var enemy := enemy_value as EnemyBase
		if is_instance_valid(enemy):
			result.append(enemy.debug_snapshot())
	return result


func catalog() -> EnemyCatalog:
	return _catalog


func _spawn_from_nearby_chunks() -> void:
	var current_chunk := WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(_player.global_position))
	var chunk_coordinates := ChunkStreamPlanner.coordinates_in_radius(current_chunk, ChunkStreamPlanner.PRELOAD_RADIUS)
	_planner.retain_chunks(chunk_coordinates)
	var candidates: Array[Dictionary] = []
	for coordinate in chunk_coordinates:
		candidates.append_array(_planner.candidates_for_chunk(coordinate))
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["spawn_id"]) < String(b["spawn_id"])
	)
	var start := posmod(_spawn_cursor, candidates.size())
	_spawn_cursor += 1
	for offset in candidates.size():
		if _active.size() >= _catalog.maximum_active():
			break
		var candidate := candidates[posmod(start + offset, candidates.size())]
		var spawn_id := String(candidate["spawn_id"])
		if _active.has(spawn_id) or _cooldowns.has(spawn_id):
			continue
		var world_position := candidate["world_position"] as Vector2
		var distance := world_position.distance_to(_player.global_position)
		if distance < float(_catalog.population_value("spawn_minimum_distance_pixels", 760.0)) \
				or distance > float(_catalog.population_value("spawn_maximum_distance_pixels", 1450.0)) \
				or _is_on_screen(world_position, 96.0):
			continue
		_spawn_enemy(candidate)


func _spawn_enemy(candidate: Dictionary) -> EnemyBase:
	var definition := _catalog.enemy(candidate["enemy_id"] as StringName)
	if definition == null:
		return null
	var enemy := EnemyBase.new()
	var spawn_id := String(candidate["spawn_id"])
	enemy.configure(
		definition,
		_player,
		spawn_id,
		candidate["world_position"] as Vector2,
		float(_catalog.population_value("logic_sleep_distance_pixels", 920.0))
	)
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)
	_active[spawn_id] = enemy
	return enemy


func _despawn_far_enemies() -> void:
	var maximum_distance := float(_catalog.population_value("despawn_distance_pixels", 1700.0))
	for spawn_id_value in _active.keys():
		var spawn_id := String(spawn_id_value)
		var enemy := _active[spawn_id] as EnemyBase
		if not is_instance_valid(enemy):
			_active.erase(spawn_id)
			continue
		if enemy.global_position.distance_to(_player.global_position) <= maximum_distance:
			continue
		_active.erase(spawn_id)
		_cooldowns[spawn_id] = 2.0
		enemy.queue_free()


func _on_enemy_defeated(spawn_id: String, enemy_id: StringName, world_position: Vector2, drops: Array) -> void:
	_active.erase(spawn_id)
	_cooldowns[spawn_id] = float(_catalog.population_value("respawn_cooldown_seconds", 18.0))
	var drop_index := 0
	for drop_value in drops:
		var drop := drop_value as Dictionary
		var offset := Vector2((drop_index - 1) * 11, 5 + posmod(drop_index, 2) * 5)
		if not _drop_pool.spawn_drop(drop["item_id"] as StringName, int(drop["quantity"]), world_position + offset):
			LogManager.warning("EnemyDirector", "掉落池已满，无法生成 %s" % drop["item_id"])
		drop_index += 1
	EventBus.combat_feedback.emit("击败%s，掉落已生成" % _catalog.enemy(enemy_id).display_name, true)
	_emit_metrics()


func _is_on_screen(world_position: Vector2, margin: float) -> bool:
	if get_viewport() == null:
		return false
	var screen_position := get_viewport().get_canvas_transform() * world_position
	return Rect2(Vector2.ZERO, get_viewport_rect().size).grow(margin).has_point(screen_position)


func _emit_metrics() -> void:
	var counts := {"slime": 0, "wolf": 0, "cave_bat": 0}
	var states := {}
	for enemy_value in _active.values():
		var enemy := enemy_value as EnemyBase
		if not is_instance_valid(enemy) or enemy.definition == null:
			continue
		var enemy_id := String(enemy.definition.enemy_id)
		counts[enemy_id] = int(counts.get(enemy_id, 0)) + 1
		var state := String(enemy.state_name())
		states[state] = int(states.get(state, 0)) + 1
	EventBus.enemy_state_changed.emit({
		"active": _active.size(),
		"sleeping": sleeping_count(),
		"maximum": _catalog.maximum_active(),
		"counts": counts,
		"states": states,
		"cooldowns": _cooldowns.size(),
	})
