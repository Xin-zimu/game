class_name ChunkStreamManager
extends Node

signal metrics_changed(metrics: Dictionary)

const MAX_CONCURRENT_JOBS := 4

var _world_seed := 0
var _player: PlayerCharacter
var _current_chunk := Vector2i.ZERO
var _movement_direction := Vector2i.ZERO
var _cache: Dictionary = {}
var _renderers: Dictionary = {}
var _queue: Array[Vector2i] = []
var _jobs: Dictionary = {}
var _task_ids: Dictionary = {}
var _preload_targets: Dictionary = {}
var _catalog := BiomeCatalog.new()
var _resource_catalog := ResourceCatalog.new()
var _item_catalog := ItemCatalog.new()
var _weapon_catalog := WeaponCatalog.new()
var _harvest_state := ResourceHarvestState.new()
var _tool_ids: Array[StringName] = []
var _crafting_system: CraftingSystem
var _grave_model := GraveModel.new()
var _grave_markers: Dictionary = {}
var _drop_pool: WorldDropPool
var _enemy_director: EnemyDirector
var _milestone_catalog := MilestoneCatalog.new()
var _milestone_state := MilestoneState.new()
var _ruin_encounter: RuinEncounter
var _pending_persistence: Dictionary = {}
var _view_mode := ChunkRenderer.ViewMode.TERRAIN
var _show_boundaries := true
var _completed_total := 0
var _unloaded_total := 0
var _peak_cache := 0
var _peak_memory_mb := 0.0
var _metrics_elapsed := 0.0
var _prompt_elapsed := 0.0
var _time_phase: StringName = &"DAWN"
var _weather_resource_multiplier := 1.0


func configure(world_seed: int, player: PlayerCharacter, initial_chunk: ChunkData = null) -> void:
	_world_seed = world_seed
	_player = player
	_current_chunk = WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(player.global_position))
	if initial_chunk != null:
		_cache[initial_chunk.chunk_position] = initial_chunk


func _ready() -> void:
	if _player == null:
		push_error("ChunkStreamManager requires a configured player before entering the scene tree.")
		set_process(false)
		return
	_tool_ids = _resource_catalog.tool_ids()
	EventBus.time_state_changed.connect(_on_time_state_changed)
	EventBus.weather_state_changed.connect(_on_weather_state_changed)
	_crafting_system = CraftingSystem.new(_harvest_state.inventory_model())
	_restore_pending_persistence()
	_drop_pool = WorldDropPool.new()
	_drop_pool.configure(_resource_catalog.drop_pool_capacity(), _resource_catalog)
	add_child(_drop_pool)
	_enemy_director = EnemyDirector.new()
	_enemy_director.configure(_world_seed, _player, _drop_pool)
	add_child(_enemy_director)
	var ruin_plan := RuinPlanner.new(_world_seed, _milestone_catalog).plan()
	if ruin_plan.is_empty():
		push_error("Unable to plan the canonical ruin: %s" % _milestone_catalog.error_message())
	else:
		_ruin_encounter = RuinEncounter.new()
		_ruin_encounter.configure(ruin_plan, _player, _milestone_state, _milestone_catalog)
		_ruin_encounter.milestone_changed.connect(func(_snapshot: Dictionary) -> void: _emit_metrics())
		add_child(_ruin_encounter)
	_refresh_grave_markers()
	_refresh_targets()
	_emit_metrics()
	_emit_tool_and_inventory()


func _process(delta: float) -> void:
	_collect_completed_jobs()
	_collect_nearby_drops()
	var next_chunk := WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(_player.global_position))
	var next_direction := _direction_from_velocity(_player.velocity)
	var targets_changed := next_chunk != _current_chunk
	if next_direction != Vector2i.ZERO and next_direction != _movement_direction:
		_movement_direction = next_direction
		targets_changed = true
	if next_chunk != _current_chunk:
		_current_chunk = next_chunk
	if targets_changed:
		_refresh_targets()
	_dispatch_jobs()
	_metrics_elapsed += delta
	if _metrics_elapsed >= 0.2:
		_metrics_elapsed = 0.0
		_emit_metrics()
	_prompt_elapsed += delta
	if _prompt_elapsed >= 0.10:
		_prompt_elapsed = 0.0
		_update_resource_prompt()


