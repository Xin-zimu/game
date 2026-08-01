class_name InventoryModel
extends RefCounted

const SCHEMA_VERSION := 2

var last_error := ""
var _catalog: ItemCatalog
var _slots: Array[Dictionary] = []
var _selected_hotbar_slot := 0


func _init(catalog: ItemCatalog = null) -> void:
	_catalog = catalog if catalog != null else ItemCatalog.new()
	_slots.resize(_catalog.slot_count())
	for index in _slots.size():
		_slots[index] = {}


func slot_count() -> int:
	return _slots.size()


func hotbar_slot_count() -> int:
	return _catalog.hotbar_slot_count()


func catalog() -> ItemCatalog:
	return _catalog


func slot(index: int) -> Dictionary:
	return _slots[index].duplicate(true) if _is_valid_index(index) else {}


func slots_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _slots:
		result.append(value.duplicate(true))
	return result


func selected_hotbar_slot() -> int:
	return _selected_hotbar_slot


func select_hotbar(index: int) -> bool:
	if index < 0 or index >= hotbar_slot_count():
		last_error = "快捷栏索引超出范围"
		return false
	_selected_hotbar_slot = index
	last_error = ""
	return true


func add_item(item_id: StringName, quantity: int, durability := -1) -> Dictionary:
	if quantity <= 0 or not _catalog.has_item(item_id):
		last_error = "无效物品或数量：%s ×%d" % [item_id, quantity]
		return {"accepted": 0, "remainder": maxi(quantity, 0), "full": false}
	var remaining := quantity
	var maximum := _catalog.maximum_stack(item_id)
	for index in _slots.size():
		if remaining <= 0:
			break
		var current := _slots[index]
		if StringName(current.get("item_id", "")) != item_id:
			continue
		var room := maximum - int(current.get("quantity", 0))
		if room <= 0:
			continue
		var moved := mini(room, remaining)
		current = current.duplicate(true)
		current["quantity"] = int(current["quantity"]) + moved
		_slots[index] = current
		remaining -= moved
	for index in _slots.size():
		if remaining <= 0:
			break
		if not _slots[index].is_empty():
			continue
		var moved := mini(maximum, remaining)
		var next_slot := {"item_id": String(item_id), "quantity": moved}
		if _catalog.is_durable(item_id):
			next_slot["durability"] = clampi(durability if durability > 0 else _catalog.maximum_durability(item_id), 1, _catalog.maximum_durability(item_id))
		_slots[index] = next_slot
		remaining -= moved
	last_error = "背包已满" if remaining > 0 else ""
	return {"accepted": quantity - remaining, "remainder": remaining, "full": remaining > 0}


func move_or_swap(from_index: int, to_index: int) -> bool:
	if not _is_valid_index(from_index) or not _is_valid_index(to_index):
		last_error = "拖拽格子索引超出范围"
		return false
	if from_index == to_index or _slots[from_index].is_empty():
		last_error = ""
		return true
	var source := _slots[from_index].duplicate(true)
	var target := _slots[to_index].duplicate(true)
	if target.is_empty():
		_slots[to_index] = source
		_slots[from_index] = {}
	elif String(target.get("item_id", "")) == String(source.get("item_id", "")):
		var item_id := StringName(source["item_id"])
		var room := _catalog.maximum_stack(item_id) - int(target["quantity"])
		var moved := mini(maxi(room, 0), int(source["quantity"]))
		target["quantity"] = int(target["quantity"]) + moved
		source["quantity"] = int(source["quantity"]) - moved
		_slots[to_index] = target
		_slots[from_index] = source if int(source["quantity"]) > 0 else {}
	else:
		_slots[to_index] = source
		_slots[from_index] = target
	last_error = ""
	return true


