class_name DamageCalculator
extends RefCounted

const DEFENSE_COEFFICIENT := 0.65


static func calculate(attack_power: float, defense: float, coefficient := DEFENSE_COEFFICIENT) -> int:
	return maxi(1, roundi(maxf(0.0, attack_power) - maxf(0.0, defense) * maxf(0.0, coefficient)))
