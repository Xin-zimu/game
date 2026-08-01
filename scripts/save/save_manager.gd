extends Node

const SAVE_ROOT := "user://saves"
const DEFAULT_START_CHUNK := Vector2i(-1, -4)

var last_error := ""
var last_save_duration_ms := 0.0

var _current_world_id := ""
var _metadata: Dictionary = {}
var _player_snapshot: Dictionary = {}
var _world_state_snapshot: Dictionary = {}
var _save_job: SaveWriteJob
var _save_task_id := -1
var _queued_request: Dictionary = {}


func _ready() -> void:
	var root_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
	if root_error != OK:
		last_error = "无法创建存档目录：%s" % error_string(root_error)
		LogManager.error("SaveManager", last_error)


func _process(_delta: float) -> void:
	if _save_task_id >= 0 and WorkerThreadPool.is_task_completed(_save_task_id):
		_collect_completed_save()


func _exit_tree() -> void:
	flush_pending_save()


func create_world(world_name: String, seed_text: String) -> bool:
	flush_pending_save()
	last_error = ""
	var clean_name := world_name.strip_edges()
	var clean_seed := seed_text.strip_edges()
	if clean_name.is_empty() or clean_name.length() > 32:
		return _fail("世界名称必须为 1–32 个字符")
	if clean_seed.is_empty():
		clean_seed = clean_name
	var seed := WorldSeed.from_text(clean_seed)
	var unique_source := "%s|%s|%d|%d" % [clean_name, clean_seed, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	var world_id := "world_%d" % WorldSeed.from_text(unique_source)
	var root_path := _world_root_absolute(world_id)
	var error := DirAccess.make_dir_recursive_absolute(root_path.path_join("chunks/surface"))
	if error != OK:
		return _fail("无法创建世界目录：%s" % error_string(error))
	error = DirAccess.make_dir_recursive_absolute(root_path.path_join("backups"))
	if error != OK:
		return _fail("无法创建备份目录：%s" % error_string(error))
	var generator := TerrainGenerator.new(seed)
	var initial_chunk := generator.generate_chunk(DEFAULT_START_CHUNK)
	var spawn_tile := generator.find_land_near(initial_chunk)
	var spawn_position := WorldCoordinates.tile_to_world_pixel(spawn_tile, true)
	var timestamp := Time.get_datetime_string_from_system(false, true)
	_metadata = {
		"save_version": GameVersion.SAVE_VERSION,
		"generation_version": GameVersion.GENERATION_VERSION,
		"game_version": GameVersion.VERSION,
		"world_id": world_id,
		"world_name": clean_name,
		"seed_text": clean_seed,
		"seed": seed,
		"created_at": timestamp,
		"last_played_at": timestamp,
		"game_time_seconds": 0.0,
		"player_layer": "surface",
	}
	_player_snapshot = {
		"save_version": GameVersion.SAVE_VERSION,
		"position": [spawn_position.x, spawn_position.y],
		"health": 100.0,
		"maximum_health": 100.0,
		"stamina": 100.0,
		"maximum_stamina": 100.0,
		"active_tool": "hands",
		"inventory": InventoryModel.new().snapshot(),
	}
	_world_state_snapshot = {"collected_resources": [], "inventory": _player_snapshot["inventory"], "active_tool": "hands"}
	var world_result := _write_initial_json(root_path.path_join("world.json"), _metadata)
	if not world_result:
		return false
	if not _write_initial_json(root_path.path_join("player.json"), _player_snapshot):
		return false
	_current_world_id = world_id
	LogManager.info("SaveManager", "Created world %s (%s)" % [clean_name, world_id])
	return true


func has_any_world() -> bool:
	var directory := DirAccess.open(ProjectSettings.globalize_path(SAVE_ROOT))
	if directory == null:
		return false
	for dirname in directory.get_directories():
		if FileAccess.file_exists(ProjectSettings.globalize_path(SAVE_ROOT.path_join(dirname).path_join("world.json"))):
			return true
	return false


func load_most_recent_world() -> bool:
	last_error = ""
	var directory := DirAccess.open(ProjectSettings.globalize_path(SAVE_ROOT))
	if directory == null:
		return _fail("存档目录不可读")
	var candidates: Array[Dictionary] = []
	var corrupt_errors: Array[String] = []
	for dirname in directory.get_directories():
		var read_result := _read_json(_world_root_absolute(dirname).path_join("world.json"))
		if not bool(read_result["ok"]):
			corrupt_errors.append("%s：%s" % [dirname, read_result["error"]])
			continue
		var metadata := read_result["data"] as Dictionary
		var validation_error := _validate_metadata(metadata)
		if not validation_error.is_empty():
			corrupt_errors.append("%s：%s" % [dirname, validation_error])
			continue
		candidates.append({"id": dirname, "last_played_at": String(metadata.get("last_played_at", ""))})
	if candidates.is_empty():
		if not corrupt_errors.is_empty():
			return _fail("存档损坏或不兼容：" + "；".join(corrupt_errors))
		return _fail("没有可以继续的世界")
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["last_played_at"]) > String(b["last_played_at"])
	)
	return load_world(String(candidates[0]["id"]))


