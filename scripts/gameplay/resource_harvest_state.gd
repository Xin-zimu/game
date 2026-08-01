class_name ResourceHarvestState
extends RefCounted

var collected_resources: Dictionary = {}
var _durability: Dictionary = {}
var _inventory: Dictionary = {}


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


func collect_item(item_id: StringName, quantity: int) -> void:
	if quantity <= 0:
		return
	var key := String(item_id)
	_inventory[key] = int(_inventory.get(key, 0)) + quantity


func inventory_snapshot() -> Dictionary:
	return _inventory.duplicate()


func quantity(item_id: StringName) -> int:
	return int(_inventory.get(String(item_id), 0))


func remaining_durability(resource_key: String, resource_code: int, catalog: ResourceCatalog) -> int:
	return int(_durability.get(resource_key, catalog.durability_for_code(resource_code)))


func restore_snapshot(collected_values: Array, inventory_values: Dictionary) -> void:
	collected_resources.clear()
	_durability.clear()
	_inventory.clear()
	for value in collected_values:
		var key := String(value)
		if key.split(":").size() == 3:
			collected_resources[key] = true
	for item_id in inventory_values:
		var quantity_value := maxi(int(inventory_values[item_id]), 0)
		if quantity_value > 0:
			_inventory[String(item_id)] = quantity_value


func persistence_snapshot() -> Dictionary:
	var collected: Array[String] = []
	for key in collected_resources.keys():
		collected.append(String(key))
	collected.sort()
	return {
		"collected_resources": collected,
		"inventory": inventory_snapshot(),
	}