func split_stack(from_index: int, to_index: int, quantity := -1) -> bool:
	if not _is_valid_index(from_index) or not _is_valid_index(to_index) or from_index == to_index:
		last_error = "拆分格子索引无效"
		return false
	if _slots[from_index].is_empty() or int(_slots[from_index].get("quantity", 0)) < 2:
		last_error = "该物品堆叠无法继续拆分"
		return false
	var source := _slots[from_index].duplicate(true)
	var target := _slots[to_index].duplicate(true)
	var item_id := StringName(source["item_id"])
	if not target.is_empty() and StringName(target.get("item_id", "")) != item_id:
		last_error = "目标格不是空格或同类物品"
		return false
	var requested := floori(float(int(source["quantity"])) / 2.0) if quantity < 0 else quantity
	var target_quantity := int(target.get("quantity", 0))
	var room := _catalog.maximum_stack(item_id) - target_quantity
	var moved := mini(requested, mini(room, int(source["quantity"])))
	if moved <= 0:
		last_error = "目标堆叠已满"
		return false
	source["quantity"] = int(source["quantity"]) - moved
	_slots[from_index] = source if int(source["quantity"]) > 0 else {}
	_slots[to_index] = {"item_id": String(item_id), "quantity": target_quantity + moved}
	last_error = ""
	return true


func first_empty_slot() -> int:
	for index in _slots.size():
		if _slots[index].is_empty():
			return index
	return -1


func discard(index: int, quantity := -1) -> Dictionary:
	if not _is_valid_index(index) or _slots[index].is_empty():
		last_error = "没有可以丢弃的物品"
		return {}
	var source := _slots[index].duplicate(true)
	var available := int(source["quantity"])
	var removed := available if quantity < 0 else clampi(quantity, 1, available)
	source["quantity"] = available - removed
	_slots[index] = source if int(source["quantity"]) > 0 else {}
	last_error = ""
	var result := {"item_id": String(source["item_id"]), "quantity": removed}
	if source.has("durability"):
		result["durability"] = int(source["durability"])
	return result


func sort_inventory() -> void:
	var totals := {}
	var durable_slots: Dictionary = {}
	for current in _slots:
		if current.is_empty():
			continue
		var current_id := String(current["item_id"])
		if _catalog.is_durable(StringName(current_id)):
			if not durable_slots.has(current_id):
				durable_slots[current_id] = []
			(durable_slots[current_id] as Array).append(current.duplicate(true))
		else:
			totals[current_id] = int(totals.get(current_id, 0)) + int(current["quantity"])
	var item_ids: Array[String] = []
	for key in count_snapshot().keys():
		item_ids.append(String(key))
	item_ids.sort_custom(func(a: String, b: String) -> bool:
		return _catalog.sort_key(StringName(a)) < _catalog.sort_key(StringName(b))
	)
	for index in _slots.size():
		_slots[index] = {}
	var cursor := 0
	for item_id in item_ids:
		if durable_slots.has(item_id):
			var entries := durable_slots[item_id] as Array
			entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return int(a.get("durability", 0)) > int(b.get("durability", 0))
			)
			for entry in entries:
				_slots[cursor] = (entry as Dictionary).duplicate(true)
				cursor += 1
			continue
		var remaining := int(totals[item_id])
		var maximum := _catalog.maximum_stack(StringName(item_id))
		while remaining > 0:
			var moved := mini(maximum, remaining)
			_slots[cursor] = {"item_id": item_id, "quantity": moved}
			cursor += 1
			remaining -= moved
	last_error = ""


