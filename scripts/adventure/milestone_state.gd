class_name MilestoneState
extends RefCounted

const SCHEMA_VERSION := 1

var ruin_discovered := false
var boss_defeated := false
var reward_claimed := false
var last_error := ""


func discover_ruin() -> bool:
	if ruin_discovered:
		return false
	ruin_discovered = true
	return true


func defeat_boss() -> bool:
	if boss_defeated:
		return false
	ruin_discovered = true
	boss_defeated = true
	return true


func claim_reward() -> bool:
	if not boss_defeated or reward_claimed:
		return false
	reward_claimed = true
	return true


func persistence_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"ruin_discovered": ruin_discovered,
		"boss_defeated": boss_defeated,
		"reward_claimed": reward_claimed,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	last_error = ""
	if snapshot.is_empty():
		return true
	if int(snapshot.get("schema_version", 0)) != SCHEMA_VERSION:
		last_error = "里程碑存档版本无效"
		return false
	for key in ["ruin_discovered", "boss_defeated", "reward_claimed"]:
		if not snapshot.get(key, null) is bool:
			last_error = "里程碑字段 %s 必须是布尔值" % key
			return false
	var next_discovered := bool(snapshot["ruin_discovered"])
	var next_defeated := bool(snapshot["boss_defeated"])
	var next_claimed := bool(snapshot["reward_claimed"])
	if next_defeated and not next_discovered:
		last_error = "Boss 已击败但遗迹未发现"
		return false
	if next_claimed and not next_defeated:
		last_error = "奖励已领取但 Boss 未击败"
		return false
	ruin_discovered = next_discovered
	boss_defeated = next_defeated
	reward_claimed = next_claimed
	return true


func objective_text() -> String:
	if reward_claimed:
		return "完整闭环完成 · 继续探索"
	if boss_defeated:
		return "在遗迹核心领取奖励"
	if ruin_discovered:
		return "击败遗迹守卫"
	return "寻找世界中的古老遗迹"