func _exit_tree() -> void:
	for coordinate in _task_ids.keys():
		var task_id: int = _task_ids[coordinate]
		var error := WorkerThreadPool.wait_for_task_completion(task_id)
		if error != OK:
			push_error("Unable to await chunk task %s during shutdown: %s" % [coordinate, error_string(error)])
	_task_ids.clear()
	_jobs.clear()


func toggle_noise_view() -> void:
	_view_mode = (_view_mode + 1) % (ChunkRenderer.ViewMode.ELEVATION + 1)
	_update_renderer_debug_options()
	_emit_metrics()


func toggle_chunk_boundaries() -> void:
	_show_boundaries = not _show_boundaries
	_update_renderer_debug_options()
	_emit_metrics()


func cycle_active_tool() -> void:
	var inventory := _harvest_state.inventory_model()
	var start := inventory.selected_hotbar_slot()
	for offset in range(1, inventory.hotbar_slot_count() + 1):
		var candidate := posmod(start + offset, inventory.hotbar_slot_count())
		var value := inventory.slot(candidate)
		if value.is_empty():
			continue
		var kind := _item_catalog.tool_kind(StringName(value["item_id"]))
		if kind.is_empty():
			continue
		inventory.select_hotbar(candidate)
		_emit_tool_and_inventory()
		EventBus.interaction_feedback.emit("已切换到%s" % active_tool_display_name(), true)
		_update_resource_prompt()
		return
	EventBus.interaction_feedback.emit("快捷栏中没有可以切换的工具", false)


func active_tool_id() -> StringName:
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	if value.is_empty():
		return &"hands"
	var kind := _item_catalog.tool_kind(StringName(value["item_id"]))
	return kind if not kind.is_empty() else &"hands"


func selected_item_id() -> StringName:
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	return StringName(value.get("item_id", "")) if not value.is_empty() else &""


func active_tool_power() -> int:
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	if value.is_empty():
		return 1
	var power := _item_catalog.tool_power(StringName(value["item_id"]))
	return power if power > 0 else 1


func active_tool_display_name() -> String:
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	if value.is_empty() or _item_catalog.tool_kind(StringName(value["item_id"])).is_empty():
		return _resource_catalog.tool_display_name(&"hands")
	return _item_catalog.display_name(StringName(value["item_id"]))


func active_weapon_id() -> StringName:
	var inventory := _harvest_state.inventory_model()
	var value := inventory.slot(inventory.selected_hotbar_slot())
	if value.is_empty():
		return &"unarmed"
	var item_id := StringName(value["item_id"])
	return item_id if _item_catalog.tool_kind(item_id) == &"sword" and _weapon_catalog.weapon(item_id) != null else &"unarmed"


func consume_selected_weapon_durability() -> Dictionary:
	var inventory := _harvest_state.inventory_model()
	var index := inventory.selected_hotbar_slot()
	var value := inventory.slot(index)
	if value.is_empty():
		return {"accepted": false, "broken": false}
	var item_id := StringName(value["item_id"])
	if _item_catalog.tool_kind(item_id) != &"sword":
		return {"accepted": false, "broken": false}
	var result := inventory.damage_tool_at(index, 1)
	_emit_tool_and_inventory()
	if bool(result.get("broken", false)):
		EventBus.combat_feedback.emit("%s已损坏" % _item_catalog.display_name(item_id), false)
	return result


func interact() -> void:
	if _ruin_encounter != null and _ruin_encounter.try_interact(_harvest_state.inventory_model()):
		_emit_tool_and_inventory()
		return
	if try_reclaim_nearest_grave():
		return
	interact_with_nearest_resource()


func create_death_grave(world_position: Vector2) -> Dictionary:
	var grave := _grave_model.deposit(world_position, _harvest_state.inventory_model())
	if grave.is_empty():
		EventBus.combat_feedback.emit("背包为空，没有生成墓碑", false)
		return {}
	_refresh_grave_markers()
	_emit_tool_and_inventory()
	EventBus.combat_feedback.emit("物品已保存在墓碑中", false)
	return grave


