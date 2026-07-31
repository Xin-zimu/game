extends Node

const LOG_DIRECTORY := "user://logs"
const LOG_FILE := "user://logs/infinite_frontier.log"
const MAX_LOG_BYTES := 2 * 1024 * 1024

var _file: FileAccess


func _ready() -> void:
	_prepare_log_file()
	info("LogManager", "Session started - version %s" % GameVersion.VERSION)


func _exit_tree() -> void:
	info("LogManager", "Session ended")
	_file = null


func debug(source: String, message: String) -> void:
	_write("DEBUG", source, message)


func info(source: String, message: String) -> void:
	_write("INFO", source, message)


func warning(source: String, message: String) -> void:
	_write("WARN", source, message)


func error(source: String, message: String) -> void:
	_write("ERROR", source, message)
	push_error("[%s] %s" % [source, message])


func get_log_path() -> String:
	return ProjectSettings.globalize_path(LOG_FILE)


func _prepare_log_file() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOG_DIRECTORY))
	if FileAccess.file_exists(LOG_FILE) and FileAccess.get_file_as_bytes(LOG_FILE).size() > MAX_LOG_BYTES:
		var backup_path := "%s.1" % LOG_FILE
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(LOG_FILE),
			ProjectSettings.globalize_path(backup_path)
		)
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(LOG_FILE) else FileAccess.WRITE_READ
	_file = FileAccess.open(LOG_FILE, mode)
	if _file == null:
		push_error("Unable to open log file: %s" % FileAccess.get_open_error())
		return
	_file.seek_end()


func _write(level: String, source: String, message: String) -> void:
	var timestamp := Time.get_datetime_string_from_system(false, true)
	var line := "%s | %-5s | %-18s | %s" % [timestamp, level, source, message]
	print(line)
	if _file != null:
		_file.store_line(line)
		_file.flush()
