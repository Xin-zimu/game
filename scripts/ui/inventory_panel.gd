class_name InventoryPanel
extends Control

class SlotView extends PanelContainer:
	var slot_index := -1
	var inventory_ui: InventoryPanel
	var hotbar_copy := false
	var icon: ColorRect
	var item_label: Label
	var quantity_label: Label

	func configure(next_index: int, next_ui: InventoryPanel, is_hotbar := false) -> void:
		slot_index = next_index
		inventory_ui = next_ui
		hotbar_copy = is_hotbar
		name = ("HotbarSlot%02d" if is_hotbar else "InventorySlot%02d") % (slot_index + 1)
		custom_minimum_size = Vector2(70, 62) if not is_hotbar else Vector2(52, 52)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 5)
		margin.add_theme_constant_override("margin_right", 5)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		add_child(margin)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 1)
		margin.add_child(column)
		icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(22, 20)
		icon.color = Color("1a2a28")
		column.add_child(icon)
		item_label = Label.new()
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_label.add_theme_font_size_override("font_size", 11 if not is_hotbar else 10)
		column.add_child(item_label)
		quantity_label = Label.new()
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity_label.add_theme_font_size_override("font_size", 11)
		column.add_child(quantity_label)

	func update_slot(value: Dictionary, catalog: ItemCatalog, selected: bool) -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("182521f2")
		style.border_color = Color("e2c178") if selected else Color("4f6c5d")
		style.set_border_width_all(3 if selected else 2)
		style.set_corner_radius_all(4)
		add_theme_stylebox_override("panel", style)
		if value.is_empty():
			icon.color = Color("172421")
			item_label.text = "空"
			item_label.add_theme_color_override("font_color", Color("6f8278"))
			quantity_label.text = ""
			tooltip_text = "空格"
			return
		var item_id := StringName(value["item_id"])
		icon.color = catalog.item_color(item_id)
		item_label.text = catalog.display_name(item_id)
		item_label.add_theme_color_override("font_color", Color("e8efe9"))
		quantity_label.text = "×%d" % int(value["quantity"])
		if value.has("durability"):
			quantity_label.text = "耐 %d" % int(value["durability"])
		quantity_label.add_theme_color_override("font_color", Color("e2c178"))
		tooltip_text = "%s · %s · %d/%d" % [catalog.display_name(item_id), catalog.category_name(item_id), int(value["quantity"]), catalog.maximum_stack(item_id)]
		if value.has("durability"):
			tooltip_text += " · 耐久 %d/%d" % [int(value["durability"]), catalog.maximum_durability(item_id)]

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				inventory_ui.select_slot(slot_index)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				inventory_ui.split_slot(slot_index)
			accept_event()

	func _get_drag_data(_at_position: Vector2) -> Variant:
		var value := inventory_ui.slot_value(slot_index)
		if value.is_empty():
			return null
		inventory_ui.select_slot(slot_index)
		var preview := Label.new()
		preview.text = "%s ×%d" % [inventory_ui.catalog().display_name(StringName(value["item_id"])), int(value["quantity"])]
		preview.theme = UIThemeFactory.create_theme()
		preview.add_theme_color_override("font_color", Color("fff1bd"))
		set_drag_preview(preview)
		return {"inventory_slot": slot_index}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and (data as Dictionary).has("inventory_slot")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		inventory_ui.move_slot(int((data as Dictionary)["inventory_slot"]), slot_index)


