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
var _show_noise := false
var _show_boundaries := true
var _completed_total := 0
var _unloaded_total := 0
var _peak_cache := 0
var _peak_memory_mb := 0.0
var _metrics_elapsed := 0.0


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
	_refresh_targets()
	_emit_metrics()


func _process(delta: float) -> void:
	_collect_completed_jobs()
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


func _exit_tree() -> void:
	for coordinate in _task_ids.keys():
		var task_id: int = _task_ids[coordinate]
		var error := WorkerThreadPool.wait_for_task_completion(task_id)
		if error != OK:
			push_error("Unable to await chunk task %s during shutdown: %s" % [coordinate, error_string(error)])
	_task_ids.clear()
	_jobs.clear()


func toggle_noise_view() -> void:
	_show_noise = not _show_noise
	_update_renderer_debug_options()
	_emit_metrics()


func toggle_chunk_boundaries() -> void:
	_show_boundaries = not _show_boundaries
	_update_renderer_debug_options()
	_emit_metrics()


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
		"view_mode": "噪声" if _show_noise else "地形",
		"boundaries": _show_boundaries,
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
	renderer.apply_chunk(_cache[coordinate] as ChunkData)
	renderer.set_debug_options(_show_noise, _show_boundaries)
	_renderers[coordinate] = renderer


func _update_renderer_debug_options() -> void:
	for renderer_value in _renderers.values():
		var renderer := renderer_value as ChunkRenderer
		renderer.set_debug_options(_show_noise, _show_boundaries)


func _emit_metrics() -> void:
	_peak_memory_mb = maxf(_peak_memory_mb, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	metrics_changed.emit(metrics_snapshot())


func _coordinate_set(coordinates: Array[Vector2i]) -> Dictionary:
	var result := {}
	for coordinate in coordinates:
		result[coordinate] = true
	return result


func _direction_from_velocity(velocity: Vector2) -> Vector2i:
	if velocity.length_squared() < 1.0:
		return Vector2i.ZERO
	return Vector2i(roundi(signf(velocity.x)), roundi(signf(velocity.y)))
