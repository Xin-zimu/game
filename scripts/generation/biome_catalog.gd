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
var _deep_water_threshold := 0.0
var _shallow_water_threshold := 0.0
var _coast_threshold := 0.0
var _terrain_majority := 6
var _island_land_neighbors_max := 1
var _inlet_land_neighbors_min := 7
var _biome_majority := 5
var _surface_deep_water_code := 0
var _surface_shallow_water_code := 0
var _surface_coast_code := 0
var _biomes: Array[Dictionary] = []
var _ids_by_code: Array[StringName] = []
var _display_names_by_code: Array[String] = []
var _colors_by_code: Array[Color] = []
var _debug_colors_by_code: Array[Color] = []
var _land_rules: Array[BiomeRule] = []


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
	match name:
		"deep_water": return _deep_water_threshold
		"shallow_water": return _shallow_water_threshold
		"coast": return _coast_threshold
		_: return fallback


func cleanup_value(name: String, fallback := 0) -> int:
	match name:
		"terrain_majority": return _terrain_majority
		"island_land_neighbors_max": return _island_land_neighbors_max
		"inlet_land_neighbors_min": return _inlet_land_neighbors_min
		"biome_majority": return _biome_majority
		_: return fallback


func has_biome(biome_id: StringName) -> bool:
	return _ids_by_code.has(biome_id)


func code_for_id(biome_id: StringName) -> int:
	var code := _ids_by_code.find(biome_id)
	if code < 0:
		push_error("Unknown biome ID in %s: %s" % [_config_path, biome_id])
		return 0
	return code


func id_for_code(code: int) -> StringName:
	return _ids_by_code[code] if code >= 0 and code < _ids_by_code.size() else &"deep_ocean"


func display_name_for_code(code: int) -> String:
	return _display_names_by_code[code] if code >= 0 and code < _display_names_by_code.size() else "未知"


func color_for_code(code: int, debug := false) -> Color:
	var colors := _debug_colors_by_code if debug else _colors_by_code
	return colors[code] if code >= 0 and code < colors.size() else Color("ff00ff")


func code_for_surface(surface: StringName) -> int:
	match surface:
		&"deep_water": return _surface_deep_water_code
		&"shallow_water": return _surface_shallow_water_code
		&"coast": return _surface_coast_code
		_: return 0


func classify_land(temperature: float, moisture: float, elevation: float, erosion: float) -> int:
	for rule in _land_rules:
		if not rule.matches(temperature, moisture, elevation, erosion):
			continue
		if rule.transition_band > 0.0 and not rule.transition_id.is_empty() and rule.distance_to_edge(temperature, moisture, elevation, erosion) < rule.transition_band:
			return code_for_id(rule.transition_id)
		return rule.code
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
	var thresholds := root.get("terrain_thresholds", {}) as Dictionary
	_deep_water_threshold = float(thresholds.get("deep_water", 0.0))
	_shallow_water_threshold = float(thresholds.get("shallow_water", 0.0))
	_coast_threshold = float(thresholds.get("coast", 0.0))
	var cleanup := root.get("cleanup", {}) as Dictionary
	_terrain_majority = int(cleanup.get("terrain_majority", 6))
	_island_land_neighbors_max = int(cleanup.get("island_land_neighbors_max", 1))
	_inlet_land_neighbors_min = int(cleanup.get("inlet_land_neighbors_min", 7))
	_biome_majority = int(cleanup.get("biome_majority", 5))
	var surface_defaults := root.get("surface_defaults", {}) as Dictionary
	var biome_values := root.get("biomes", []) as Array
	for value in biome_values:
		if not value is Dictionary:
			_fail("Biome entry is not an object in %s" % _config_path)
			return
		var definition := (value as Dictionary).duplicate(true)
		var biome_id := String(definition.get("id", ""))
		var code := int(definition.get("code", -1))
		if biome_id.is_empty() or code < 0 or _ids_by_code.has(StringName(biome_id)):
			_fail("Biome IDs and codes must be unique and non-empty in %s" % _config_path)
			return
		while _ids_by_code.size() <= code:
			_ids_by_code.append(&"")
			_display_names_by_code.append("")
			_colors_by_code.append(Color("ff00ff"))
			_debug_colors_by_code.append(Color("ff00ff"))
		if not _ids_by_code[code].is_empty():
			_fail("Biome codes must be unique in %s" % _config_path)
			return
		_ids_by_code[code] = StringName(biome_id)
		_display_names_by_code[code] = String(definition.get("display_name", biome_id))
		_colors_by_code[code] = Color(String(definition.get("color", "ff00ff")))
		_debug_colors_by_code[code] = Color(String(definition.get("debug_color", "ff00ff")))
		_biomes.append(definition)
		if String(definition.get("surface", "")) == "land":
			var rule := BiomeRule.new()
			rule.configure(definition)
			_land_rules.append(rule)
	for required_id in REQUIRED_IDS:
		if not _ids_by_code.has(StringName(required_id)):
			_fail("Missing required biome '%s' in %s" % [required_id, _config_path])
			return
	for expected_code in _biomes.size():
		if expected_code >= _ids_by_code.size() or _ids_by_code[expected_code].is_empty():
			_fail("Biome codes must be contiguous from zero in %s" % _config_path)
			return
	if not _thresholds_are_ordered():
		_fail("Biome terrain thresholds must satisfy deep_water < shallow_water < coast")
		return
	_surface_deep_water_code = code_for_id(StringName(surface_defaults.get("deep_water", "deep_ocean")))
	_surface_shallow_water_code = code_for_id(StringName(surface_defaults.get("shallow_water", "ocean")))
	_surface_coast_code = code_for_id(StringName(surface_defaults.get("coast", "coast")))
	_land_rules.sort_custom(func(a: BiomeRule, b: BiomeRule) -> bool:
		return a.priority > b.priority
	)
	_valid = true


func _thresholds_are_ordered() -> bool:
	return threshold("deep_water") > 0.0 \
		and threshold("deep_water") < threshold("shallow_water") \
		and threshold("shallow_water") < threshold("coast") \
		and threshold("coast") < 1.0


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
