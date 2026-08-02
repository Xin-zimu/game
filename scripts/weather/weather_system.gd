class_name WeatherSystem
extends RefCounted

const SCHEMA_VERSION := 1

var _world_seed := 0
var _catalog: WeatherCatalog
var _current_id: StringName = &"CLEAR"
var _target_id: StringName = &"CLEAR"
var _region := Vector2i(2147483647, 2147483647)
var _segment := 0
var _weather_elapsed := 0.0
var _weather_duration := 120.0
var _transition_elapsed := 0.0


func _init(world_seed: int, restored := {}, catalog := WeatherCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	if restored is Dictionary and not (restored as Dictionary).is_empty():
		restore_snapshot(restored as Dictionary)


func update(delta: float, world_tile: Vector2i, biome_id: StringName) -> Dictionary:
	var chunk := WorldCoordinates.tile_to_chunk(world_tile)
	var next_region := Vector2i(
		floori(float(chunk.x) / float(_catalog.region_size_chunks())),
		floori(float(chunk.y) / float(_catalog.region_size_chunks()))
	)
	if _region.x == 2147483647:
		_region = next_region
		_current_id = _select_weather(biome_id)
		_target_id = _current_id
		_weather_duration = _select_duration()
	elif next_region != _region:
		_region = next_region
		_segment = 0
		_weather_elapsed = 0.0
		_set_target(_select_weather(biome_id))
		_weather_duration = _select_duration()
	_weather_elapsed += maxf(delta, 0.0)
	if _weather_elapsed >= _weather_duration:
		_weather_elapsed = fposmod(_weather_elapsed, _weather_duration)
		_segment += 1
		_set_target(_select_weather(biome_id))
		_weather_duration = _select_duration()
	if _current_id != _target_id:
		_transition_elapsed += maxf(delta, 0.0)
		if _transition_elapsed >= _catalog.transition_seconds():
			_current_id = _target_id
			_transition_elapsed = 0.0
	return snapshot()


func snapshot() -> Dictionary:
	var current := _catalog.definition(_current_id)
	var target := _catalog.definition(_target_id)
	if current == null or target == null:
		return {}
	var blend := smoothstep(0.0, 1.0, clampf(_transition_elapsed / _catalog.transition_seconds(), 0.0, 1.0)) if _current_id != _target_id else 1.0
	var visible := target if blend >= 0.5 else current
	return {
		"schema_version": SCHEMA_VERSION,
		"weather_id": visible.weather_id,
		"current_id": _current_id,
		"target_id": _target_id,
		"display_name": visible.display_name,
		"region": _region,
		"segment": _segment,
		"weather_elapsed": _weather_elapsed,
		"weather_duration": _weather_duration,
		"transition_elapsed": _transition_elapsed,
		"transition_progress": blend,
		"tint": current.tint.lerp(target.tint, blend),
		"particle_style": visible.particle_style,
		"particle_color": visible.particle_color,
		"particle_count": roundi(lerpf(float(current.particle_count), float(target.particle_count), blend)),
		"particle_speed": lerpf(current.particle_speed, target.particle_speed, blend),
		"ambient_frequency": lerpf(current.ambient_frequency, target.ambient_frequency, blend),
		"enemy_population_multiplier": lerpf(current.enemy_population_multiplier, target.enemy_population_multiplier, blend),
		"resource_yield_multiplier": lerpf(current.resource_yield_multiplier, target.resource_yield_multiplier, blend),
	}


func persistence_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"current_id": String(_current_id),
		"target_id": String(_target_id),
		"region": [_region.x, _region.y],
		"segment": _segment,
		"weather_elapsed": _weather_elapsed,
		"weather_duration": _weather_duration,
		"transition_elapsed": _transition_elapsed,
	}


func restore_snapshot(value: Dictionary) -> bool:
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION:
		return false
	var current := StringName(value.get("current_id", "CLEAR"))
	var target := StringName(value.get("target_id", current))
	var region_value := value.get("region", []) as Array
	if _catalog.definition(current) == null or _catalog.definition(target) == null or region_value.size() != 2:
		return false
	_current_id = current
	_target_id = target
	_region = Vector2i(int(region_value[0]), int(region_value[1]))
	_segment = maxi(0, int(value.get("segment", 0)))
	_weather_elapsed = maxf(0.0, float(value.get("weather_elapsed", 0.0)))
	_weather_duration = maxf(_catalog.minimum_duration(), float(value.get("weather_duration", _catalog.minimum_duration())))
	_transition_elapsed = clampf(float(value.get("transition_elapsed", 0.0)), 0.0, _catalog.transition_seconds())
	return true


func force_weather(weather_id: StringName) -> bool:
	if _catalog.definition(weather_id) == null:
		return false
	_current_id = weather_id
	_target_id = weather_id
	_transition_elapsed = 0.0
	return true


func transition_to(weather_id: StringName) -> bool:
	if _catalog.definition(weather_id) == null:
		return false
	_set_target(weather_id)
	return true


func _set_target(weather_id: StringName) -> void:
	if weather_id == _target_id:
		return
	_current_id = StringName(snapshot().get("weather_id", _current_id))
	_target_id = weather_id
	_transition_elapsed = 0.0


func _select_weather(biome_id: StringName) -> StringName:
	var stable := WorldSeed.from_text("%d|weather|%d|%d|%d|%s" % [_world_seed, _region.x, _region.y, _segment, biome_id])
	return _catalog.choose_for_biome(biome_id, float(stable & 0xffff) / 65536.0)


func _select_duration() -> float:
	var stable := WorldSeed.from_text("%d|weather-duration|%d|%d|%d" % [_world_seed, _region.x, _region.y, _segment])
	var roll := float(stable & 0xffff) / 65535.0
	return lerpf(_catalog.minimum_duration(), _catalog.maximum_duration(), roll)