var _catalog := ItemCatalog.new()
var _stream_manager: ChunkStreamManager
var _inventory_window: PanelContainer
var _detail_label: Label
var _grid_views: Array[SlotView] = []
var _hotbar_views: Array[SlotView] = []
var _snapshot: Dictionary = {}
var _selected_slot := -1


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_inventory_window()
	_build_hotbar()
	EventBus.inventory_state_changed.connect(_on_inventory_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_inventory_state_changed(stream_manager.inventory_state_snapshot())


func catalog() -> ItemCatalog:
	return _catalog


func is_inventory_open() -> bool:
	return _inventory_window != null and _inventory_window.visible


func toggle_inventory() -> void:
	set_inventory_open(not is_inventory_open())


func set_inventory_open(open: bool) -> void:
	_inventory_window.visible = open
	if open:
		EventBus.interaction_feedback.emit("拖拽交换 · 右键拆半 · 按分类整理", true)


func slot_value(index: int) -> Dictionary:
	var values: Variant = _snapshot.get("slots", [])
	if values is Array and index >= 0 and index < (values as Array).size() and (values as Array)[index] is Dictionary:
		return ((values as Array)[index] as Dictionary).duplicate(true)
	return {}


func select_slot(index: int) -> void:
	_selected_slot = index
	if index < _catalog.hotbar_slot_count() and _stream_manager != null:
		_stream_manager.select_hotbar_slot(index)
	_refresh_views()


func move_slot(from_index: int, to_index: int) -> void:
	if _stream_manager != null:
		_stream_manager.move_inventory_slot(from_index, to_index)


func split_slot(from_index: int) -> void:
	if _stream_manager == null:
		return
	var values: Variant = _snapshot.get("slots", [])
	var destination := -1
	if values is Array:
		for index in (values as Array).size():
			if (values as Array)[index] is Dictionary and ((values as Array)[index] as Dictionary).is_empty():
				destination = index
				break
	if destination < 0:
		EventBus.interaction_feedback.emit("背包已满，没有空格可以拆分堆叠", false)
		return
	_stream_manager.split_inventory_stack(from_index, destination)


func _build_inventory_window() -> void:
	_inventory_window = PanelContainer.new()
	_inventory_window.name = "InventoryWindow"
	_inventory_window.position = Vector2(365, 112)
	_inventory_window.custom_minimum_size = Vector2(550, 470)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("071319f7")
	style.border_color = Color("8b6d47")
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	_inventory_window.add_theme_stylebox_override("panel", style)
	_inventory_window.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_inventory_window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_inventory_window.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := Label.new()
	title.text = "背包 · 24 格"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f2d48c"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close_button := Button.new()
	close_button.text = "关闭 [I]"
	close_button.pressed.connect(func() -> void: set_inventory_open(false))
	title_row.add_child(close_button)
	var grid := GridContainer.new()
	grid.name = "InventoryGrid"
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for index in _catalog.slot_count():
		var view := SlotView.new()
		view.configure(index, self)
		grid.add_child(view)
		_grid_views.append(view)
	_detail_label = Label.new()
	_detail_label.name = "InventoryDetailLabel"
	_detail_label.text = "选择一个格子查看物品"
	_detail_label.add_theme_color_override("font_color", Color("a9c7b5"))
	column.add_child(_detail_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	var split_button := Button.new()
	split_button.name = "SplitStackButton"
	split_button.text = "拆分一半"
	split_button.pressed.connect(func() -> void: split_slot(_selected_slot))
	actions.add_child(split_button)
	var discard_button := Button.new()
	discard_button.name = "DiscardItemButton"
	discard_button.text = "丢弃整组"
	discard_button.pressed.connect(func() -> void:
		if _stream_manager != null:
			_stream_manager.discard_inventory_slot(_selected_slot)
	)
	actions.add_child(discard_button)
	var sort_button := Button.new()
	sort_button.name = "SortInventoryButton"
	sort_button.text = "按分类整理 [R]"
	sort_button.pressed.connect(func() -> void:
		if _stream_manager != null:
			_stream_manager.sort_inventory()
	)
	actions.add_child(sort_button)
	_inventory_window.visible = false


func _build_hotbar() -> void:
	var hotbar := PanelContainer.new()
	hotbar.name = "Hotbar"
	hotbar.position = Vector2(414, 620)
	hotbar.custom_minimum_size = Vector2(452, 62)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("071319e8")
	style.border_color = Color("506e60")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	hotbar.add_theme_stylebox_override("panel", style)
	hotbar.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(hotbar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	hotbar.add_child(row)
	for index in _catalog.hotbar_slot_count():
		var wrapper := VBoxContainer.new()
		wrapper.add_theme_constant_override("separation", 0)
		row.add_child(wrapper)
		var key_label := Label.new()
		key_label.text = str(index + 1)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 9)
		key_label.add_theme_color_override("font_color", Color("9fb8aa"))
		wrapper.add_child(key_label)
		var view := SlotView.new()
		view.configure(index, self, true)
		wrapper.add_child(view)
		_hotbar_views.append(view)


func _on_inventory_state_changed(next_snapshot: Dictionary) -> void:
	_snapshot = next_snapshot.duplicate(true)
	_refresh_views()


func _refresh_views() -> void:
	if _snapshot.is_empty():
		return
	var selected_hotbar := int(_snapshot.get("selected_hotbar_slot", 0))
	for index in _grid_views.size():
		_grid_views[index].update_slot(slot_value(index), _catalog, index == _selected_slot)
	for index in _hotbar_views.size():
		_hotbar_views[index].update_slot(slot_value(index), _catalog, index == selected_hotbar)
	var selected_value := slot_value(_selected_slot)
	if selected_value.is_empty():
		_detail_label.text = "选择一个格子查看物品"
	else:
		var item_id := StringName(selected_value["item_id"])
		_detail_label.text = "%s · %s · 堆叠 %d/%d" % [
			_catalog.display_name(item_id),
			_catalog.category_name(item_id),
			int(selected_value["quantity"]),
			_catalog.maximum_stack(item_id),
		]
		if selected_value.has("durability"):
			_detail_label.text += " · 耐久 %d/%d" % [int(selected_value["durability"]), _catalog.maximum_durability(item_id)]
