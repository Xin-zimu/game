class_name ResourceCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/resources.json"
const REQUIRED_RESOURCE_IDS := ["tree", "rock", "grass", "flower", "berry_bush"]
const REQUIRED_TOOL_IDS := ["hands", "axe", "pickaxe"]

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _root: Dictionary = {}
var _resources: Array[Dictionary] = []
var _resources_by_id: Dictionary = {}
var _resources_by_code: Dictionary = {}
var _tools: Array[Dictionary] = []
var _tools_by_id: Dictionary = {}
var _items_by_id: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func resource_count() -> int:
	return _resources.size()


func candidate_cell_size() -> int:
	return int(_root.get("candidate_cell_size", 2))


func max_resources_per_chunk() -> int:
	return int(_root.get("max_resources_per_chunk", 128))


func drop_pool_capacity() -> int:
	return int(_root.get("drop_pool_capacity", 32))


func interaction_radius_pixels() -> float:
	return float(_root.get("interaction_radius_pixels", 64.0))


func pickup_radius_pixels() -> float:
	return float(_root.get("pickup_radius_pixels", 34.0))


func has_resource(resource_id: StringName) -> bool:
	return _resources_by_id.has(String(resource_id))


func code_for_id(resource_id: StringName) -> int:
	var definition := definition_for_id(resource_id)
	if definition.is_empty():
		push_error("Unknown resource ID in %s: %s" % [_config_path, resource_id])
		return 0
	return int(definition["code"])


func id_for_code(code: int) -> StringName:
	return StringName(definition_for_code(code).get("id", "tree"))


func definition_for_id(resource_id: StringName) -> Dictionary:
	return _resources_by_id.get(String(resource_id), {}) as Dictionary


func definition_for_code(code: int) -> Dictionary:
	return _resources_by_code.get(code, {}) as Dictionary


func display_name_for_code(code: int) -> String:
	return String(definition_for_code(code).get("display_name", "未知资源"))


func color_for_code(code: int) -> Color:
	return Color(String(definition_for_code(code).get("color", "ff00ff")))


func durability_for_code(code: int) -> int:
	return int(definition_for_code(code).get("durability", 1))


func minimum_distance_for_code(code: int) -> int:
	return int(definition_for_code(code).get("minimum_distance_tiles", 2))


func maximum_minimum_distance() -> int:
	var result := 1
	for definition in _resources:
		result = maxi(result, int(definition.get("minimum_distance_tiles", 1)))
	return result


func required_tool_for_code(code: int) -> StringName:
	return StringName(definition_for_code(code).get("required_tool", "hands"))


func is_solid(code: int) -> bool:
	return bool(definition_for_code(code).get("solid", false))


func drops_for_code(code: int) -> Array:
	return definition_for_code(code).get("drops", []) as Array


func tool_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _tools:
		result.append(StringName(definition["id"]))
	return result


func tool_display_name(tool_id: StringName) -> String:
	var definition := _tools_by_id.get(String(tool_id), {}) as Dictionary
	return String(definition.get("display_name", "未知工具"))


func tool_power(tool_id: StringName) -> int:
	var definition := _tools_by_id.get(String(tool_id), {}) as Dictionary
	return int(definition.get("power", 0))


func item_display_name(item_id: StringName) -> String:
	var definition := _items_by_id.get(String(item_id), {}) as Dictionary
	return String(definition.get("display_name", item_id))


func item_color(item_id: StringName) -> Color:
	var definition := _items_by_id.get(String(item_id), {}) as Dictionary
	return Color(String(definition.get("color", "ffffff")))


func candidate_code_for_biome(biome_id: StringName, roll: float) -> int:
	var cursor := 0.0
	for definition in _resources:
		var weights := definition.get("biome_weights", {}) as Dictionary
		cursor += float(weights.get(String(biome_id), 0.0))
		if roll < cursor:
			return int(definition["code"])
	return -1


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open resource configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Resource configuration is not a JSON object: %s" % _config_path)
		return
	_root = parsed as Dictionary
	if int(_root.get("schema_version", 0)) != 1:
		_fail("Unsupported resource schema version in %s" % _config_path)
		return
	if candidate_cell_size() < 2 or max_resources_per_chunk() < 1 or drop_pool_capacity() < 1:
		_fail("Resource generation and pool limits must be positive in %s" % _config_path)
		return
	for value in _root.get("tools", []) as Array:
		if not value is Dictionary:
			_fail("Tool entry is not an object in %s" % _config_path)
			return
		var definition := (value as Dictionary).duplicate(true)
		var tool_id := String(definition.get("id", ""))
		if tool_id.is_empty() or _tools_by_id.has(tool_id) or int(definition.get("power", 0)) < 1:
			_fail("Tool IDs must be unique and tool power must be positive in %s" % _config_path)
			return
		_tools.append(definition)
		_tools_by_id[tool_id] = definition
	for value in _root.get("items", []) as Array:
		if not value is Dictionary:
			_fail("Item entry is not an object in %s" % _config_path)
			return
		var definition := (value as Dictionary).duplicate(true)
		var item_id := String(definition.get("id", ""))
		if item_id.is_empty() or _items_by_id.has(item_id):
			_fail("Item IDs must be unique and non-empty in %s" % _config_path)
			return
		_items_by_id[item_id] = definition
	for value in _root.get("resources", []) as Array:
		if not value is Dictionary:
			_fail("Resource entry is not an object in %s" % _config_path)
			return
		var definition := (value as Dictionary).duplicate(true)
		var resource_id := String(definition.get("id", ""))
		var code := int(definition.get("code", -1))
		var required_tool := String(definition.get("required_tool", ""))
		if resource_id.is_empty() or code < 0 or _resources_by_id.has(resource_id) or _resources_by_code.has(code):
			_fail("Resource IDs and codes must be unique and non-empty in %s" % _config_path)
			return
		if not _tools_by_id.has(required_tool) or int(definition.get("durability", 0)) < 1 or int(definition.get("minimum_distance_tiles", 0)) < 1:
			_fail("Resource tool, durability or spacing is invalid for '%s'" % resource_id)
			return
		for drop_value in definition.get("drops", []) as Array:
			var drop := drop_value as Dictionary
			var item_id := String(drop.get("item_id", ""))
			if not _items_by_id.has(item_id) or int(drop.get("minimum", 0)) < 1 or int(drop.get("maximum", 0)) < int(drop.get("minimum", 0)):
				_fail("Resource '%s' has an invalid drop rule" % resource_id)
				return
		_resources.append(definition)
		_resources_by_id[resource_id] = definition
		_resources_by_code[code] = definition
	for required_id in REQUIRED_TOOL_IDS:
		if not _tools_by_id.has(required_id):
			_fail("Missing required tool '%s' in %s" % [required_id, _config_path])
			return
	for required_id in REQUIRED_RESOURCE_IDS:
		if not _resources_by_id.has(required_id):
			_fail("Missing required resource '%s' in %s" % [required_id, _config_path])
			return
	for expected_code in _resources.size():
		if not _resources_by_code.has(expected_code):
			_fail("Resource codes must be contiguous from zero in %s" % _config_path)
			return
	for biome_id in BiomeCatalog.REQUIRED_IDS:
		var total_weight := 0.0
		for definition in _resources:
			total_weight += float((definition.get("biome_weights", {}) as Dictionary).get(biome_id, 0.0))
		if total_weight > 1.0:
			_fail("Resource weights exceed 1.0 for biome '%s'" % biome_id)
			return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
