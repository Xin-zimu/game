class_name RecipeData
extends Resource

@export var recipe_id: StringName = &""
@export var display_name := ""
@export var station_id: StringName = &"hands"
@export var inputs: Dictionary = {}
@export var output_item_id: StringName = &""
@export var output_quantity := 1
@export var unlock_items: Array[StringName] = []


func configure(definition: Dictionary) -> void:
	recipe_id = StringName(definition.get("id", ""))
	display_name = String(definition.get("display_name", recipe_id))
	station_id = StringName(definition.get("station", "hands"))
	inputs = (definition.get("inputs", {}) as Dictionary).duplicate(true)
	var output := definition.get("output", {}) as Dictionary
	output_item_id = StringName(output.get("item_id", ""))
	output_quantity = int(output.get("quantity", 1))
	unlock_items.clear()
	for value in definition.get("unlock_items", []) as Array:
		unlock_items.append(StringName(value))
