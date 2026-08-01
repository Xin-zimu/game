class_name CraftingSystem
extends RefCounted

const STATE_SCHEMA_VERSION := 1

var last_error := ""
var _inventory: InventoryModel
var _item_catalog: ItemCatalog
var _recipe_catalog: RecipeCatalog
var _discovered_items: Dictionary = {}


func _init(inventory: InventoryModel, recipe_catalog: RecipeCatalog = null) -> void:
	_inventory = inventory
	_item_catalog = inventory.catalog()
	_recipe_catalog = recipe_catalog if recipe_catalog != null else RecipeCatalog.new(RecipeCatalog.DEFAULT_CONFIG_PATH, _item_catalog)


func recipe_catalog() -> RecipeCatalog:
	return _recipe_catalog


func refresh_discoveries() -> void:
	for item_id in _inventory.count_snapshot().keys():
		if int(_inventory.quantity(StringName(item_id))) > 0:
			_discovered_items[String(item_id)] = true


func station_available(station_id: StringName) -> bool:
	if station_id == &"hands":
		return true
	var required_item := _recipe_catalog.station_required_item(station_id)
	return not required_item.is_empty() and _inventory.quantity(required_item) > 0


func is_unlocked(recipe_id: StringName) -> bool:
	var definition := _recipe_catalog.recipe(recipe_id)
	if definition == null or not station_available(definition.station_id):
		return false
	for item_id in definition.unlock_items:
		if not _discovered_items.has(String(item_id)):
			return false
	return true


func can_craft(recipe_id: StringName) -> bool:
	var definition := _recipe_catalog.recipe(recipe_id)
	if definition == null or not is_unlocked(recipe_id):
		return false
	for item_id in definition.inputs.keys():
		if _inventory.quantity(StringName(item_id)) < int(definition.inputs[item_id]):
			return false
	var simulation := InventoryModel.new(_item_catalog)
	if not simulation.restore_snapshot(_inventory.snapshot()):
		return false
	for item_id in definition.inputs.keys():
		simulation.remove_item(StringName(item_id), int(definition.inputs[item_id]))
	return int(simulation.add_item(definition.output_item_id, definition.output_quantity)["remainder"]) == 0


func craft(recipe_id: StringName) -> Dictionary:
	refresh_discoveries()
	var definition := _recipe_catalog.recipe(recipe_id)
	if definition == null:
		return _fail("未知制作配方：%s" % recipe_id)
	if not station_available(definition.station_id):
		return _fail("需要%s才能制作" % _recipe_catalog.station_display_name(definition.station_id))
	for item_id in definition.unlock_items:
		if not _discovered_items.has(String(item_id)):
			return _fail("配方尚未解锁：需要发现%s" % _item_catalog.display_name(item_id))
	for item_id in definition.inputs.keys():
		var required := int(definition.inputs[item_id])
		var current := _inventory.quantity(StringName(item_id))
		if current < required:
			return _fail("材料不足：%s %d/%d" % [_item_catalog.display_name(StringName(item_id)), current, required])
	var simulation := InventoryModel.new(_item_catalog)
	if not simulation.restore_snapshot(_inventory.snapshot()):
		return _fail("无法创建制作事务：%s" % simulation.last_error)
	for item_id in definition.inputs.keys():
		if not simulation.remove_item(StringName(item_id), int(definition.inputs[item_id])):
			return _fail("制作事务扣除材料失败")
	var add_result := simulation.add_item(definition.output_item_id, definition.output_quantity)
	if int(add_result["remainder"]) > 0:
		return _fail("背包空间不足，制作未消耗材料")
	if not _inventory.restore_snapshot(simulation.snapshot()):
		return _fail("无法提交制作事务：%s" % _inventory.last_error)
	_discovered_items[String(definition.output_item_id)] = true
	last_error = ""
	return {
		"ok": true,
		"recipe_id": String(recipe_id),
		"item_id": String(definition.output_item_id),
		"quantity": definition.output_quantity,
		"message": "制作完成：%s ×%d" % [_item_catalog.display_name(definition.output_item_id), definition.output_quantity],
	}


func recipe_views() -> Array[Dictionary]:
	refresh_discoveries()
	var result: Array[Dictionary] = []
	for definition in _recipe_catalog.recipes():
		var material_parts: Array[String] = []
		for item_id in definition.inputs.keys():
			material_parts.append("%s %d/%d" % [
				_item_catalog.display_name(StringName(item_id)),
				_inventory.quantity(StringName(item_id)),
				int(definition.inputs[item_id]),
			])
		result.append({
			"recipe_id": String(definition.recipe_id),
			"display_name": definition.display_name,
			"station_id": String(definition.station_id),
			"station_name": _recipe_catalog.station_display_name(definition.station_id),
			"unlocked": is_unlocked(definition.recipe_id),
			"craftable": can_craft(definition.recipe_id),
			"materials": " · ".join(material_parts),
			"output_name": _item_catalog.display_name(definition.output_item_id),
			"output_quantity": definition.output_quantity,
		})
	return result


func persistence_snapshot() -> Dictionary:
	var discovered: Array[String] = []
	for item_id in _discovered_items.keys():
		discovered.append(String(item_id))
	discovered.sort()
	return {"schema_version": STATE_SCHEMA_VERSION, "discovered_items": discovered}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_discovered_items.clear()
		refresh_discoveries()
		return true
	if int(value.get("schema_version", 0)) != STATE_SCHEMA_VERSION:
		last_error = "制作解锁数据版本无效"
		return false
	var discovered_value: Variant = value.get("discovered_items", [])
	if not discovered_value is Array:
		last_error = "制作解锁列表必须是数组"
		return false
	var restored := {}
	for item_id_value in discovered_value as Array:
		var item_id := StringName(item_id_value)
		if not _item_catalog.has_item(item_id):
			last_error = "制作解锁包含未知物品：%s" % item_id
			return false
		restored[String(item_id)] = true
	_discovered_items = restored
	refresh_discoveries()
	last_error = ""
	return true


func _fail(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "message": message}