func load_world(world_id: String) -> bool:
	flush_pending_save()
	last_error = ""
	var root_path := _world_root_absolute(world_id)
	var world_result := _read_json(root_path.path_join("world.json"))
	if not bool(world_result["ok"]):
		return _fail("存档损坏：%s" % world_result["error"])
	var metadata := world_result["data"] as Dictionary
	var metadata_error := _validate_metadata(metadata)
	if not metadata_error.is_empty():
		return _fail("存档损坏或不兼容：%s" % metadata_error)
	var player_result := _read_json(root_path.path_join("player.json"))
	if not bool(player_result["ok"]):
		return _fail("玩家存档损坏：%s" % player_result["error"])
	var player := player_result["data"] as Dictionary
	var player_error := _validate_player(player)
	if not player_error.is_empty():
		return _fail("玩家存档损坏：%s" % player_error)
	var loaded_save_version := int(metadata.get("save_version", 0))
	if loaded_save_version == 2:
		var migrated_inventory := InventoryModel.new()
		if not migrated_inventory.restore_legacy_counts(player.get("inventory", {}) as Dictionary):
			return _fail("玩家存档迁移失败：%s" % migrated_inventory.last_error)
		player["inventory"] = migrated_inventory.snapshot()
		player["save_version"] = GameVersion.SAVE_VERSION
		metadata["save_version"] = GameVersion.SAVE_VERSION
		metadata["game_version"] = GameVersion.VERSION
		LogManager.info("SaveManager", "Migrated world %s from save format 2 to 3" % world_id)
	else:
		var normalized_inventory := InventoryModel.new()
		normalized_inventory.restore_snapshot(player["inventory"] as Dictionary)
		player["inventory"] = normalized_inventory.snapshot()
	var difference_result := _load_chunk_differences(root_path.path_join("chunks/surface"))
	if not bool(difference_result["ok"]):
		return _fail("区块差异损坏：%s" % difference_result["error"])
	_current_world_id = world_id
	_metadata = metadata
	_player_snapshot = player
	_world_state_snapshot = {
		"collected_resources": difference_result["collected_resources"],
		"inventory": player.get("inventory", {}),
		"active_tool": String(player.get("active_tool", "hands")),
	}
	LogManager.info("SaveManager", "Loaded world %s (%s)" % [_metadata["world_name"], world_id])
	return true


func request_save(player: Dictionary, world_state: Dictionary, game_time_seconds: float, create_backup := false) -> bool:
	if _current_world_id.is_empty():
		return false
	var request := {
		"player": player.duplicate(true),
		"world_state": world_state.duplicate(true),
		"game_time_seconds": game_time_seconds,
		"create_backup": create_backup,
	}
	if _save_task_id >= 0:
		_queued_request = request
		return true
	_start_save(request)
	return true


func flush_pending_save() -> void:
	if _save_task_id < 0:
		return
	var error := WorkerThreadPool.wait_for_task_completion(_save_task_id)
	if error != OK:
		last_error = "等待存档线程失败：%s" % error_string(error)
		LogManager.error("SaveManager", last_error)
		_save_task_id = -1
		_save_job = null
		return
	_collect_completed_save(true)
	if _save_task_id >= 0:
		flush_pending_save()


func has_current_world() -> bool:
	return not _current_world_id.is_empty()


func current_world_id() -> String:
	return _current_world_id


func current_world_name() -> String:
	return String(_metadata.get("world_name", "临时世界"))


