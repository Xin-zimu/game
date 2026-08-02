class_name GraveModel
extends RefCounted

const SCHEMA_VERSION := 1

var last_error := ""
var _next_id := 1
var _graves: Array[Dictionary] = []
var _item_catalog: ItemCatalog


func _init(item_catalog: ItemCatalog = null) -> void:
	_item_catalog = item_catalog if item_catalog != null else ItemCatalog.new()


func graves() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for grave in _graves:
		result.append(grave.duplicate(true))
	return result


func grave_count() -> int:
	return _graves.size()


func deposit(world_position: Vector2, inventory: InventoryModel) -> Dictionary:
	if inventory == null or inventory.is_empty():
		last_error = "没有物品需要存入墓碑"
		return {}
	var grave := {
		"id": _next_id,
		"position": [world_position.x, world_position.y],
		"inventory": inventory.snapshot(),
	}
	_next_id += 1
	_graves.append(grave)
	inventory.clear()
	last_error = ""
	return grave.duplicate(true)


func nearest_grave(world_position: Vector2, radius: float) -> Dictionary:
	var nearest: Dictionary = {}
	var best_distance := radius * radius
	for grave in _graves:
		var position_value := grave["position"] as Array
		var grave_position := Vector2(float(position_value[0]), float(position_value[1]))
		var distance := world_position.distance_squared_to(grave_position)
		if distance <= best_distance:
			best_distance = distance
			nearest = grave.duplicate(true)
	return nearest


func reclaim(grave_id: int, inventory: InventoryModel) -> Dictionary:
	var index := _find_index(grave_id)
	if index < 0 or inventory == null:
		return _fail("墓碑不存在或背包不可用")
	var grave := _graves[index]
	var source := InventoryModel.new(_item_catalog)
	if not source.restore_snapshot(grave["inventory"] as Dictionary):
		return _fail("墓碑物品损坏：%s" % source.last_error)
	var remaining := InventoryModel.new(_item_catalog)
	var transferred := 0
	for slot_value in source.slots_snapshot():
		if slot_value.is_empty():
			continue
		var item_id := StringName(slot_value["item_id"])
		var quantity := int(slot_value["quantity"])
		var durability := int(slot_value.get("durability", -1))
		var add_result := inventory.add_item(item_id, quantity, durability)
		transferred += int(add_result["accepted"])
		var remainder := int(add_result["remainder"])
		if remainder > 0:
			remaining.add_item(item_id, remainder, durability)
	if remaining.is_empty():
		_graves.remove_at(index)
		last_error = ""
		return {"ok": true, "complete": true, "transferred": transferred, "remaining": 0}
	grave["inventory"] = remaining.snapshot()
	_graves[index] = grave
	last_error = "背包空间不足，墓碑仍保留剩余物品"
	return {"ok": true, "complete": false, "transferred": transferred, "remaining": _count_items(remaining)}


func persistence_snapshot() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "next_id": _next_id, "graves": graves()}


func restore_snapshot(value: Dictionary) -> bool:
	if value.is_empty():
		_next_id = 1
		_graves.clear()
		last_error = ""
		return true
	if int(value.get("schema_version", 0)) != SCHEMA_VERSION:
		last_error = "墓碑数据版本无效"
		return false
	var graves_value: Variant = value.get("graves", [])
	if not graves_value is Array:
		last_error = "墓碑列表必须是数组"
		return false
	var restored: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	var maximum_id := 0
	for grave_value in graves_value as Array:
		if not grave_value is Dictionary:
			last_error = "墓碑条目必须是对象"
			return false
		var grave := (grave_value as Dictionary).duplicate(true)
		var grave_id := int(grave.get("id", 0))
		var position_value: Variant = grave.get("position", [])
		var inventory_value: Variant = grave.get("inventory", {})
		if grave_id <= 0 or seen_ids.has(grave_id) or not position_value is Array or (position_value as Array).size() != 2 or not inventory_value is Dictionary:
			last_error = "墓碑 ID、位置或背包无效"
			return false
		var inventory := InventoryModel.new(_item_catalog)
		if not inventory.restore_snapshot(inventory_value as Dictionary) or inventory.is_empty():
			last_error = "墓碑背包无效：%s" % inventory.last_error
			return false
		seen_ids[grave_id] = true
		maximum_id = maxi(maximum_id, grave_id)
		restored.append({
			"id": grave_id,
			"position": [float(position_value[0]), float(position_value[1])],
			"inventory": inventory.snapshot(),
		})
	var requested_next := int(value.get("next_id", maximum_id + 1))
	if requested_next <= maximum_id:
		last_error = "墓碑下一个 ID 无效"
		return false
	_next_id = requested_next
	_graves = restored
	last_error = ""
	return true


func _find_index(grave_id: int) -> int:
	for index in _graves.size():
		if int(_graves[index]["id"]) == grave_id:
			return index
	return -1


func _count_items(inventory: InventoryModel) -> int:
	var total := 0
	for quantity in inventory.count_snapshot().values():
		total += int(quantity)
	return total


func _fail(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "complete": false, "transferred": 0, "remaining": 0, "message": message}
