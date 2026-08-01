class_name RecipeCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/recipes.json"

var _config_path := DEFAULT_CONFIG_PATH
var _item_catalog: ItemCatalog
var _valid := false
var _error_message := ""
var _stations: Array[Dictionary] = []
var _stations_by_id: Dictionary = {}
var _recipes: Array[RecipeData] = []
var _recipes_by_id: Dictionary = {}


func _init(config_path := DEFAULT_CONFIG_PATH, item_catalog: ItemCatalog = null) -> void:
	_config_path = config_path
	_item_catalog = item_catalog if item_catalog != null else ItemCatalog.new()
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func recipe(recipe_id: StringName) -> RecipeData:
	return _recipes_by_id.get(String(recipe_id)) as RecipeData


func recipes() -> Array[RecipeData]:
	return _recipes.duplicate()


func station_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for station in _stations:
		result.append(StringName(station["id"]))
	return result


func station_display_name(station_id: StringName) -> String:
	return String((_stations_by_id.get(String(station_id), {}) as Dictionary).get("display_name", station_id))


func station_required_item(station_id: StringName) -> StringName:
	return StringName((_stations_by_id.get(String(station_id), {}) as Dictionary).get("required_item_id", ""))


func _load_config() -> void:
	if not _item_catalog.is_valid():
		_fail("Item catalog is invalid: %s" % _item_catalog.error_message())
		return
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("Unable to open recipe configuration %s: %s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Recipe configuration is not a JSON object: %s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("Unsupported recipe schema version in %s" % _config_path)
		return
	for value in root.get("stations", []) as Array:
		if not value is Dictionary:
			_fail("Crafting station entry is not an object")
			return
		var station := (value as Dictionary).duplicate(true)
		var station_id := String(station.get("id", ""))
		var required_item := StringName(station.get("required_item_id", ""))
		if station_id.is_empty() or _stations_by_id.has(station_id) or String(station.get("display_name", "")).is_empty():
			_fail("Crafting station IDs must be unique and named")
			return
		if not required_item.is_empty() and not _item_catalog.has_item(required_item):
			_fail("Crafting station '%s' requires an unknown item" % station_id)
			return
		_stations.append(station)
		_stations_by_id[station_id] = station
	if not _stations_by_id.has("hands"):
		_fail("Recipe catalog requires the hands station")
		return
	for value in root.get("recipes", []) as Array:
		if not value is Dictionary:
			_fail("Recipe entry is not an object")
			return
		var definition := value as Dictionary
		var next_recipe := RecipeData.new()
		next_recipe.configure(definition)
		if next_recipe.recipe_id.is_empty() or _recipes_by_id.has(String(next_recipe.recipe_id)):
			_fail("Recipe IDs must be unique and non-empty")
			return
		if not _stations_by_id.has(String(next_recipe.station_id)) or not _item_catalog.has_item(next_recipe.output_item_id) or next_recipe.output_quantity < 1:
			_fail("Recipe '%s' has an invalid station or output" % next_recipe.recipe_id)
			return
		if next_recipe.inputs.is_empty():
			_fail("Recipe '%s' must consume at least one material" % next_recipe.recipe_id)
			return
		for input_id in next_recipe.inputs.keys():
			if not _item_catalog.has_item(StringName(input_id)) or int(next_recipe.inputs[input_id]) < 1:
				_fail("Recipe '%s' has an invalid material" % next_recipe.recipe_id)
				return
		for unlock_item in next_recipe.unlock_items:
			if not _item_catalog.has_item(unlock_item):
				_fail("Recipe '%s' has an unknown unlock item" % next_recipe.recipe_id)
				return
		_recipes.append(next_recipe)
		_recipes_by_id[String(next_recipe.recipe_id)] = next_recipe
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