func current_seed_text() -> String:
	return String(_metadata.get("seed_text", WorldSeed.DEFAULT_TEXT))


func current_seed() -> int:
	return int(_metadata.get("seed", WorldSeed.from_text(WorldSeed.DEFAULT_TEXT)))


func current_game_time_seconds() -> float:
	return float(_metadata.get("game_time_seconds", 0.0))


func loaded_player_snapshot() -> Dictionary:
	return _player_snapshot.duplicate(true)


func loaded_world_state_snapshot() -> Dictionary:
	return _world_state_snapshot.duplicate(true)


func current_world_root_absolute() -> String:
	return _world_root_absolute(_current_world_id) if not _current_world_id.is_empty() else ""


func clear_current_world() -> void:
	flush_pending_save()
	_current_world_id = ""
	_metadata.clear()
	_player_snapshot.clear()
	_world_state_snapshot.clear()
	last_error = ""


func _start_save(request: Dictionary) -> void:
	var player := request["player"] as Dictionary
	var world_state := request["world_state"] as Dictionary
	player["save_version"] = GameVersion.SAVE_VERSION
	player["active_tool"] = String(world_state.get("active_tool", "hands"))
	player["inventory"] = (world_state.get("inventory", {}) as Dictionary).duplicate(true)
	_metadata["last_played_at"] = Time.get_datetime_string_from_system(false, true)
	_metadata["game_time_seconds"] = float(request["game_time_seconds"])
	_metadata["game_version"] = GameVersion.VERSION
	var chunk_differences := _group_chunk_differences(world_state.get("collected_resources", []) as Array)
	var snapshot := {
		"root_path": current_world_root_absolute(),
		"world": _metadata.duplicate(true),
		"player": player,
		"chunk_differences": chunk_differences,
		"create_backup": bool(request["create_backup"]),
	}
	_player_snapshot = player.duplicate(true)
	_world_state_snapshot = world_state.duplicate(true)
	_save_job = SaveWriteJob.new(snapshot)
	_save_task_id = WorkerThreadPool.add_task(_save_job.execute, true, "save_%s" % _current_world_id)
	EventBus.save_status_changed.emit("正在%s保存…" % ("手动" if bool(request["create_backup"]) else "自动"), true)


func _collect_completed_save(already_waited := false) -> void:
	if _save_task_id < 0 or _save_job == null:
		return
	if not already_waited:
		var error := WorkerThreadPool.wait_for_task_completion(_save_task_id)
		if error != OK:
			last_error = "存档线程失败：%s" % error_string(error)
			LogManager.error("SaveManager", last_error)
			EventBus.save_status_changed.emit(last_error, false)
			_save_task_id = -1
			_save_job = null
			return
	var completed_result := _save_job.result.duplicate(true)
	_save_task_id = -1
	_save_job = null
	last_save_duration_ms = float(completed_result.get("duration_usec", 0)) / 1000.0
	if bool(completed_result.get("ok", false)):
		last_error = ""
		var differences := int(completed_result.get("written_difference_files", 0))
		LogManager.info("SaveManager", "Saved world in %.2f ms (%d difference files)" % [last_save_duration_ms, differences])
		EventBus.save_status_changed.emit("保存完成 · %.1f ms · %d 个差异文件" % [last_save_duration_ms, differences], true)
	else:
		last_error = String(completed_result.get("error", "未知存档错误"))
		LogManager.error("SaveManager", last_error)
		EventBus.save_status_changed.emit("保存失败：%s" % last_error, false)
	if not _queued_request.is_empty():
		var next_request := _queued_request
		_queued_request = {}
		_start_save(next_request)


func _group_chunk_differences(collected_values: Array) -> Dictionary:
	var grouped := {}
	for value in collected_values:
		var resource_key := String(value)
		var parts := resource_key.split(":")
		if parts.size() != 3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
			continue
		var world_tile := Vector2i(int(parts[0]), int(parts[1]))
		var chunk := WorldCoordinates.tile_to_chunk(world_tile)
		var chunk_key := "%d_%d" % [chunk.x, chunk.y]
		if not grouped.has(chunk_key):
			grouped[chunk_key] = {
				"save_version": GameVersion.SAVE_VERSION,
				"generation_version": GameVersion.GENERATION_VERSION,
				"layer": "surface",
				"chunk": [chunk.x, chunk.y],
				"removed_resources": [],
			}
		(grouped[chunk_key]["removed_resources"] as Array).append(resource_key)
	for chunk_key in grouped:
		(grouped[chunk_key]["removed_resources"] as Array).sort()
	return grouped


