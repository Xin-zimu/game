extends Node

## Central signal hub. Systems communicate through typed signals instead of
## reaching into each other's scene trees.

signal scene_change_requested(scene_path: String)
signal scene_changed(scene_path: String)
signal settings_changed(key: StringName, value: Variant)
signal notification_requested(message: String, severity: StringName)
signal debug_visibility_changed(visible: bool)


func request_scene(scene_path: String) -> void:
	scene_change_requested.emit(scene_path)


func notify(message: String, severity: StringName = &"info") -> void:
	notification_requested.emit(message, severity)
