class_name ItemCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/items.json"
const REQUIRED_ITEM_IDS := [
	"wood", "stone", "fiber", "branch", "wildflower", "slime_gel", "wolf_pelt", "bat_wing", "berry", "cooked_berries",
	"wood_axe", "wood_pickaxe", "wood_sword", "stone_axe", "stone_pickaxe", "stone_sword",
	"workbench", "campfire", "torch",
]

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _slot_count := 24
var _hotbar_slot_count := 8
var _categories: Dictionary = {}
var _items: Array[ItemData] = []
var _items_by_id: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func slot_count() -> int:
	return _slot_count


func hotbar_slot_count() -> int:
	return _hotbar_slot_count


func item_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for item in _items:
		result.append(item.item_id)
	return result


func has_item(item_id: StringName) -> bool:
	return _items_by_id.has(String(item_id))


func item(item_id: StringName) -> ItemData:
	return _items_by_id.get(String(item_id)) as ItemData


func display_name(item_id: StringName) -> String:
	var definition := item(item_id)
	return definition.display_name if definition != null else String(item_id)


func category_name(item_id: StringName) -> String:
	var definition := item(item_id)
	return definition.category_name if definition != null else "未知分类"


func maximum_stack(item_id: StringName) -> int:
	var definition := item(item_id)
	return definition.maximum_stack if definition != null else 0


func item_color(item_id: StringName) -> Color:
	var definition := item(item_id)
	return definition.color if definition != null else Color.WHITE


func tool_kind(item_id: StringName) -> StringName:
	var definition := item(item_id)
	return definition.tool_kind if definition != null else &""


func tool_power(item_id: StringName) -> int:
	var definition := item(item_id)
	return definition.tool_power if definition != null else 0


func maximum_durability(item_id: StringName) -> int:
	var definition := item(item_id)
	return definition.maximum_durability if definition != null else 0


func is_durable(item_id: StringName) -> bool:
	return maximum_durability(item_id) > 0


func station_kind(item_id: StringName) -> StringName:
	var definition := item(item_id)
	return definition.station_kind if definition != null else &""


func sort_key(item_id: StringName) -> String:
	var definition := item(item_id)
	return definition.sort_key() if definition != null else "99999999|%s" % item_id


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open item configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Item configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 2:
		_fail("Unsupported item schema version in %s" % _config_path)
		return
	_slot_count = int(root.get("inventory_slot_count", 0))
	_hotbar_slot_count = int(root.get("hotbar_slot_count", 0))
	if _slot_count < 1 or _hotbar_slot_count < 1 or _hotbar_slot_count > _slot_count:
		_fail("Inventory and hotbar slot counts are invalid in %s" % _config_path)
		return
	for value in root.get("categories", []) as Array:
		if not value is Dictionary:
			_fail("Item category entry is not an object in %s" % _config_path)
			return
		var category := (value as Dictionary).duplicate(true)
		var category_id := String(category.get("id", ""))
		if category_id.is_empty() or _categories.has(category_id) or String(category.get("display_name", "")).is_empty():
			_fail("Item category IDs must be unique and named in %s" % _config_path)
			return
		_categories[category_id] = category
	for value in root.get("items", []) as Array:
		if not value is Dictionary:
			_fail("Item entry is not an object in %s" % _config_path)
			return
		var definition := value as Dictionary
		var item_id := String(definition.get("id", ""))
		var category_id := String(definition.get("category", ""))
		if item_id.is_empty() or _items_by_id.has(item_id):
			_fail("Item IDs must be unique and non-empty in %s" % _config_path)
			return
		if not _categories.has(category_id) or int(definition.get("max_stack", 0)) < 1:
			_fail("Item '%s' has an invalid category or stack limit" % item_id)
			return
		var durability := int(definition.get("durability", 0))
		var tool_kind_value := String(definition.get("tool_kind", ""))
		var tool_power_value := int(definition.get("tool_power", 0))
		if (durability > 0 or not tool_kind_value.is_empty() or tool_power_value > 0) and (durability < 1 or tool_kind_value.is_empty() or tool_power_value < 1 or int(definition.get("max_stack", 0)) != 1):
			_fail("Durable item '%s' requires kind, power, durability and max stack 1" % item_id)
			return
		var next_item := ItemData.new()
		next_item.configure(definition, _categories[category_id] as Dictionary)
		_items.append(next_item)
		_items_by_id[item_id] = next_item
	for required_id in REQUIRED_ITEM_IDS:
		if not _items_by_id.has(required_id):
			_fail("Missing required item '%s' in %s" % [required_id, _config_path])
			return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