func _load_chunk_differences(chunks_path: String) -> Dictionary:
	var collected: Array[String] = []
	var directory := DirAccess.open(chunks_path)
	if directory == null:
		return {"ok": true, "error": "", "collected_resources": collected}
	for filename in directory.get_files():
		if not filename.ends_with(".json"):
			continue
		var read_result := _read_json(chunks_path.path_join(filename))
		if not bool(read_result["ok"]):
			return {"ok": false, "error": "%s：%s" % [filename, read_result["error"]], "collected_resources": []}
		var difference := read_result["data"] as Dictionary
		if not [2, GameVersion.SAVE_VERSION].has(int(difference.get("save_version", 0))) \
				or int(difference.get("generation_version", 0)) != GameVersion.GENERATION_VERSION \
				or String(difference.get("layer", "")) != "surface":
			return {"ok": false, "error": "%s 的版本或世界层无效" % filename, "collected_resources": []}
		var removed: Variant = difference.get("removed_resources", [])
		if not removed is Array:
			return {"ok": false, "error": "%s 的资源差异不是数组" % filename, "collected_resources": []}
		for value in removed as Array:
			var key := String(value)
			if key.split(":").size() != 3:
				return {"ok": false, "error": "%s 包含无效资源键" % filename, "collected_resources": []}
			if not collected.has(key):
				collected.append(key)
	collected.sort()
	return {"ok": true, "error": "", "collected_resources": collected}


func _validate_metadata(metadata: Dictionary) -> String:
	if not [2, GameVersion.SAVE_VERSION].has(int(metadata.get("save_version", 0))):
		return "存档版本 %s 不受 V%s 支持" % [metadata.get("save_version", "缺失"), GameVersion.VERSION]
	if int(metadata.get("generation_version", 0)) != GameVersion.GENERATION_VERSION:
		return "生成版本 %s 与当前版本 %d 不兼容" % [metadata.get("generation_version", "缺失"), GameVersion.GENERATION_VERSION]
	for key in ["world_id", "world_name", "seed_text", "seed", "created_at", "last_played_at"]:
		if not metadata.has(key) or str(metadata[key]).is_empty():
			return "世界元数据缺少 %s" % key
	return ""


func _validate_player(player: Dictionary) -> String:
	var player_save_version := int(player.get("save_version", 0))
	if not [2, GameVersion.SAVE_VERSION].has(player_save_version):
		return "玩家存档版本无效"
	var position_value: Variant = player.get("position", [])
	if not position_value is Array or (position_value as Array).size() != 2:
		return "玩家位置必须包含两个坐标"
	for key in ["health", "maximum_health", "stamina", "maximum_stamina"]:
		if not player.has(key):
			return "玩家属性缺少 %s" % key
	var inventory_value: Variant = player.get("inventory", {})
	if not inventory_value is Dictionary:
		return "背包数据必须是对象"
	if player_save_version == GameVersion.SAVE_VERSION:
		var inventory := InventoryModel.new()
		if not inventory.restore_snapshot(inventory_value as Dictionary):
			return inventory.last_error
	return ""


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "无法读取 %s（%s）" % [path.get_file(), error_string(FileAccess.get_open_error())], "data": {}}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		return {"ok": false, "error": "%s 第 %d 行：%s" % [path.get_file(), parser.get_error_line(), parser.get_error_message()], "data": {}}
	if not parser.data is Dictionary:
		return {"ok": false, "error": "%s 根节点不是对象" % path.get_file(), "data": {}}
	return {"ok": true, "error": "", "data": parser.data}


func _write_initial_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _fail("无法写入初始存档：%s" % error_string(FileAccess.get_open_error()))
	file.store_string(JSON.stringify(data, "\t", true, true) + "\n")
	file.flush()
	return true


func _world_root_absolute(world_id: String) -> String:
	return ProjectSettings.globalize_path(SAVE_ROOT.path_join(world_id))


func _fail(message: String) -> bool:
	last_error = message
	LogManager.warning("SaveManager", message)
	return false
