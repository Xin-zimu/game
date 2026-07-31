class_name PlayerMotor
extends RefCounted

const WALK_SPEED := 150.0
const RUN_SPEED := 245.0
const ROLL_SPEED := 360.0


static func normalized_input(raw_input: Vector2) -> Vector2:
	return raw_input.limit_length(1.0)


static func velocity_for(raw_input: Vector2, running: bool) -> Vector2:
	var speed := RUN_SPEED if running else WALK_SPEED
	return normalized_input(raw_input) * speed


static func integrated_distance(raw_input: Vector2, running: bool, fps: int, seconds: float) -> Vector2:
	var delta := 1.0 / float(fps)
	var steps := int(round(seconds * fps))
	var position := Vector2.ZERO
	for _step in steps:
		position += velocity_for(raw_input, running) * delta
	return position