func try_reclaim_nearest_grave(radius := 68.0) -> bool:
	if _player == null:
		return false
	var grave := _grave_model.nearest_grave(_player.global_position, radius)
	if grave.is_empty():
		return false
	var result := _grave_model.reclaim(int(grave["id"]), _harvest_state.inventory_model())
	if not bool(result.get("ok", false)):
		EventBus.combat_feedback.emit(_grave_model.last_error, false)
		return true
	_refresh_grave_markers()
	_emit_tool_and_inventory()
	EventBus.combat_feedback.emit(
		"已取回墓碑中的 %d 件物品" % int(result["transferred"]) if bool(result["complete"]) else _grave_model.last_error,
		bool(result["complete"])
	)
	return true


func interact_with_nearest_resource() -> void:
	var target := nearest_resource(_resource_catalog.interaction_radius_pixels())
	if target.is_empty():
		EventBus.interaction_feedback.emit("附近没有可以采集的资源", false)
		return
	var resource_code := int(target["resource_code"])
	var resource_key := String(target["resource_key"])
	var result := _harvest_state.hit(resource_key, resource_code, active_tool_id(), _resource_catalog, active_tool_power())
	if not bool(result["accepted"]):
		if String(result.get("reason", "")) == "wrong_tool":
			var required_tool := StringName(result["required_tool"])
			EventBus.interaction_feedback.emit("需要%s才能采集%s" % [
				_resource_catalog.tool_display_name(required_tool),
				_resource_catalog.display_name_for_code(resource_code),
			], false)
		return
	var broken_tool := _consume_active_tool_durability()
	var renderer := _renderers.get(target["chunk_position"]) as ChunkRenderer
	var destroyed := bool(result["destroyed"])
	if renderer != null:
		renderer.play_resource_hit(resource_key, destroyed)
	if not destroyed:
		var progress_message := "采集中：%s  %d/%d" % [
			_resource_catalog.display_name_for_code(resource_code),
			int(result["remaining"]),
			int(result["maximum"]),
		]
		if not broken_tool.is_empty():
			progress_message += " · %s已损坏" % broken_tool
		EventBus.interaction_feedback.emit(progress_message, true)
		return
	var drop_position := target["world_position"] as Vector2
	var drop_index := 0
	for drop_value in result["drops"] as Array:
		var drop := drop_value as Dictionary
		var offset := Vector2((drop_index - 1) * 12, 5 + posmod(drop_index, 2) * 6)
		var weather_quantity := adjusted_resource_quantity(int(drop["quantity"]))
		if not _drop_pool.spawn_drop(drop["item_id"] as StringName, weather_quantity, drop_position + offset):
			LogManager.warning("ResourceInteraction", "Drop pool full; unable to spawn %s" % drop["item_id"])
		drop_index += 1
	var destroyed_message := "%s已采集，掉落物将自动拾取" % _resource_catalog.display_name_for_code(resource_code)
	if not broken_tool.is_empty():
		destroyed_message += " · %s已损坏" % broken_tool
	EventBus.interaction_feedback.emit(destroyed_message, true)
	_update_resource_prompt()
	_emit_metrics()


func nearest_resource(radius_pixels: float) -> Dictionary:
	if _player == null:
		return {}
	var best: Dictionary = {}
	var best_distance_squared := radius_pixels * radius_pixels
	for coordinate_value in _renderers.keys():
		var coordinate := coordinate_value as Vector2i
		var chunk := _cache.get(coordinate) as ChunkData
		if chunk == null:
			continue
		for index in chunk.resource_count():
			if not _resource_catalog.available_in_phase(chunk.resource_code_at(index), _time_phase):
				continue
			var resource_key := chunk.resource_key_at(index)
			if _harvest_state.collected_resources.has(resource_key):
				continue
			var world_position := WorldCoordinates.tile_to_world_pixel(chunk.resource_world_tile_at(index), true)
			var distance_squared := _player.global_position.distance_squared_to(world_position)
			if distance_squared > best_distance_squared:
				continue
			best_distance_squared = distance_squared
			best = {
				"chunk_position": coordinate,
				"resource_index": index,
				"resource_key": resource_key,
				"resource_code": chunk.resource_code_at(index),
				"world_position": world_position,
				"distance_squared": distance_squared,
			}
	return best


