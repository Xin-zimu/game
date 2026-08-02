class_name EnemyDefinition
extends Resource

@export var enemy_id: StringName = &""
@export var display_name := ""
@export var profile: StringName = &""
@export var color := Color.WHITE
@export var biomes: Array[StringName] = []
@export var spawn_weight := 0.0
@export var maximum_health := 1.0
@export var defense := 0.0
@export var move_speed := 1.0
@export var detection_range := 1.0
@export var disengage_range := 1.0
@export var attack_range := 1.0
@export var attack_power := 1.0
@export var attack_cooldown := 1.0
@export var attack_windup := 0.1
@export var attack_recovery := 0.2
@export var knockback := 0.0
@export var return_distance := 1.0
var drops: Array[Dictionary] = []


func configure(value: Dictionary) -> void:
	enemy_id = StringName(value.get("id", ""))
	display_name = String(value.get("display_name", enemy_id))
	profile = StringName(value.get("profile", ""))
	color = Color(String(value.get("color", "ffffff")))
	biomes.clear()
	for biome_value in value.get("biomes", []) as Array:
		biomes.append(StringName(biome_value))
	spawn_weight = float(value.get("spawn_weight", 0.0))
	maximum_health = float(value.get("maximum_health", 1.0))
	defense = float(value.get("defense", 0.0))
	move_speed = float(value.get("move_speed", 1.0))
	detection_range = float(value.get("detection_range", 1.0))
	disengage_range = float(value.get("disengage_range", 1.0))
	attack_range = float(value.get("attack_range", 1.0))
	attack_power = float(value.get("attack_power", 1.0))
	attack_cooldown = float(value.get("attack_cooldown", 1.0))
	attack_windup = float(value.get("attack_windup", 0.1))
	attack_recovery = float(value.get("attack_recovery", 0.2))
	knockback = float(value.get("knockback", 0.0))
	return_distance = float(value.get("return_distance", 1.0))
	drops.clear()
	for drop_value in value.get("drops", []) as Array:
		drops.append((drop_value as Dictionary).duplicate(true))
