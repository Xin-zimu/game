class_name BiomeCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/biomes.json"
const REQUIRED_IDS := [
	"deep_ocean",
	"ocean",
	"coast",
	"plains",
	"forest",
	"desert",
	"snowfield",
	"swamp",
	"mountain",
]

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _terrain_thresholds: Dictionary = {}
var _cleanup: Dictionary = {}
var _surface_defaults: Dictionary = {}
var _biomes: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _by_code: Dictionary = {}
var _land_rules: Array[Dictionary] = []


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func biome_count() -> int:
	return _biomes.size()


func threshold(name: String, fallback := 0.0) -> float:
	return float(_terrain_thresholds.get(name, fallback))


func cleanup_value(name: String, fallback := 0) -> int:
	return int(_cleanup.get(name, fallback))


func has_biome(biome_id: StringName) -> bool:
	return _by_id.has(String(biome_id))


func code_for_id(biome_id: StringName) -> int:
	var definition := _by_id.get(String(biome_id)) as Dictionary
	if definition.is_empty():
		push_error("Unknown biome ID in %s: %s" % [_config_path, biome_id])
		return 0
	return int(definition["code"])


func id_for_code(code: int) -> StringName:
	var definition := _by_code.get(code) as Dictionary
	return StringName(definition.get("id", "deep_ocean"))


func display_name_for_code(code: int) -> String:
	var definition := _by_code.get(code) as Dictionary
	return String(definition.get("display_name", "未知"))


func color_for_code(code: int, debug := false) -> Color:
	var definition := _by_code.get(code) as Dictionary
	var key := "debug_color" if debug else "color"
	return Color(String(definition.get(key, "ff00ff")))


func code_for_surface(surface: StringName) -> int:
	var biome_id := StringName(_surface_defaults.get(String(surface), "deep_ocean"))
	return code_for_id(biome_id)


func classify_land(temperature: float, moisture: float, elevation: float, erosion: float) -> int:
	var values := {
		"temperature": temperature,
		"moisture": moisture,
		"elevation": elevation,
		"erosion": erosion,
	}
	for rule in _land_rules:
		var conditions := rule.get("conditions", {}) as Dictionary
		if not _matches_conditions(values, conditions):
			continue
		var transition_band := float(rule.get("transition_band", 0.0))
		var transition_id := StringName(rule.get("transition_to", ""))
		if transition_band > 0.0 and not transition_id.is_empty() and _distance_to_condition_edge(values, conditions) < transition_band:
			return code_for_id(transition_id)
		return int(rule["code"])
	return code_for_id(&"plains")


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open biome configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Biome configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported biome schema version in %s" % _config_path)
		return
	_terrain_thresholds = root.get("terrain_thresholds", {}) as Dictionary
	_cleanup = root.get("cleanup", {}) as Dictionary
	_surface_defaults = root.get("surface_defaults", {}) as Dictionary
	var biome_values := root.get("biomes", []) as Array
	for value in biome_values:
		if not value is Dictionary:
			_fail("Biome entry is not an object in %s" % _config_path)
			return
		var definition := (value as Dictionary).duplicate(true)
		var biome_id := String(definition.get("id", ""))
		var code := int(definition.get("code", -1))
		if biome_id.is_empty() or code < 0 or _by_id.has(biome_id) or _by_code.has(code):
			_fail("Biome IDs and codes must be unique and non-empty in %s" % _config_path)
			return
		_by_id[biome_id] = definition
		_by_code[code] = definition
		_biomes.append(definition)
		if String(definition.get("surface", "")) == "land":
			_land_rules.append(definition)
	for required_id in REQUIRED_IDS:
		if not _by_id.has(required_id):
			_fail("Missing required biome '%s' in %s" % [required_id, _config_path])
			return
	for expected_code in _biomes.size():
		if not _by_code.has(expected_code):
			_fail("Biome codes must be contiguous from zero in %s" % _config_path)
			return
	if not _thresholds_are_ordered():
		_fail("Biome terrain thresholds must satisfy deep_water < shallow_water < coast")
		return
	_land_rules.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)
	_valid = true


func _matches_conditions(values: Dictionary, conditions: Dictionary) -> bool:
	for dimension in ["temperature", "moisture", "elevation", "erosion"]:
		var value: float = values[dimension]
		var minimum_key := "%s_min" % dimension
		var maximum_key := "%s_max" % dimension
		if conditions.has(minimum_key) and value < conditions[minimum_key]:
			return false
		if conditions.has(maximum_key) and value > conditions[maximum_key]:
			return false
	return true


func _distance_to_condition_edge(values: Dictionary, conditions: Dictionary) -> float:
	var distance := INF
	for dimension in ["temperature", "moisture", "elevation", "erosion"]:
		var value: float = values[dimension]
		var minimum_key := "%s_min" % dimension
		var maximum_key := "%s_max" % dimension
		if conditions.has(minimum_key):
			distance = minf(distance, value - conditions[minimum_key])
		if conditions.has(maximum_key):
			distance = minf(distance, conditions[maximum_key] - value)
	return distance


func _thresholds_are_ordered() -> bool:
	return threshold("deep_water") > 0.0 \
		and threshold("deep_water") < threshold("shallow_water") \
		and threshold("shallow_water") < threshold("coast") \
		and threshold("coast") < 1.0


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
