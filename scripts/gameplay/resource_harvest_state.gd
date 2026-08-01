class_name ResourceHarvestState
extends RefCounted

var collected_resources: Dictionary = {}
var _durability: Dictionary = {}
var _inventory := InventoryModel.new()


func hit(resource_key: String, resource_code: int, active_tool: StringName, catalog: ResourceCatalog) -> Dictionary:
	if collected_resources.has(resource_key):
		return {"accepted": false, "destroyed": false, "reason": "already_collected", "drops": []}
	var required_tool := catalog.required_tool_for_code(resource_code)
	if active_tool != required_tool or catalog.tool_power(active_tool) < 1:
		return {
			"accepted": false,
			"destroyed": false,
			"reason": "wrong_tool",
			"required_tool": required_tool,
			"drops": [],
		}
	var maximum := catalog.durability_for_code(resource_code)
	var remaining := int(_durability.get(resource_key, maximum)) - catalog.tool_power(active_tool)
	if remaining > 0:
		_durability[resource_key] = remaining
		return {"accepted": true, "destroyed": false, "remaining": remaining, "maximum": maximum, "drops": []}
	_durability.erase(resource_key)
	collected_resources[resource_key] = true
	var resolved_drops: Array[Dictionary] = []
	var drop_index := 0
	for value in catalog.drops_for_code(resource_code):
		var drop := value as Dictionary
		var minimum := int(drop["minimum"])
		var maximum_drop := int(drop["maximum"])
		var drop_hash := WorldSeed.from_text("%s|drop:%d" % [resource_key, drop_index])
		var quantity := minimum + int(drop_hash % (maximum_drop - minimum + 1))
		resolved_drops.append({"item_id": StringName(drop["item_id"]), "quantity": quantity})
		drop_index += 1
	return {
		"accepted": true,
		"destroyed": true,
		"remaining": 0,
		"maximum": maximum,
		"drops": resolved_drops,
	}


func collect_item(item_id: StringName, quantity: int) -> Dictionary:
	return _inventory.add_item(item_id, quantity)


func inventory_snapshot() -> Dictionary:
	return _inventory.count_snapshot()


func inventory_state_snapshot() -> Dictionary:
	return _inventory.snapshot()


func inventory_model() -> InventoryModel:
	return _inventory


func quantity(item_id: StringName) -> int:
	return _inventory.quantity(item_id)


func remaining_durability(resource_key: String, resource_code: int, catalog: ResourceCatalog) -> int:
	return int(_durability.get(resource_key, catalog.durability_for_code(resource_code)))


func restore_snapshot(collected_values: Array, inventory_values: Variant) -> bool:
	collected_resources.clear()
	_durability.clear()
	for value in collected_values:
		var key := String(value)
		if key.split(":").size() == 3:
			collected_resources[key] = true
	if not inventory_values is Dictionary:
		return _inventory.restore_legacy_counts({})
	var values := inventory_values as Dictionary
	if values.has("slots"):
		return _inventory.restore_snapshot(values)
	return _inventory.restore_legacy_counts(values)


func persistence_snapshot() -> Dictionary:
	var collected: Array[String] = []
	for key in collected_resources.keys():
		collected.append(String(key))
	collected.sort()
	return {
		"collected_resources": collected,
		"inventory": inventory_state_snapshot(),
	}


func move_inventory_slot(from_index: int, to_index: int) -> bool:
	return _inventory.move_or_swap(from_index, to_index)


func split_inventory_stack(from_index: int, to_index: int, quantity := -1) -> bool:
	return _inventory.split_stack(from_index, to_index, quantity)


func discard_inventory_slot(index: int, quantity := -1) -> Dictionary:
	return _inventory.discard(index, quantity)


func sort_inventory() -> void:
	_inventory.sort_inventory()


func select_hotbar_slot(index: int) -> bool:
	return _inventory.select_hotbar(index)
