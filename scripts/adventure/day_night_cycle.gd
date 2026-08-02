class_name DayNightCycle
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/time_cycle.json"

var total_seconds := 0.0
var _cycle_seconds := 1200.0
var _phases: Array[Dictionary] = []
var _valid := false
var _error_message := ""


func _init(initial_seconds := 0.0, config_path := DEFAULT_CONFIG_PATH) -> void:
	total_seconds = maxf(0.0, initial_seconds)
	_load_config(config_path)


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func cycle_seconds() -> float:
	return _cycle_seconds


func phase_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for phase in _phases:
		result.append(phase["id"] as StringName)
	return result


func advance(delta: float) -> Dictionary:
	total_seconds = maxf(0.0, total_seconds + maxf(delta, 0.0))
	return snapshot()


func snapshot() -> Dictionary:
	if not _valid:
		return {}
	var cycle_time := fposmod(total_seconds, _cycle_seconds)
	var phase_index := _phase_index_at(cycle_time)
	var phase := _phases[phase_index]
	var phase_start := float(phase["start_seconds"])
	var phase_progress := clampf((cycle_time - phase_start) / float(phase["duration_seconds"]), 0.0, 1.0)
	var next_phase := _phases[(phase_index + 1) % _phases.size()]
	var blend := smoothstep(0.72, 1.0, phase_progress)
	return {
		"total_seconds": total_seconds,
		"day": int(floor(total_seconds / _cycle_seconds)) + 1,
		"progress": cycle_time / _cycle_seconds,
		"phase_progress": phase_progress,
		"phase": phase["id"],
		"display_name": phase["display_name"],
		"overlay": (phase["overlay"] as Color).lerp(next_phase["overlay"] as Color, blend),
		"ambient_energy": lerpf(float(phase["ambient_energy"]), float(next_phase["ambient_energy"]), blend),
		"is_night": phase["id"] == &"NIGHT",
	}


func seconds_at_phase(phase_id: StringName) -> float:
	for phase in _phases:
		if phase["id"] == phase_id:
			return float(phase["start_seconds"])
	return -1.0


func _phase_index_at(cycle_time: float) -> int:
	for index in _phases.size():
		var phase := _phases[index]
		if cycle_time < float(phase["start_seconds"]) + float(phase["duration_seconds"]):
			return index
	return _phases.size() - 1


func _load_config(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open time-cycle configuration %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Time-cycle configuration is not a JSON object: %s" % path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported time-cycle schema version in %s" % path)
		return
	_cycle_seconds = float(root.get("cycle_seconds", 0.0))
	var elapsed := 0.0
	var seen := {}
	for value in root.get("phases", []) as Array:
		if not value is Dictionary:
			_fail("Time-cycle phase is not an object")
			return
		var source := value as Dictionary
		var phase_id := StringName(source.get("id", ""))
		var duration := float(source.get("duration_seconds", 0.0))
		if phase_id.is_empty() or seen.has(phase_id) or duration <= 0.0:
			_fail("Time-cycle phases require unique IDs and positive durations")
			return
		seen[phase_id] = true
		_phases.append({
			"id": phase_id,
			"display_name": String(source.get("display_name", phase_id)),
			"duration_seconds": duration,
			"start_seconds": elapsed,
			"overlay": Color(String(source.get("overlay", "00000000"))),
			"ambient_energy": clampf(float(source.get("ambient_energy", 1.0)), 0.0, 1.0),
		})
		elapsed += duration
	if _phases.size() != 4 or not seen.has(&"DAWN") or not seen.has(&"DAY") or not seen.has(&"DUSK") or not seen.has(&"NIGHT"):
		_fail("Time-cycle configuration must contain DAWN, DAY, DUSK and NIGHT")
		return
	if not is_equal_approx(elapsed, _cycle_seconds):
		_fail("Time-cycle phase durations must equal cycle_seconds")
		return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
