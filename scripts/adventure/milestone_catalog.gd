class_name MilestoneCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/milestones.json"

var _valid := false
var _error_message := ""
var _data: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		_fail("无法读取里程碑配置")
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		_fail("里程碑配置不是有效对象")
		return
	_data = (parser.data as Dictionary).duplicate(true)
	if int(_data.get("schema_version", 0)) != 1:
		_fail("里程碑配置版本无效")
		return
	for section in ["ruin", "boss", "reward"]:
		if not _data.get(section, null) is Dictionary:
			_fail("里程碑配置缺少 %s" % section)
			return
	var ruin := _data["ruin"] as Dictionary
	if int(ruin.get("search_minimum_chunk_radius", 0)) < 1 \
			or int(ruin.get("search_maximum_chunk_radius", 0)) < int(ruin.get("search_minimum_chunk_radius", 0)):
		_fail("遗迹搜索半径无效")
		return
	var boss := _data["boss"] as Dictionary
	for key in ["maximum_health", "move_speed", "detection_range", "attack_range", "attack_power", "attack_cooldown"]:
		if float(boss.get(key, 0.0)) <= 0.0:
			_fail("Boss 数值 %s 必须为正数" % key)
			return
	var reward := _data["reward"] as Dictionary
	var items := ItemCatalog.new()
	if not items.has_item(StringName(reward.get("item_id", ""))) or int(reward.get("quantity", 0)) <= 0:
		_fail("里程碑奖励物品无效")
		return
	_valid = true


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func ruin_value(key: String, fallback: Variant = null) -> Variant:
	return (_data.get("ruin", {}) as Dictionary).get(key, fallback)


func boss_value(key: String, fallback: Variant = null) -> Variant:
	return (_data.get("boss", {}) as Dictionary).get(key, fallback)


func reward_item_id() -> StringName:
	return StringName((_data.get("reward", {}) as Dictionary).get("item_id", ""))


func reward_quantity() -> int:
	return int((_data.get("reward", {}) as Dictionary).get("quantity", 0))


func _fail(message: String) -> void:
	_error_message = message
	_valid = false
