extends Node

enum State { BOOT, MENU, LOADING, PLAYING, PAUSED }

const MAIN_MENU_SCENE := "res://scenes/main/main.tscn"
const GAME_SCENE := "res://scenes/main/game.tscn"

var current_state: State = State.BOOT
var current_scene_path := ""


func _ready() -> void:
	EventBus.scene_change_requested.connect(change_scene)
	current_state = State.MENU
	current_scene_path = MAIN_MENU_SCENE


func change_scene(scene_path: String) -> void:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		LogManager.error("GameManager", "Cannot load scene: %s" % scene_path)
		EventBus.notify("场景加载失败", &"error")
		return
	current_state = State.LOADING
	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		LogManager.error("GameManager", "Scene change failed: %s" % error_string(result))
		current_state = State.MENU
		return
	current_scene_path = scene_path
	current_state = State.MENU if scene_path == MAIN_MENU_SCENE else State.PLAYING
	LogManager.info("GameManager", "Changed scene to %s" % scene_path)
	EventBus.scene_changed.emit(scene_path)


func start_new_game() -> void:
	change_scene(GAME_SCENE)


func return_to_menu() -> void:
	change_scene(MAIN_MENU_SCENE)


func quit_game() -> void:
	LogManager.info("GameManager", "Quit requested")
	get_tree().quit()