func _on_time_state_changed(snapshot: Dictionary) -> void:
	_time_phase = StringName(snapshot.get("phase", &"DAWN"))
	_update_resource_prompt()


func _on_weather_state_changed(snapshot: Dictionary) -> void:
	_weather_resource_multiplier = clampf(float(snapshot.get("resource_yield_multiplier", 1.0)), 0.25, 3.0)


func adjusted_resource_quantity(base_quantity: int) -> int:
	return maxi(1, roundi(float(base_quantity) * _weather_resource_multiplier))


func current_biome_id() -> StringName:
	var current_data := _cache.get(_current_chunk) as ChunkData
	if current_data == null or _player == null:
		return &"plains"
	var local := WorldCoordinates.tile_to_local(WorldCoordinates.world_pixel_to_tile(_player.global_position))
	return _catalog.id_for_code(current_data.biome_at(local))


func harvest_state() -> ResourceHarvestState:
	return _harvest_state


func enemy_director() -> EnemyDirector:
	return _enemy_director


func ruin_encounter() -> RuinEncounter:
	return _ruin_encounter


func milestone_state() -> MilestoneState:
	return _milestone_state


func restore_persistence(snapshot: Dictionary) -> void:
	_pending_persistence = snapshot.duplicate(true)
	if is_inside_tree() and not _tool_ids.is_empty():
		_restore_pending_persistence()
		_refresh_grave_markers()


func persistence_snapshot() -> Dictionary:
	var snapshot := _harvest_state.persistence_snapshot()
	snapshot["active_tool"] = String(active_tool_id())
	snapshot["crafting_state"] = _crafting_system.persistence_snapshot() if _crafting_system != null else {}
	snapshot["grave_state"] = _grave_model.persistence_snapshot()
	snapshot["milestone_state"] = _milestone_state.persistence_snapshot()
	return snapshot


func inventory_state_snapshot() -> Dictionary:
	return _harvest_state.inventory_state_snapshot()


func move_inventory_slot(from_index: int, to_index: int) -> bool:
	var changed := _harvest_state.move_inventory_slot(from_index, to_index)
	if changed:
		_emit_inventory_state()
	else:
		EventBus.interaction_feedback.emit(_harvest_state.inventory_model().last_error, false)
	return changed


func split_inventory_stack(from_index: int, to_index: int, quantity := -1) -> bool:
	var changed := _harvest_state.split_inventory_stack(from_index, to_index, quantity)
	if changed:
		_emit_inventory_state()
	else:
		EventBus.interaction_feedback.emit(_harvest_state.inventory_model().last_error, false)
	return changed


func discard_inventory_slot(index: int, quantity := -1) -> bool:
	var removed := _harvest_state.discard_inventory_slot(index, quantity)
	if removed.is_empty():
		EventBus.interaction_feedback.emit(_harvest_state.inventory_model().last_error, false)
		return false
	var item_id := StringName(removed["item_id"])
	var amount := int(removed["quantity"])
	var metadata := {}
	if removed.has("durability"):
		metadata["durability"] = int(removed["durability"])
	if _drop_pool == null or not _drop_pool.spawn_drop(item_id, amount, _player.global_position + Vector2(18, 10), metadata):
		_harvest_state.inventory_model().add_item(item_id, amount, int(removed.get("durability", -1)))
		EventBus.interaction_feedback.emit("地面掉落池已满，物品已退回背包", false)
		_emit_inventory_state()
		return false
	EventBus.interaction_feedback.emit("已丢弃%s ×%d" % [_resource_catalog.item_display_name(item_id), amount], true)
	_emit_inventory_state()
	return true


func sort_inventory() -> void:
	_harvest_state.sort_inventory()
	_emit_inventory_state()
	EventBus.interaction_feedback.emit("背包已按分类整理", true)


func select_hotbar_slot(index: int) -> bool:
	var changed := _harvest_state.select_hotbar_slot(index)
	if changed:
		_emit_tool_and_inventory()
		_update_resource_prompt()
	return changed


func crafting_views() -> Array[Dictionary]:
	return _crafting_system.recipe_views() if _crafting_system != null else []


