class_name EnemyCatalog
extends RefCounted

const DEFAULT_CONFIG_PATH := "res://data/enemies.json"
const REQUIRED_IDS := ["slime", "wolf", "cave_bat"]
const VALID_PROFILES := ["hop", "pounce", "flight"]

var _config_path := DEFAULT_CONFIG_PATH
var _valid := false
var _error_message := ""
var _population: Dictionary = {}
var _enemies: Array[EnemyDefinition] = []
var _by_id: Dictionary = {}
var _item_catalog := ItemCatalog.new()
var _biome_catalog := BiomeCatalog.new()


func _init(config_path := DEFAULT_CONFIG_PATH) -> void:
	_config_path = config_path
	_load_config()


func is_valid() -> bool:
	return _valid


func error_message() -> String:
	return _error_message


func enemies() -> Array[EnemyDefinition]:
	return _enemies.duplicate()


func enemy(enemy_id: StringName) -> EnemyDefinition:
	return _by_id.get(String(enemy_id)) as EnemyDefinition


func enemy_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _enemies:
		result.append(definition.enemy_id)
	return result


func population_value(key: String, fallback: Variant) -> Variant:
	return _population.get(key, fallback)


func maximum_active() -> int:
	return int(population_value("maximum_active", 1))


func maximum_per_chunk() -> int:
	return int(population_value("maximum_per_chunk", 1))


func candidate_slots_per_chunk() -> int:
	return int(population_value("candidate_slots_per_chunk", 1))


func spawn_chance() -> float:
	return float(population_value("spawn_chance", 0.0))


func enemy_id_for_biome(biome_id: StringName, roll: float) -> StringName:
	var candidates: Array[EnemyDefinition] = []
	var total := 0.0
	for definition in _enemies:
		if definition.biomes.has(biome_id):
			candidates.append(definition)
			total += definition.spawn_weight
	if candidates.is_empty() or total <= 0.0:
		return &""
	var cursor := clampf(roll, 0.0, 0.999999) * total
	for definition in candidates:
		cursor -= definition.spawn_weight
		if cursor < 0.0:
			return definition.enemy_id
	return candidates[-1].enemy_id


func resolve_drops(enemy_id: StringName, stable_spawn_id: String) -> Array[Dictionary]:
	var definition := enemy(enemy_id)
	var result: Array[Dictionary] = []
	if definition == null:
		return result
	for index in definition.drops.size():
		var rule := definition.drops[index]
		var stable_hash := WorldSeed.from_text("%s|drop|%s|%d" % [stable_spawn_id, enemy_id, index])
		var chance_roll := float(stable_hash & 0xffff) / 65536.0
		if chance_roll >= float(rule.get("chance", 1.0)):
			continue
		var minimum := int(rule["minimum"])
		var maximum := int(rule["maximum"])
		var quantity := minimum + posmod(int(stable_hash >> 16), maximum - minimum + 1)
		result.append({"item_id": StringName(rule["item_id"]), "quantity": quantity})
	return result


func _load_config() -> void:
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		_fail("无法打开敌人配置 %s：%s" % [_config_path, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("敌人配置必须是 JSON 对象：%s" % _config_path)
		return
	var root := parsed as Dictionary
	if int(root.get("schema_version", 0)) != 1:
		_fail("敌人配置版本无效：%s" % _config_path)
		return
	_population = (root.get("population", {}) as Dictionary).duplicate(true)
	if maximum_active() < 1 or maximum_per_chunk() < 1 or candidate_slots_per_chunk() < maximum_per_chunk() \
			or spawn_chance() <= 0.0 or spawn_chance() > 1.0:
		_fail("敌人数量与生成参数必须为正数且概率不能超过 1")
		return
	var spawn_min := float(population_value("spawn_minimum_distance_pixels", 0.0))
	var spawn_max := float(population_value("spawn_maximum_distance_pixels", 0.0))
	var despawn := float(population_value("despawn_distance_pixels", 0.0))
	var sleep_distance := float(population_value("logic_sleep_distance_pixels", 0.0))
	if spawn_min < 640.0 or spawn_max <= spawn_min or despawn <= spawn_max or sleep_distance <= 0.0:
		_fail("敌人屏幕外生成、休眠和卸载距离无效")
		return
	if not _item_catalog.is_valid() or not _biome_catalog.is_valid():
		_fail("敌人依赖的物品或群系目录无效")
		return
	for value in root.get("enemies", []) as Array:
		if not value is Dictionary:
			_fail("敌人条目必须是对象")
			return
		var raw := value as Dictionary
		var enemy_id := String(raw.get("id", ""))
		if enemy_id.is_empty() or _by_id.has(enemy_id) or not VALID_PROFILES.has(String(raw.get("profile", ""))):
			_fail("敌人 ID 必须唯一且行为类型有效：%s" % enemy_id)
			return
		var biomes := raw.get("biomes", []) as Array
		if biomes.is_empty():
			_fail("敌人必须至少绑定一个群系：%s" % enemy_id)
			return
		for biome_value in biomes:
			if not _biome_catalog.has_biome(StringName(biome_value)):
				_fail("敌人 %s 引用了未知群系 %s" % [enemy_id, biome_value])
				return
		for numeric_key in ["spawn_weight", "maximum_health", "move_speed", "detection_range", "disengage_range", "attack_range", "attack_power", "attack_cooldown", "attack_windup", "attack_recovery", "return_distance"]:
			if float(raw.get(numeric_key, 0.0)) <= 0.0:
				_fail("敌人 %s 的 %s 必须为正数" % [enemy_id, numeric_key])
				return
		if float(raw.get("disengage_range", 0.0)) <= float(raw.get("detection_range", 0.0)):
			_fail("敌人 %s 的脱战距离必须大于警觉距离" % enemy_id)
			return
		for drop_value in raw.get("drops", []) as Array:
			var drop := drop_value as Dictionary
			var item_id := StringName(drop.get("item_id", ""))
			var minimum := int(drop.get("minimum", 0))
			var maximum := int(drop.get("maximum", 0))
			var chance := float(drop.get("chance", 0.0))
			if not _item_catalog.has_item(item_id) or minimum < 1 or maximum < minimum or chance <= 0.0 or chance > 1.0:
				_fail("敌人 %s 包含无效掉落规则" % enemy_id)
				return
		var definition := EnemyDefinition.new()
		definition.configure(raw)
		_enemies.append(definition)
		_by_id[enemy_id] = definition
	for required_id in REQUIRED_IDS:
		if not _by_id.has(required_id):
			_fail("缺少必需敌人：%s" % required_id)
			return
	_valid = true


func _fail(message: String) -> void:
	_error_message = message
	push_error(message)
