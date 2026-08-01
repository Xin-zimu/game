class_name ItemData
extends Resource

@export var item_id: StringName = &""
@export var display_name := ""
@export var category_id: StringName = &""
@export var category_name := ""
@export var category_sort_order := 0
@export var maximum_stack := 1
@export var color := Color.WHITE


func configure(definition: Dictionary, category: Dictionary) -> void:
	item_id = StringName(definition.get("id", ""))
	display_name = String(definition.get("display_name", item_id))
	category_id = StringName(definition.get("category", ""))
	category_name = String(category.get("display_name", category_id))
	category_sort_order = int(category.get("sort_order", 0))
	maximum_stack = int(definition.get("max_stack", 1))
	color = Color(String(definition.get("color", "ffffff")))


func sort_key() -> String:
	return "%08d|%s|%s" % [category_sort_order, display_name, item_id]