func craft_recipe(recipe_id: StringName) -> Dictionary:
	if _crafting_system == null:
		return {"ok": false, "message": "制作系统尚未就绪"}
	var result := _crafting_system.craft(recipe_id)
	EventBus.interaction_feedback.emit(String(result["message"]), bool(result["ok"]))
	_emit_tool_and_inventory()
	return result


func metrics_snapshot() -> Dictionary:
	var preload_ready := 0
	var sleeping := 0
	for coordinate in _cache.keys():
		var distance := ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk)
		if distance > ChunkStreamPlanner.ACTIVE_RADIUS and distance <= ChunkStreamPlanner.PRELOAD_RADIUS:
			preload_ready += 1
		elif distance > ChunkStreamPlanner.PRELOAD_RADIUS:
			sleeping += 1
	var current_data := _cache.get(_current_chunk) as ChunkData
	var biome_name := "生成中"
	var temperature := 0.0
	var moisture := 0.0
	var elevation := 0.0
	var erosion := 0.0
	var active_resources := 0
	for renderer_value in _renderers.values():
		active_resources += (renderer_value as ChunkRenderer).visible_resource_count()
	if current_data != null:
		var player_tile := WorldCoordinates.world_pixel_to_tile(_player.global_position)
		var local := WorldCoordinates.tile_to_local(player_tile)
		biome_name = _catalog.display_name_for_code(current_data.biome_at(local))
		temperature = current_data.temperature_at(local)
		moisture = current_data.moisture_at(local)
		elevation = current_data.elevation_at(local)
		erosion = current_data.erosion_at(local)
	return {
		"current_chunk": _current_chunk,
		"current_checksum": current_data.checksum if current_data != null else "生成中",
		"active": _renderers.size(),
		"preload": preload_ready,
		"sleeping": sleeping,
		"cache": _cache.size(),
		"queued": _queue.size(),
		"generating": _task_ids.size(),
		"completed_total": _completed_total,
		"unloaded_total": _unloaded_total,
		"peak_cache": _peak_cache,
		"peak_memory_mb": _peak_memory_mb,
		"view_mode": ChunkRenderer.view_mode_name(_view_mode),
		"boundaries": _show_boundaries,
		"biome_name": biome_name,
		"temperature": temperature,
		"moisture": moisture,
		"elevation": elevation,
		"erosion": erosion,
		"active_resources": active_resources,
		"collected_resources": _harvest_state.collected_resources.size(),
		"active_drops": _drop_pool.active_count() if _drop_pool != null else 0,
		"active_enemies": _enemy_director.active_count() if _enemy_director != null else 0,
		"sleeping_enemies": _enemy_director.sleeping_count() if _enemy_director != null else 0,
		"ruin_discovered": _milestone_state.ruin_discovered,
		"boss_defeated": _milestone_state.boss_defeated,
		"reward_claimed": _milestone_state.reward_claimed,
		"drop_pool_capacity": _resource_catalog.drop_pool_capacity(),
		"active_tool": active_tool_id(),
	}


func cached_checksum(coordinate: Vector2i) -> String:
	var data := _cache.get(coordinate) as ChunkData
	return data.checksum if data != null else ""


func _refresh_targets() -> void:
	var active_targets := ChunkStreamPlanner.coordinates_in_radius(_current_chunk, ChunkStreamPlanner.ACTIVE_RADIUS)
	var active_set := _coordinate_set(active_targets)
	var preload_targets := ChunkStreamPlanner.coordinates_in_radius(_current_chunk, ChunkStreamPlanner.PRELOAD_RADIUS)
	_preload_targets = _coordinate_set(preload_targets)
	var filtered_queue: Array[Vector2i] = []
	for coordinate in _queue:
		if _preload_targets.has(coordinate):
			filtered_queue.append(coordinate)
	_queue = filtered_queue
	for coordinate in preload_targets:
		if not _cache.has(coordinate) and not _task_ids.has(coordinate) and not _queue.has(coordinate):
			_queue.append(coordinate)
	_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return ChunkStreamPlanner.priority_score(a, _current_chunk, _movement_direction) < ChunkStreamPlanner.priority_score(b, _current_chunk, _movement_direction)
	)
	for coordinate in _renderers.keys():
		if not active_set.has(coordinate):
			var renderer := _renderers[coordinate] as ChunkRenderer
			renderer.queue_free()
			_renderers.erase(coordinate)
	for coordinate in _cache.keys():
		if ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk) > ChunkStreamPlanner.CACHE_RADIUS:
			_cache.erase(coordinate)
			_unloaded_total += 1
	for coordinate in active_targets:
		_activate_cached_chunk(coordinate)
	_peak_cache = maxi(_peak_cache, _cache.size())


