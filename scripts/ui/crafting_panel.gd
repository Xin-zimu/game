class_name CraftingPanel
extends Control

var _recipe_catalog := RecipeCatalog.new()
var _stream_manager: ChunkStreamManager
var _window: PanelContainer
var _station_row: HBoxContainer
var _recipe_list: VBoxContainer
var _status_label: Label
var _selected_station: StringName = &"hands"
var _views: Array = []


func _ready() -> void:
	theme = UIThemeFactory.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_window()
	EventBus.crafting_state_changed.connect(_on_crafting_state_changed)


func configure(stream_manager: ChunkStreamManager) -> void:
	_stream_manager = stream_manager
	_on_crafting_state_changed(stream_manager.crafting_views())


func is_crafting_open() -> bool:
	return _window != null and _window.visible


func toggle_crafting() -> void:
	set_crafting_open(not is_crafting_open())


func set_crafting_open(open: bool) -> void:
	_window.visible = open
	if open and _stream_manager != null:
		_on_crafting_state_changed(_stream_manager.crafting_views())


func _build_window() -> void:
	_window = PanelContainer.new()
	_window.name = "CraftingWindow"
	UiLayout.centered(_window, Vector2(610, 520))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("071319f7")
	style.border_color = Color("b26f3f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	_window.add_theme_stylebox_override("panel", style)
	_window.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_window.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := Label.new()
	title.text = "工具和制作"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f3c07a"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := Button.new()
	close.text = "关闭 [C]"
	close.pressed.connect(func() -> void: set_crafting_open(false))
	title_row.add_child(close)
	_station_row = HBoxContainer.new()
	_station_row.name = "CraftingStationTabs"
	_station_row.add_theme_constant_override("separation", 8)
	column.add_child(_station_row)
	for station_id in _recipe_catalog.station_ids():
		var button := Button.new()
		button.name = "Station_%s" % station_id
		button.text = _recipe_catalog.station_display_name(station_id)
		button.pressed.connect(_select_station.bind(station_id))
		_station_row.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.name = "CraftingRecipeScroll"
	scroll.custom_minimum_size = Vector2(0, 365)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_recipe_list = VBoxContainer.new()
	_recipe_list.name = "CraftingRecipeList"
	_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recipe_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_recipe_list)
	_status_label = Label.new()
	_status_label.name = "CraftingStatusLabel"
	_status_label.text = "发现材料会永久解锁对应配方"
	_status_label.add_theme_color_override("font_color", Color("a9c7b5"))
	column.add_child(_status_label)
	_window.visible = false


func _on_crafting_state_changed(recipe_views: Array) -> void:
	_views = recipe_views.duplicate(true)
	_refresh_recipe_list()


func _refresh_recipe_list() -> void:
	for child in _recipe_list.get_children():
		_recipe_list.remove_child(child)
		child.queue_free()
	var visible_count := 0
	for value in _views:
		var view := value as Dictionary
		if StringName(view.get("station_id", "hands")) != _selected_station:
			continue
		visible_count += 1
		var row := PanelContainer.new()
		row.name = "Recipe_%s" % view["recipe_id"]
		var style := StyleBoxFlat.new()
		style.bg_color = Color("152520")
		style.border_color = Color("52705f") if bool(view["unlocked"]) else Color("4a4f4d")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		row.add_theme_stylebox_override("panel", style)
		_recipe_list.add_child(row)
		var content := HBoxContainer.new()
		content.add_theme_constant_override("separation", 12)
		row.add_child(content)
		var labels := VBoxContainer.new()
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(labels)
		var name_label := Label.new()
		name_label.text = String(view["display_name"]) if bool(view["unlocked"]) else "未解锁配方"
		name_label.add_theme_color_override("font_color", Color("f1d195") if bool(view["unlocked"]) else Color("8d9690"))
		labels.add_child(name_label)
		var materials := Label.new()
		materials.text = String(view["materials"]) if bool(view["unlocked"]) else "继续发现材料以解锁"
		materials.add_theme_font_size_override("font_size", 12)
		materials.add_theme_color_override("font_color", Color("a8c0b2"))
		labels.add_child(materials)
		var craft_button := Button.new()
		craft_button.name = "Craft_%s" % view["recipe_id"]
		craft_button.text = "制作 ×%d" % int(view["output_quantity"])
		craft_button.disabled = not bool(view["craftable"])
		var recipe_id := StringName(view["recipe_id"])
		craft_button.pressed.connect(_request_recipe.bind(recipe_id))
		content.add_child(craft_button)
	if visible_count == 0:
		var empty := Label.new()
		empty.text = "此制作设施目前没有配方"
		empty.add_theme_color_override("font_color", Color("8d9690"))
		_recipe_list.add_child(empty)


func _select_station(station_id: StringName) -> void:
	_selected_station = station_id
	_refresh_recipe_list()


func _request_recipe(recipe_id: StringName) -> void:
	if _stream_manager != null:
		var result := _stream_manager.craft_recipe(recipe_id)
		_status_label.text = String(result["message"])
