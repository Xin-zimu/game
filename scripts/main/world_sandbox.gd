extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SEED_TEXT := "无尽边境"
const START_CHUNK := Vector2i(-1, -4)

var _world_seed := WorldSeed.from_text(SEED_TEXT)
var _player: PlayerCharacter
var _stream_manager: ChunkStreamManager
var _generation_hud: GenerationHud


func _ready() -> void:
	GameManager.current_state = GameManager.State.PLAYING
	GameManager.current_scene_path = GameManager.GAME_SCENE
	_build_world()
	LogManager.info("WorldSandbox", "V0.5.0 layered terrain and biome stream ready")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.return_to_menu()
	elif event.is_action_pressed("toggle_noise_view"):
		_stream_manager.toggle_noise_view()
	elif event.is_action_pressed("toggle_chunk_borders"):
		_stream_manager.toggle_chunk_boundaries()


func _build_world() -> void:
	var initial_chunk := TerrainGenerator.new(_world_seed).generate_chunk(START_CHUNK)
	_player = PLAYER_SCENE.instantiate() as PlayerCharacter
	var spawn_tile := TerrainGenerator.new(_world_seed).find_land_near(initial_chunk)
	_player.position = WorldCoordinates.tile_to_world_pixel(spawn_tile, true)
	var camera := _player.get_node("Camera2D") as PixelCamera
	camera.configure_unbounded()
	add_child(_player)
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	canvas.add_child(GameplayHud.new())
	_generation_hud = GenerationHud.new()
	canvas.add_child(_generation_hud)
	_generation_hud.configure(SEED_TEXT, _world_seed, START_CHUNK, initial_chunk.checksum)
	canvas.add_child(DebugPanel.new())
	_stream_manager = ChunkStreamManager.new()
	_stream_manager.configure(_world_seed, _player, initial_chunk)
	_stream_manager.metrics_changed.connect(_generation_hud.update_streaming)
	add_child(_stream_manager)
	if "--noise-view" in OS.get_cmdline_user_args():
		_stream_manager.toggle_noise_view()
