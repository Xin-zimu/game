extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULTS := {
	"video/fullscreen": false,
	"video/vsync": true,
	"video/ui_scale": 1.0,
	"audio/master_volume": 0.8,
	"audio/music_volume": 0.7,
	"audio/sfx_volume": 0.8,
	"accessibility/reduce_motion": false,
	"accessibility/show_fps": true,
}

var _values: Dictionary = {}


func _ready() -> void:
	load_settings()
	apply_settings()


func get_value(key: String, fallback: Variant = null) -> Variant:
	return _values.get(key, DEFAULTS.get(key, fallback))


func set_value(key: String, value: Variant, save_immediately: bool = true) -> void:
	_values[key] = value
	_apply_value(key, value)
	EventBus.settings_changed.emit(StringName(key), value)
	if save_immediately:
		save_settings()


func reset_to_defaults() -> void:
	_values = DEFAULTS.duplicate(true)
	apply_settings()
	save_settings()


func load_settings() -> bool:
	_values = DEFAULTS.duplicate(true)
	var config := ConfigFile.new()
	var result := config.load(SETTINGS_PATH)
	if result == ERR_FILE_NOT_FOUND:
		save_settings()
		return true
	if result != OK:
		LogManager.warning("SettingsManager", "Settings file could not be loaded: %s" % error_string(result))
		return false
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			_values["%s/%s" % [section, key]] = config.get_value(section, key)
	return true


func save_settings() -> bool:
	var config := ConfigFile.new()
	for composite_key in _values:
		var parts: PackedStringArray = String(composite_key).split("/", true, 1)
		if parts.size() == 2:
			config.set_value(parts[0], parts[1], _values[composite_key])
	var result := config.save(SETTINGS_PATH)
	if result != OK:
		LogManager.error("SettingsManager", "Settings file could not be saved: %s" % error_string(result))
		return false
	return true


func apply_settings() -> void:
	for key in _values:
		_apply_value(key, _values[key])


func _apply_value(key: String, value: Variant) -> void:
	match key:
		"video/fullscreen":
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if bool(value) else DisplayServer.WINDOW_MODE_WINDOWED
			)
		"video/vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if bool(value) else DisplayServer.VSYNC_DISABLED
			)
		"audio/master_volume":
			_set_bus_volume("Master", float(value))


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(linear_value, 0.0001, 1.0)))
