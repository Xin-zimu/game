class_name WeaponCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/weapons.json"
const REQUIRED_WEAPON_IDS := [&"unarmed", &"wood_sword", &"stone_sword"]

var _valid := false
var _error_message := ""
var _definitions: Array[WeaponDefinition] = []
var _by_id: Dictionary = {}
var _by_item_id: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH, item_catalog: ItemCatalog = null) -> void:
	_load_config(config_path, item_catalog if item_catalog != null else ItemCatalog.new())


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func weapon_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _definitions:
		result.append(definition.weapon_id)
	return result


func weapon(weapon_id: StringName) -> WeaponDefinition:
	return _by_id.get(String(weapon_id)) as WeaponDefinition


func weapon_for_item(item_id: StringName) -> WeaponDefinition:
	return _by_item_id.get(String(item_id), weapon(&"unarmed")) as WeaponDefinition


func _load_config(path: String, item_catalog: ItemCatalog) -> void:
	if not item_catalog.is_valid():
		_fail("Item catalog is invalid: %s" % item_catalog.error_message())
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open weapon configuration %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int((parsed as Dictionary).get("schema_version", 0)) != 1:
		_fail("Weapon configuration must use schema version 1: %s" % path)
		return
	for value in (parsed as Dictionary).get("weapons", []) as Array:
		if not value is Dictionary:
			_fail("Weapon entry is not an object")
			return
		var definition := WeaponDefinition.new()
		definition.configure(value as Dictionary)
		var key := String(definition.weapon_id)
		if key.is_empty() or _by_id.has(key):
			_fail("Weapon IDs must be unique and non-empty")
			return
		if definition.damage <= 0.0 or definition.attack_speed <= 0.0 or definition.attack_range <= 0.0 \
				or definition.hitbox_width <= 0.0 or definition.active_duration <= 0.0 \
				or definition.knockback < 0.0 or definition.stamina_cost < 0.0 or definition.combo_count() < 1:
			_fail("Weapon '%s' contains an invalid combat value" % key)
			return
		for multiplier in definition.combo_multipliers:
			if multiplier <= 0.0:
				_fail("Weapon '%s' contains an invalid combo multiplier" % key)
				return
		if definition.item_id.is_empty():
			if definition.weapon_id != &"unarmed":
				_fail("Only the unarmed weapon may omit item_id")
				return
		elif not item_catalog.has_item(definition.item_id) or item_catalog.tool_kind(definition.item_id) != &"sword":
			_fail("Weapon '%s' must reference a sword item" % key)
			return
		_definitions.append(definition)
		_by_id[key] = definition
		if not definition.item_id.is_empty():
			_by_item_id[String(definition.item_id)] = definition
	for required_id in REQUIRED_WEAPON_IDS:
		if not _by_id.has(String(required_id)):
			_fail("Weapon catalog is missing required ID '%s'" % required_id)
			return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