func _dispatch_jobs() -> void:
	while _task_ids.size() < MAX_CONCURRENT_JOBS and not _queue.is_empty():
		var coordinate: Vector2i = _queue.pop_front()
		if _cache.has(coordinate) or _task_ids.has(coordinate):
			continue
		var job := ChunkGenerationJob.new(_world_seed, coordinate)
		var high_priority := ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk) <= 1
		var task_id := WorkerThreadPool.add_task(job.execute, high_priority, "chunk_%d_%d" % [coordinate.x, coordinate.y])
		_jobs[coordinate] = job
		_task_ids[coordinate] = task_id


func _collect_completed_jobs() -> void:
	for coordinate in _task_ids.keys():
		var task_id: int = _task_ids[coordinate]
		if not WorkerThreadPool.is_task_completed(task_id):
			continue
		var error := WorkerThreadPool.wait_for_task_completion(task_id)
		var job := _jobs[coordinate] as ChunkGenerationJob
		_task_ids.erase(coordinate)
		_jobs.erase(coordinate)
		if error != OK:
			push_error("Chunk generation task failed for %s: %s" % [coordinate, error_string(error)])
			continue
		if job.result == null:
			push_error("Chunk generation task returned no data for %s" % coordinate)
			continue
		_completed_total += 1
		if ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk) <= ChunkStreamPlanner.CACHE_RADIUS:
			_cache[coordinate] = job.result
			_activate_cached_chunk(coordinate)
		else:
			_unloaded_total += 1
	_peak_cache = maxi(_peak_cache, _cache.size())


func _activate_cached_chunk(coordinate: Vector2i) -> void:
	if _renderers.has(coordinate) or not _cache.has(coordinate):
		return
	if ChunkStreamPlanner.chebyshev_distance(coordinate, _current_chunk) > ChunkStreamPlanner.ACTIVE_RADIUS:
		return
	var renderer := ChunkRenderer.new()
	add_child(renderer)
	renderer.set_collected_resources(_harvest_state.collected_resources)
	renderer.apply_chunk(_cache[coordinate] as ChunkData)
	renderer.set_debug_options(_view_mode, _show_boundaries)
	_renderers[coordinate] = renderer


func _update_renderer_debug_options() -> void:
	for renderer_value in _renderers.values():
		var renderer := renderer_value as ChunkRenderer
		renderer.set_debug_options(_view_mode, _show_boundaries)


