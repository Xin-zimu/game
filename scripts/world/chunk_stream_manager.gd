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
var _harvest_state := ResourceHarvestState.new()
var _tool_ids: Array[StringName] = []
var _active_tool_index := 0
var _drop_pool: WorldDropPool
var _view_mode := ChunkRenderer.ViewMode.TERRAIN
var _show_boundaries := true
var _completed_total := 0
var _unloaded_total := 0
var _peak_cache := 0
var _peak_memory_mb := 0.0
var _metrics_elapsed := 0.0
var _prompt_elapsed := 0.0


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
	_drop_pool = WorldDropPool.new()
	_drop_pool.configure(_resource_catalog.drop_pool_capacity(), _resource_catalog)
	add_child(_drop_pool)
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
	if _tool_ids.is_empty():
		return
	_active_tool_index = (_active_tool_index + 1) % _tool_ids.size()
	var tool_id := active_tool_id()
	EventBus.active_tool_changed.emit(tool_id, _resource_catalog.tool_display_name(tool_id))
	EventBus.interaction_feedback.emit("已切换到%s" % _resource_catalog.tool_display_name(tool_id), true)
	_update_resource_prompt()


func active_tool_id() -> StringName:
	return _tool_ids[_active_tool_index] if not _tool_ids.is_empty() else &"hands"


func interact_with_nearest_resource() -> void:
	var target := nearest_resource(_resource_catalog.interaction_radius_pixels())
	if target.is_empty():
		EventBus.interaction_feedback.emit("附近没有可以采集的资源", false)
		return
	var resource_code := int(target["resource_code"])
	var resource_key := String(target["resource_key"])
	var result := _harvest_state.hit(resource_key, resource_code, active_tool_id(), _resource_catalog)
	if not bool(result["accepted"]):
		if String(result.get("reason", "")) == "wrong_tool":
			var required_tool := StringName(result["required_tool"])
			EventBus.interaction_feedback.emit("需要%s才能采集%s" % [
				_resource_catalog.tool_display_name(required_tool),
				_resource_catalog.display_name_for_code(resource_code),
			], false)
		return
	var renderer := _renderers.get(target["chunk_position"]) as ChunkRenderer
	var destroyed := bool(result["destroyed"])
	if renderer != null:
		renderer.play_resource_hit(resource_key, destroyed)
	if not destroyed:
		EventBus.interaction_feedback.emit("采集中：%s  %d/%d" % [
			_resource_catalog.display_name_for_code(resource_code),
			int(result["remaining"]),
			int(result["maximum"]),
		], true)
		return
	var drop_position := target["world_position"] as Vector2
	var drop_index := 0
	for drop_value in result["drops"] as Array:
		var drop := drop_value as Dictionary
		var offset := Vector2((drop_index - 1) * 12, 5 + posmod(drop_index, 2) * 6)
		if not _drop_pool.spawn_drop(drop["item_id"] as StringName, int(drop["quantity"]), drop_position + offset):
			LogManager.warning("ResourceInteraction", "Drop pool full; unable to spawn %s" % drop["item_id"])
		drop_index += 1
	EventBus.interaction_feedback.emit("%s已采集，掉落物将自动拾取" % _resource_catalog.display_name_for_code(resource_code), true)
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


func harvest_state() -> ResourceHarvestState:
	return _harvest_state


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
	var pickups := _drop_pool.collect_near(_player.global_position, _resource_catalog.pickup_radius_pixels())
	if pickups.is_empty():
		return
	var messages: Array[String] = []
	for value in pickups:
		var pickup := value as Dictionary
		var item_id := pickup["item_id"] as StringName
		var quantity := int(pickup["quantity"])
		_harvest_state.collect_item(item_id, quantity)
		messages.append("%s ×%d" % [_resource_catalog.item_display_name(item_id), quantity])
	EventBus.inventory_changed.emit(_harvest_state.inventory_snapshot())
	EventBus.interaction_feedback.emit("拾取 " + "、".join(messages), true)


func _update_resource_prompt() -> void:
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
			_resource_catalog.tool_display_name(active_tool_id()),
		])
	else:
		var remaining := _harvest_state.remaining_durability(String(target["resource_key"]), resource_code, _resource_catalog)
		EventBus.resource_prompt_changed.emit("[E] 采集%s · 耐久 %d" % [name, remaining])


func _emit_tool_and_inventory() -> void:
	var tool_id := active_tool_id()
	EventBus.active_tool_changed.emit(tool_id, _resource_catalog.tool_display_name(tool_id))
	EventBus.inventory_changed.emit(_harvest_state.inventory_snapshot())


func _coordinate_set(coordinates: Array[Vector2i]) -> Dictionary:
	var result := {}
	for coordinate in coordinates:
		result[coordinate] = true
	return result


func _direction_from_velocity(velocity: Vector2) -> Vector2i:
	if velocity.length_squared() < 1.0:
		return Vector2i.ZERO
	return Vector2i(roundi(signf(velocity.x)), roundi(signf(velocity.y)))