func remove_item(item_id: StringName, quantity_value: int) -> bool:
	if quantity_value <= 0 or quantity(item_id) < quantity_value:
		last_error = "物品数量不足：%s" % item_id
		return false
	var remaining := quantity_value
	for index in range(_slots.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var current := _slots[index]
		if StringName(current.get("item_id", "")) != item_id:
			continue
		var removed := mini(remaining, int(current["quantity"]))
		current = current.duplicate(true)
		current["quantity"] = int(current["quantity"]) - removed
		_slots[index] = current if int(current["quantity"]) > 0 else {}
		remaining -= removed
	last_error = ""
	return true


func damage_tool_at(index: int, amount := 1) -> Dictionary:
	if not _is_valid_index(index) or _slots[index].is_empty() or amount <= 0:
		last_error = "没有可以消耗耐久的工具"
		return {"accepted": false, "broken": false}
	var current := _slots[index].duplicate(true)
	var item_id := StringName(current.get("item_id", ""))
	if not _catalog.is_durable(item_id):
		last_error = "当前物品没有耐久"
		return {"accepted": false, "broken": false}
	var remaining := int(current.get("durability", _catalog.maximum_durability(item_id))) - amount
	if remaining <= 0:
		_slots[index] = {}
		last_error = ""
		return {"accepted": true, "broken": true, "item_id": String(item_id), "remaining": 0}
	current["durability"] = remaining
	_slots[index] = current
	last_error = ""
	return {"accepted": true, "broken": false, "item_id": String(item_id), "remaining": remaining}


func count_snapshot() -> Dictionary:
	var result := {}
	for current in _slots:
		if current.is_empty():
			continue
		var item_id := String(current["item_id"])
		result[item_id] = int(result.get(item_id, 0)) + int(current["quantity"])
	return result


func quantity(item_id: StringName) -> int:
	return int(count_snapshot().get(String(item_id), 0))


func snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"slot_count": slot_count(),
		"hotbar_slot_count": hotbar_slot_count(),
		"selected_hotbar_slot": _selected_hotbar_slot,
		"slots": slots_snapshot(),
	}


func restore_snapshot(value: Dictionary) -> bool:
	last_error = ""
	var source_schema := int(value.get("schema_version", 0))
	if not [1, SCHEMA_VERSION].has(source_schema):
		last_error = "背包格式版本无效"
		return false
	if int(value.get("slot_count", 0)) != slot_count() or int(value.get("hotbar_slot_count", 0)) != hotbar_slot_count():
		last_error = "背包或快捷栏格子数量不兼容"
		return false
	var values: Variant = value.get("slots", [])
	if not values is Array or (values as Array).size() != slot_count():
		last_error = "背包格子数组长度无效"
		return false
	var restored: Array[Dictionary] = []
	for index in (values as Array).size():
		var slot_value: Variant = (values as Array)[index]
		if not slot_value is Dictionary:
			last_error = "背包第 %d 格不是对象" % (index + 1)
			return false
		var current := (slot_value as Dictionary).duplicate(true)
		if current.is_empty():
			restored.append({})
			continue
		var item_id := StringName(current.get("item_id", ""))
		var quantity_value := int(current.get("quantity", 0))
		if not _catalog.has_item(item_id) or quantity_value < 1 or quantity_value > _catalog.maximum_stack(item_id):
			last_error = "背包第 %d 格包含无效物品或堆叠数量" % (index + 1)
			return false
		var normalized := {"item_id": String(item_id), "quantity": quantity_value}
		if _catalog.is_durable(item_id):
			var durability_value := int(current.get("durability", 0))
			if durability_value < 1 or durability_value > _catalog.maximum_durability(item_id):
				last_error = "背包第 %d 格的工具耐久无效" % (index + 1)
				return false
			normalized["durability"] = durability_value
		restored.append(normalized)
	var selected := int(value.get("selected_hotbar_slot", 0))
	if selected < 0 or selected >= hotbar_slot_count():
		last_error = "快捷栏选中索引无效"
		return false
	_slots = restored
	_selected_hotbar_slot = selected
	return true


func restore_legacy_counts(counts: Dictionary) -> bool:
	for index in _slots.size():
		_slots[index] = {}
	var ids: Array[String] = []
	for key in counts.keys():
		ids.append(String(key))
	ids.sort_custom(func(a: String, b: String) -> bool:
		return _catalog.sort_key(StringName(a)) < _catalog.sort_key(StringName(b))
	)
	for item_id in ids:
		var quantity_value := int(counts[item_id])
		if quantity_value <= 0:
			continue
		var result := add_item(StringName(item_id), quantity_value)
		if int(result["remainder"]) > 0:
			last_error = "旧背包数据超过当前容量：%s" % item_id
			return false
	last_error = ""
	return true


func checksum() -> String:
	return JSON.stringify(snapshot(), "", true, true).sha256_text()


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _slots.size()
