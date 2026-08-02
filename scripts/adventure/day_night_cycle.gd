class_name DayNightCycle
extends RefCounted

const CYCLE_SECONDS := 300.0
const DAY_FRACTION := 0.68

var total_seconds := 0.0


func _init(initial_seconds := 0.0) -> void:
	total_seconds = maxf(0.0, initial_seconds)


func advance(delta: float) -> Dictionary:
	total_seconds = maxf(0.0, total_seconds + maxf(delta, 0.0))
	return snapshot()


func snapshot() -> Dictionary:
	var progress := fposmod(total_seconds, CYCLE_SECONDS) / CYCLE_SECONDS
	var is_day := progress < DAY_FRACTION
	return {
		"total_seconds": total_seconds,
		"day": int(floor(total_seconds / CYCLE_SECONDS)) + 1,
		"progress": progress,
		"phase": &"DAY" if is_day else &"NIGHT",
		"display_name": "白天" if is_day else "夜晚",
		"overlay": Color(0.02, 0.05, 0.12, 0.0 if is_day else 0.43),
	}
