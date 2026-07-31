extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SEED_TEXT := "无尽边境"
const CHUNK_POSITION := Vector2i(-1, -4)

var _world_seed := WorldSeed.from_text(SEED_TEXT)
var _generator := TerrainGenerator.new(_world_seed)
var _chunk: ChunkData
var _renderer: SingleChunkRenderer
var _player: PlayerCharacter
var _generation_hud: GenerationHud


func _ready() -> void:
	GameManager.current_state = GameManager.State.PLAYING
	GameManager.current_scene_path = GameManager.GAME_SCENE
	_build_world()
	LogManager.info("WorldSandbox", "V0.3.0 deterministic chunk ready: %s" % _chunk.checksum)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.return_to_menu()
	elif event.is_action_pressed("regenerate_world"):
		_regenerate()
	elif event.is_action_pressed("toggle_noise_view"):
		_renderer.toggle_noise_view()


func _build_world() -> void:
	_chunk = _generator.generate_chunk(CHUNK_POSITION)
	_renderer = SingleChunkRenderer.new()
	add_child(_renderer)
	_renderer.apply_chunk(_chunk)
	_add_chunk_boundaries(WorldCoordinates.chunk_pixel_rect(CHUNK_POSITION))
	_player = PLAYER_SCENE.instantiate() as PlayerCharacter
	var spawn_tile := _generator.find_land_near(_chunk)
	_player.position = WorldCoordinates.tile_to_world_pixel(spawn_tile, true)
	var camera := _player.get_node("Camera2D") as PixelCamera
	camera.configure_limits(WorldCoordinates.chunk_pixel_rect(CHUNK_POSITION))
	add_child(_player)
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	canvas.add_child(GameplayHud.new())
	_generation_hud = GenerationHud.new()
	canvas.add_child(_generation_hud)
	_generation_hud.configure(SEED_TEXT, _world_seed, CHUNK_POSITION, _chunk.checksum)
	_renderer.view_mode_changed.connect(_generation_hud.set_view_mode)
	if "--noise-view" in OS.get_cmdline_user_args():
		_renderer.toggle_noise_view()
	canvas.add_child(DebugPanel.new())


func _regenerate() -> void:
	var previous_checksum := _chunk.checksum
	_chunk = _generator.generate_chunk(CHUNK_POSITION)
	_renderer.apply_chunk(_chunk)
	_generation_hud.configure(SEED_TEXT, _world_seed, CHUNK_POSITION, _chunk.checksum)
	if _chunk.checksum != previous_checksum:
		push_error("Deterministic regeneration mismatch: %s != %s" % [_chunk.checksum, previous_checksum])
		return
	LogManager.info("WorldSandbox", "Chunk regenerated deterministically: %s" % _chunk.checksum)


func _add_chunk_boundaries(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var thickness := 32.0
	_add_boundary_shape(body, Vector2(rect.position.x - thickness * 0.5, rect.get_center().y), Vector2(thickness, rect.size.y + thickness * 2.0))
	_add_boundary_shape(body, Vector2(rect.end.x + thickness * 0.5, rect.get_center().y), Vector2(thickness, rect.size.y + thickness * 2.0))
	_add_boundary_shape(body, Vector2(rect.get_center().x, rect.position.y - thickness * 0.5), Vector2(rect.size.x, thickness))
	_add_boundary_shape(body, Vector2(rect.get_center().x, rect.end.y + thickness * 0.5), Vector2(rect.size.x, thickness))


func _add_boundary_shape(body: StaticBody2D, center: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	collision.position = center
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
