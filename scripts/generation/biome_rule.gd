class_name BiomeRule
extends RefCounted

var code := 0
var priority := 0
var transition_band := 0.0
var transition_id: StringName = &""
var temperature_min := -INF
var temperature_max := INF
var moisture_min := -INF
var moisture_max := INF
var elevation_min := -INF
var elevation_max := INF
var erosion_min := -INF
var erosion_max := INF


func configure(definition: Dictionary) -> void:
	code = int(definition.get("code", 0))
	priority = int(definition.get("priority", 0))
	transition_band = float(definition.get("transition_band", 0.0))
	transition_id = StringName(definition.get("transition_to", ""))
	var conditions := definition.get("conditions", {}) as Dictionary
	temperature_min = float(conditions.get("temperature_min", -INF))
	temperature_max = float(conditions.get("temperature_max", INF))
	moisture_min = float(conditions.get("moisture_min", -INF))
	moisture_max = float(conditions.get("moisture_max", INF))
	elevation_min = float(conditions.get("elevation_min", -INF))
	elevation_max = float(conditions.get("elevation_max", INF))
	erosion_min = float(conditions.get("erosion_min", -INF))
	erosion_max = float(conditions.get("erosion_max", INF))


func matches(temperature: float, moisture: float, elevation: float, erosion: float) -> bool:
	return temperature >= temperature_min and temperature <= temperature_max \
		and moisture >= moisture_min and moisture <= moisture_max \
		and elevation >= elevation_min and elevation <= elevation_max \
		and erosion >= erosion_min and erosion <= erosion_max


func distance_to_edge(temperature: float, moisture: float, elevation: float, erosion: float) -> float:
	var distance := INF
	distance = minf(distance, minf(temperature - temperature_min, temperature_max - temperature))
	distance = minf(distance, minf(moisture - moisture_min, moisture_max - moisture))
	distance = minf(distance, minf(elevation - elevation_min, elevation_max - elevation))
	distance = minf(distance, minf(erosion - erosion_min, erosion_max - erosion))
	return distance