func _emit_metrics() -> void:
	_peak_memory_mb = maxf(_peak_memory_mb, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	metrics_changed.emit(metrics_snapshot())


func _collect_nearby_drops() -> void:
	if _drop_pool == null or _player == null:
		return
	var transfer := _drop_pool.transfer_near(
		_player.global_position,
		_resource_catalog.pickup_radius_pixels(),
		func(item_id: StringName, quantity: int, metadata: Dictionary) -> int:
			var result := _harvest_state.inventory_model().add_item(item_id, quantity, int(metadata.get("durability", -1)))
			return int(result["accepted"])
	)
	var pickups := transfer["transferred"] as Array
	var blocked := transfer["blocked"] as Array
	if pickups.is_empty() and blocked.is_empty():
		return
	var messages: Array[String] = []
	for value in pickups:
		var pickup := value as Dictionary
		var item_id := pickup["item_id"] as StringName
		var quantity := int(pickup["quantity"])
		messages.append("%s ×%d" % [_resource_catalog.item_display_name(item_id), quantity])
	_emit_inventory_state()
	if not blocked.is_empty():
		EventBus.interaction_feedback.emit("背包已满，未拾取的物品仍留在地面", false)
	elif not messages.is_empty():
		EventBus.interaction_feedback.emit("拾取 " + "、".join(messages), true)


func _update_resource_prompt() -> void:
	if _ruin_encounter != null:
		var ruin_prompt := _ruin_encounter.prompt_text()
		if not ruin_prompt.is_empty():
			EventBus.resource_prompt_changed.emit(ruin_prompt)
			return
	var nearby_grave := _grave_model.nearest_grave(_player.global_position, 68.0) if _player != null else {}
	if not nearby_grave.is_empty():
		EventBus.resource_prompt_changed.emit("[E] 取回墓碑物品")
		return
	var target := nearest_resource(_resource_catalog.interaction_radius_pixels())
	if target.is_empty():
		EventBus.resource_prompt_changed.emit("")
		return
	var resource_code := int(target["resource_code"])
	var required_tool := _resource_catalog.required_tool_for_code(resource_code)
	var name := _resource_catalog.display_name_for_code(resource_code)
	if active_tool_id() != required_tool:
		EventBus.resource_prompt_changed.emit("[E] %s · 需要%s（当前%s）" % [
			name,
			_resource_catalog.tool_display_name(required_tool),
			active_tool_display_name(),
		])
	else:
		var remaining := _harvest_state.remaining_durability(String(target["resource_key"]), resource_code, _resource_catalog)
		EventBus.resource_prompt_changed.emit("[E] 采集%s · 耐久 %d" % [name, remaining])


func _emit_tool_and_inventory() -> void:
	var tool_id := active_tool_id()
	EventBus.active_tool_changed.emit(tool_id, active_tool_display_name())
	_emit_inventory_state()


func _emit_inventory_state() -> void:
	EventBus.inventory_changed.emit(_harvest_state.inventory_snapshot())
	EventBus.inventory_state_changed.emit(_harvest_state.inventory_state_snapshot())
	if _crafting_system != null:
		_crafting_system.refresh_discoveries()
		EventBus.crafting_state_changed.emit(_crafting_system.recipe_views())


func _restore_pending_persistence() -> void:
	if _pending_persistence.is_empty():
		return
	_harvest_state.restore_snapshot(
		_pending_persistence.get("collected_resources", []) as Array,
		_pending_persistence.get("inventory", {})
	)
	if _crafting_system != null and not _crafting_system.restore_snapshot(_pending_persistence.get("crafting_state", {}) as Dictionary):
		push_error("Unable to restore crafting state: %s" % _crafting_system.last_error)
	if not _grave_model.restore_snapshot(_pending_persistence.get("grave_state", {}) as Dictionary):
		push_error("Unable to restore grave state: %s" % _grave_model.last_error)
	if not _milestone_state.restore_snapshot(_pending_persistence.get("milestone_state", {}) as Dictionary):
		push_error("Unable to restore milestone state: %s" % _milestone_state.last_error)
	_pending_persistence.clear()


func _consume_active_tool_durability() -> String:
	var inventory := _harvest_state.inventory_model()
	var index := inventory.selected_hotbar_slot()
	var value := inventory.slot(index)
	if value.is_empty():
		return ""
	var item_id := StringName(value["item_id"])
	if not _item_catalog.is_durable(item_id):
		return ""
	var result := inventory.damage_tool_at(index, 1)
	_emit_tool_and_inventory()
	return _item_catalog.display_name(item_id) if bool(result.get("broken", false)) else ""


func _refresh_grave_markers() -> void:
	for marker_value in _grave_markers.values():
		(marker_value as GraveMarker).queue_free()
	_grave_markers.clear()
	for grave in _grave_model.graves():
		var position_value := grave["position"] as Array
		var marker := GraveMarker.new()
		marker.configure(int(grave["id"]), Vector2(float(position_value[0]), float(position_value[1])))
		add_child(marker)
		_grave_markers[int(grave["id"])] = marker
	_emit_grave_state()


func _emit_grave_state() -> void:
	EventBus.grave_state_changed.emit({"count": _grave_model.grave_count(), "graves": _grave_model.graves()})


func _coordinate_set(coordinates: Array[Vector2i]) -> Dictionary:
	var result := {}
	for coordinate in coordinates:
		result[coordinate] = true
	return result


func _direction_from_velocity(velocity: Vector2) -> Vector2i:
	if velocity.length_squared() < 1.0:
		return Vector2i.ZERO
	return Vector2i(roundi(signf(velocity.x)), roundi(signf(velocity.y)))
