extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const START_CHUNK := Vector2i(-1, -4)
const AUTOSAVE_INTERVAL := 30.0

var _seed_text := WorldSeed.DEFAULT_TEXT
var _world_seed := WorldSeed.from_text(WorldSeed.DEFAULT_TEXT)
var _player: PlayerCharacter
var _stream_manager: ChunkStreamManager
var _generation_hud: GenerationHud
var _inventory_panel: InventoryPanel
var _game_time_seconds := 0.0
var _autosave_elapsed := 0.0
var _exit_save_requested := false


func _ready() -> void:
	GameManager.current_state = GameManager.State.PLAYING
	GameManager.current_scene_path = GameManager.GAME_SCENE
	get_tree().auto_accept_quit = false
	if SaveManager.has_current_world():
		_seed_text = SaveManager.current_seed_text()
		_world_seed = SaveManager.current_seed()
		_game_time_seconds = SaveManager.current_game_time_seconds()
	_build_world()
	LogManager.info("WorldSandbox", "V0.8.0 inventory-enabled world ready: %s" % (SaveManager.current_world_name() if SaveManager.has_current_world() else "temporary"))


func _process(delta: float) -> void:
	_game_time_seconds += delta
	if not SaveManager.has_current_world():
		return
	_autosave_elapsed += delta
	if _autosave_elapsed >= AUTOSAVE_INTERVAL:
		_autosave_elapsed = 0.0
		_request_save(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _inventory_panel != null and _inventory_panel.is_inventory_open():
			_inventory_panel.set_inventory_open(false)
			return
		_request_save(true)
		_exit_save_requested = true
		GameManager.return_to_menu()
	elif event.is_action_pressed("toggle_noise_view"):
		_stream_manager.toggle_noise_view()
	elif event.is_action_pressed("toggle_chunk_borders"):
		_stream_manager.toggle_chunk_boundaries()
	elif event.is_action_pressed("interact"):
		_stream_manager.interact_with_nearest_resource()
	elif event.is_action_pressed("cycle_tool"):
		_stream_manager.cycle_active_tool()
	elif event.is_action_pressed("manual_save"):
		_request_save(true)
	elif event.is_action_pressed("toggle_inventory"):
		_inventory_panel.toggle_inventory()
	elif event.is_action_pressed("inventory_sort") and _inventory_panel.is_inventory_open():
		_stream_manager.sort_inventory()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).physical_keycode
		if key >= KEY_1 and key <= KEY_8:
			_stream_manager.select_hotbar_slot(int(key - KEY_1))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_save(true)
		SaveManager.flush_pending_save()
		get_tree().quit()


func _exit_tree() -> void:
	get_tree().auto_accept_quit = true
	if SaveManager.has_current_world() and not _exit_save_requested and _player != null and _stream_manager != null:
		_request_save(false)


func _build_world() -> void:
	var player_snapshot := SaveManager.loaded_player_snapshot() if SaveManager.has_current_world() else {}
	var start_chunk := START_CHUNK
	if player_snapshot.has("position") and (player_snapshot["position"] as Array).size() == 2:
		var saved_position := Vector2(float(player_snapshot["position"][0]), float(player_snapshot["position"][1]))
		start_chunk = WorldCoordinates.tile_to_chunk(WorldCoordinates.world_pixel_to_tile(saved_position))
	var initial_chunk := TerrainGenerator.new(_world_seed).generate_chunk(start_chunk)
	_player = PLAYER_SCENE.instantiate() as PlayerCharacter
	if player_snapshot.is_empty():
		var spawn_tile := TerrainGenerator.new(_world_seed).find_land_near(initial_chunk)
		_player.position = WorldCoordinates.tile_to_world_pixel(spawn_tile, true)
	else:
		_player.restore_snapshot(player_snapshot)
	var camera := _player.get_node("Camera2D") as PixelCamera
	camera.configure_unbounded()
	add_child(_player)
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	canvas.add_child(GameplayHud.new())
	canvas.add_child(ResourceHud.new())
	_generation_hud = GenerationHud.new()
	canvas.add_child(_generation_hud)
	_generation_hud.configure(_seed_text, _world_seed, start_chunk, initial_chunk.checksum)
	canvas.add_child(DebugPanel.new())
	_stream_manager = ChunkStreamManager.new()
	_stream_manager.configure(_world_seed, _player, initial_chunk)
	if SaveManager.has_current_world():
		_stream_manager.restore_persistence(SaveManager.loaded_world_state_snapshot())
	_stream_manager.metrics_changed.connect(_generation_hud.update_streaming)
	add_child(_stream_manager)
	_inventory_panel = InventoryPanel.new()
	canvas.add_child(_inventory_panel)
	_inventory_panel.configure(_stream_manager)
	if "--noise-view" in OS.get_cmdline_user_args():
		_stream_manager.toggle_noise_view()


func _request_save(create_backup: bool) -> void:
	if not SaveManager.has_current_world() or _player == null or _stream_manager == null:
		return
	SaveManager.request_save(
		_player.persistence_snapshot(),
		_stream_manager.persistence_snapshot(),
		_game_time_seconds,
		create_backup
	)
