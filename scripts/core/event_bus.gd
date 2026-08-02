extends Node

## Central signal hub. Systems communicate through typed signals instead of
## reaching into each other's scene trees.

signal scene_change_requested(scene_path: String)
signal scene_changed(scene_path: String)
signal settings_changed(key: StringName, value: Variant)
signal notification_requested(message: String, severity: StringName)
signal debug_visibility_changed(visible: bool)
signal player_health_changed(current: float, maximum: float)
signal player_stamina_changed(current: float, maximum: float)
signal player_state_changed(state_name: StringName)
signal resource_prompt_changed(text: String)
signal active_tool_changed(tool_id: StringName, display_name: String)
signal inventory_changed(inventory: Dictionary)
signal inventory_state_changed(inventory_state: Dictionary)
signal crafting_state_changed(recipe_views: Array)
signal interaction_feedback(message: String, successful: bool)
signal attack_started(attack: Dictionary)
signal combat_status_changed(status: Dictionary)
signal combat_feedback(message: String, successful: bool)
signal grave_state_changed(state: Dictionary)
signal enemy_state_changed(state: Dictionary)
signal save_status_changed(message: String, successful: bool)


func request_scene(scene_path: String) -> void:
	scene_change_requested.emit(scene_path)


func notify(message: String, severity: StringName = &"info") -> void:
	notification_requested.emit(message, severity)
