class_name WeatherDefinition
extends RefCounted

var weather_id: StringName = &"CLEAR"
var display_name := "晴天"
var tint := Color.TRANSPARENT
var particle_style: StringName = &"none"
var particle_color := Color.TRANSPARENT
var particle_count := 0
var particle_speed := 0.0
var ambient_frequency := 0.0
var enemy_population_multiplier := 1.0
var resource_yield_multiplier := 1.0
var biome_ids: Array[StringName] = []
var biome_weights := PackedFloat32Array()


func configure(source: Dictionary, biome_catalog: BiomeCatalog) -> void:
	weather_id = StringName(source.get("id", "CLEAR"))
	display_name = String(source.get("display_name", weather_id))
	tint = Color(String(source.get("tint", "ffffff00")))
	particle_style = StringName(source.get("particle_style", "none"))
	particle_color = Color(String(source.get("particle_color", "ffffff00")))
	particle_count = int(source.get("particle_count", 0))
	particle_speed = float(source.get("particle_speed", 0.0))
	ambient_frequency = float(source.get("ambient_frequency", 0.0))
	enemy_population_multiplier = float(source.get("enemy_population_multiplier", 1.0))
	resource_yield_multiplier = float(source.get("resource_yield_multiplier", 1.0))
	var weights := source.get("biome_weights", {}) as Dictionary
	for biome_id_value in BiomeCatalog.REQUIRED_IDS:
		var biome_id := StringName(biome_id_value)
		var weight := float(weights.get(String(biome_id), 0.0))
		if weight > 0.0 and biome_catalog.has_biome(biome_id):
			biome_ids.append(biome_id)
			biome_weights.append(weight)


func weight_for_biome(biome_id: StringName) -> float:
	var index := biome_ids.find(biome_id)
	return biome_weights[index] if index >= 0 else 0.0
