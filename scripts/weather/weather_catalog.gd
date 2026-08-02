class_name WeatherCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/weather.json"
const REQUIRED_IDS := [&"CLEAR", &"RAIN", &"SNOW", &"SANDSTORM"]
const VALID_PARTICLE_STYLES := [&"none", &"rain", &"snow", &"sand"]

var _valid := false
var _error_message := ""
var _region_size_chunks := 6
var _transition_seconds := 8.0
var _minimum_duration := 90.0
var _maximum_duration := 180.0
var _definitions: Array[WeatherDefinition] = []


func _init(path := DEFAULT_CONFIG_PATH) -> void:
	_load(path)


func is_valid() -> bool: return _valid
func error_message() -> String: return _error_message
func region_size_chunks() -> int: return _region_size_chunks
func transition_seconds() -> float: return _transition_seconds
func minimum_duration() -> float: return _minimum_duration
func maximum_duration() -> float: return _maximum_duration
func definitions() -> Array[WeatherDefinition]: return _definitions.duplicate()


func definition(weather_id: StringName) -> WeatherDefinition:
	for candidate in _definitions:
		if candidate.weather_id == weather_id:
			return candidate
	return null


func choose_for_biome(biome_id: StringName, roll: float) -> StringName:
	var total := 0.0
	for candidate in _definitions:
		total += candidate.weight_for_biome(biome_id)
	if total <= 0.0:
		return &"CLEAR"
	var cursor := clampf(roll, 0.0, 0.999999) * total
	for candidate in _definitions:
		cursor -= candidate.weight_for_biome(biome_id)
		if cursor < 0.0:
			return candidate.weather_id
	return &"CLEAR"


func _load(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open weather configuration: %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Weather configuration is not a JSON object")
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported weather schema version")
		return
	_region_size_chunks = int(root.get("region_size_chunks", 0))
	_transition_seconds = float(root.get("transition_seconds", 0.0))
	_minimum_duration = float(root.get("minimum_duration_seconds", 0.0))
	_maximum_duration = float(root.get("maximum_duration_seconds", 0.0))
	if _region_size_chunks < 1 or _transition_seconds <= 0.0 or _minimum_duration <= 0.0 or _maximum_duration < _minimum_duration:
		_fail("Weather region, transition or duration values are invalid")
		return
	var biome_catalog := BiomeCatalog.new()
	for value in root.get("weather", []) as Array:
		if not value is Dictionary:
			_fail("Weather entry is not an object")
			return
		var created_definition := WeatherDefinition.new()
		created_definition.configure(value as Dictionary, biome_catalog)
		if created_definition.weather_id.is_empty() or definition(created_definition.weather_id) != null \
				or not VALID_PARTICLE_STYLES.has(created_definition.particle_style) \
				or created_definition.enemy_population_multiplier <= 0.0 or created_definition.resource_yield_multiplier <= 0.0:
			_fail("Weather definition is invalid: %s" % created_definition.weather_id)
			return
		_definitions.append(created_definition)
	for required_id in REQUIRED_IDS:
		if definition(required_id) == null:
			_fail("Missing required weather: %s" % required_id)
			return
	if definition(&"SNOW").weight_for_biome(&"desert") > 0.0 or definition(&"SANDSTORM").weight_for_biome(&"snowfield") > 0.0:
		_fail("Weather biome rules are ecologically invalid")
		return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
