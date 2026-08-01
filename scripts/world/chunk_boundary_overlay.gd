class_name ChunkBoundaryOverlay
extends Line2D

const CHUNK_PIXEL_SIZE := WorldCoordinates.CHUNK_SIZE * WorldCoordinates.TILE_SIZE


func _ready() -> void:
	z_as_relative = false
	z_index = -10
	width = 4.0
	default_color = Color("f6d66de6")
	antialiased = false
	closed = true
	points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(CHUNK_PIXEL_SIZE, 0),
		Vector2(CHUNK_PIXEL_SIZE, CHUNK_PIXEL_SIZE),
		Vector2(0, CHUNK_PIXEL_SIZE),
	])
