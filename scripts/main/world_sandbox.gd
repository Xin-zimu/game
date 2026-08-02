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
var _crafting_panel: CraftingPanel
var _combat_controller: PlayerCombatController
var _game_time_seconds := 0.0
var _autosave_elapsed := 0.0
var _exit_save_requested := false
var _day_night_cycle: DayNightCycle
var _day_night_overlay: DayNightOverlay
var _weather_system: WeatherSystem
var _weather_overlay: WeatherOverlay


func _ready() -> void:
	GameManager.current_state = GameManager.State.PLAYING
	GameManager.current_scene_path = GameManager.GAME_SCENE
	get_tree().auto_accept_quit = false
	if SaveManager.has_current_world():
		_seed_text = SaveManager.current_seed_text()
		_world_seed = SaveManager.current_seed()
		_game_time_seconds = SaveManager.current_game_time_seconds()
	_build_world()
	LogManager.info("WorldSandbox", "V%s complete survival loop ready: %s" % [GameVersion.VERSION, SaveManager.current_world_name() if SaveManager.has_current_world() else "temporary"])


func _process(delta: float) -> void:
	_game_time_seconds += delta
	if _day_night_cycle != null:
		var time_state := _day_night_cycle.advance(delta)
		_day_night_overlay.apply_time(time_state)
		if _stream_manager != null:
			_day_night_overlay.set_torch_enabled(_stream_manager.selected_item_id() == &"torch")
		EventBus.time_state_changed.emit(time_state)
	if _weather_system != null and _weather_overlay != null and _player != null and _stream_manager != null:
		var weather_state := _weather_system.update(
			delta,
			WorldCoordinates.world_pixel_to_tile(_player.global_position),
			_stream_manager.current_biome_id()
		)
		_weather_overlay.apply_weather(weather_state)
		EventBus.weather_state_changed.emit(weather_state)
	if not SaveManager.has_current_world():
		return
	_autosave_elapsed += delta
	if _autosave_elapsed >= AUTOSAVE_INTERVAL:
		_autosave_elapsed = 0.0
		_request_save(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _crafting_panel != null and _crafting_panel.is_crafting_open():
			_crafting_panel.set_crafting_open(false)
			return
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
		_stream_manager.interact()
	elif event.is_action_pressed("cycle_tool"):
		_stream_manager.cycle_active_tool()
	elif event.is_action_pressed("attack") and not _inventory_panel.is_inventory_open() and not _crafting_panel.is_crafting_open():
		_combat_controller.request_attack()
	elif event.is_action_pressed("manual_save"):
		_request_save(true)
	elif event.is_action_pressed("toggle_inventory"):
		_crafting_panel.set_crafting_open(false)
		_inventory_panel.toggle_inventory()
	elif event.is_action_pressed("toggle_crafting"):
		_inventory_panel.set_inventory_open(false)
		_crafting_panel.toggle_crafting()
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
	if _player.combat_state().respawn_position.is_zero_approx():
		_player.combat_state().respawn_position = _player.position
	var camera := _player.get_node("Camera2D") as PixelCamera
	camera.configure_unbounded()
	add_child(_player)
	_player.died.connect(_on_player_died)
	_day_night_cycle = DayNightCycle.new(_game_time_seconds)
	var lighting_canvas := CanvasLayer.new()
	lighting_canvas.name = "DayNightCanvas"
	lighting_canvas.layer = 10
	add_child(lighting_canvas)
	_day_night_overlay = DayNightOverlay.new()
	lighting_canvas.add_child(_day_night_overlay)
	_day_night_overlay.configure_player(_player)
	_day_night_overlay.apply_time(_day_night_cycle.snapshot())
	_weather_overlay = WeatherOverlay.new()
	lighting_canvas.add_child(_weather_overlay)
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	canvas.add_child(GameplayHud.new())
	canvas.add_child(CombatHud.new())
	canvas.add_child(EnemyHud.new())
	canvas.add_child(MilestoneHud.new())
	canvas.add_child(ResourceHud.new())
	_generation_hud = GenerationHud.new()
	canvas.add_child(_generation_hud)
	_generation_hud.configure(_seed_text, _world_seed, start_chunk, initial_chunk.checksum)
	canvas.add_child(DebugPanel.new())
	_stream_manager = ChunkStreamManager.new()
	_stream_manager.configure(_world_seed, _player, initial_chunk)
	_weather_system = WeatherSystem.new(_world_seed, SaveManager.current_weather_state() if SaveManager.has_current_world() else {})
	if SaveManager.has_current_world():
		_stream_manager.restore_persistence(SaveManager.loaded_world_state_snapshot())
	_stream_manager.metrics_changed.connect(_generation_hud.update_streaming)
	add_child(_stream_manager)
	add_child(AudioCuePlayer.new())
	_combat_controller = PlayerCombatController.new()
	_combat_controller.configure(_player, _stream_manager)
	_player.add_child(_combat_controller)
	_inventory_panel = InventoryPanel.new()
	canvas.add_child(_inventory_panel)
	_inventory_panel.configure(_stream_manager)
	_crafting_panel = CraftingPanel.new()
	canvas.add_child(_crafting_panel)
	_crafting_panel.configure(_stream_manager)
	if "--noise-view" in OS.get_cmdline_user_args():
		_stream_manager.toggle_noise_view()
	if _player.combat_state().status == &"dead" or _player.health <= 0.0:
		_player.respawn_at(_player.combat_state().respawn_position)


func _request_save(create_backup: bool) -> void:
	if not SaveManager.has_current_world() or _player == null or _stream_manager == null:
		return
	SaveManager.request_save(
		_player.persistence_snapshot(),
		_stream_manager.persistence_snapshot(),
		_game_time_seconds,
		create_backup,
		_weather_system.persistence_snapshot() if _weather_system != null else {}
	)


func _on_player_died(death_position: Vector2) -> void:
	_stream_manager.create_death_grave(death_position)
	_player.respawn_at(_player.combat_state().respawn_position)
	_request_save(false)
