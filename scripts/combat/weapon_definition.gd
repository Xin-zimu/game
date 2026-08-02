class_name WeaponDefinition
extends Resource

@export var weapon_id: StringName = &"unarmed"
@export var display_name := "徒手攻击"
@export var item_id: StringName = &""
@export var damage := 1.0
@export var attack_speed := 1.0
@export var attack_range := 32.0
@export var hitbox_width := 24.0
@export var active_duration := 0.1
@export var knockback := 0.0
@export var stamina_cost := 0.0
@export var combo_multipliers: Array[float] = [1.0]


func configure(value: Dictionary) -> void:
	weapon_id = StringName(value.get("id", ""))
	display_name = String(value.get("display_name", weapon_id))
	item_id = StringName(value.get("item_id", ""))
	damage = float(value.get("damage", 0.0))
	attack_speed = float(value.get("attack_speed", 0.0))
	attack_range = float(value.get("range", 0.0))
	hitbox_width = float(value.get("hitbox_width", 0.0))
	active_duration = float(value.get("active_duration", 0.0))
	knockback = float(value.get("knockback", 0.0))
	stamina_cost = float(value.get("stamina_cost", 0.0))
	combo_multipliers.clear()
	for multiplier in value.get("combo_multipliers", []) as Array:
		combo_multipliers.append(float(multiplier))


func cooldown() -> float:
	return 1.0 / attack_speed


func combo_count() -> int:
	return combo_multipliers.size()


func damage_for_combo(combo_index: int) -> float:
	if combo_multipliers.is_empty():
		return damage
	return damage * combo_multipliers[clampi(combo_index - 1, 0, combo_multipliers.size() - 1)]
