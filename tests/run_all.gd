extends Node

var _failures: Array[String] = []
var _passes := 0


func _ready() -> void:
	print("=== Infinite Frontier test suite v%s ===" % GameVersion.VERSION)
	_test_project_resources()
	_test_version_contract()
	_test_event_bus_contract()
	_test_settings_round_trip()
	_test_scene_transition_contract()
	_test_player_motor_frame_independence()
	_test_world_seed_contract()
	_test_world_coordinate_contract()
	_test_biome_catalog_contract()
	_test_resource_catalog_contract()
	_test_item_catalog_contract()
	_test_inventory_model()
	_test_recipe_catalog_contract()
	_test_crafting_system()
	_test_tool_speed_and_durability()
	_test_weapon_catalog_contract()
	_test_attack_sequence_and_damage()
	_test_player_combat_state_and_graves()
	_test_enemy_catalog_and_state_machine()
	_test_enemy_spawn_planner()
	_test_milestone_models()
	_test_deterministic_generation()
	_test_biome_regions()
	_test_resource_generation()
	_test_resource_harvest_state()
	await _test_save_system()
	_test_stream_planner()
	_test_chunk_seams()
	_test_background_generation()
	await _test_player_scene_contract()
	await _test_chunk_renderer()
	await _test_drop_pool()
	await _test_generation_hud_layout()
	await _test_resource_hud_layout()
	await _test_inventory_panel_layout()
	await _test_crafting_panel_layout()
	await _test_combat_nodes_and_hud()
	await _test_enemy_runtime_and_hud()
	await _test_adventure_runtime_and_hud()
	await _test_main_menu_layout()
	await _test_responsive_ui_layouts()
	await get_tree().process_frame
	await get_tree().process_frame
	_finish()


func _test_project_resources() -> void:
	_assert_true(ResourceLoader.exists("res://scenes/main/main.tscn"), "main scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/main/game.tscn"), "game scene exists")
	_assert_true(ResourceLoader.exists("res://scenes/player/player.tscn"), "player scene exists")
	_assert_true(ResourceLoader.exists("res://assets/branding/icon.svg"), "application icon exists")
	_assert_true(ResourceLoader.exists("res://data/weapons.json"), "weapon catalog exists")
	_assert_true(ResourceLoader.exists("res://data/enemies.json"), "enemy catalog exists")
	_assert_true(ResourceLoader.exists("res://data/milestones.json"), "milestone catalog exists")


func _test_version_contract() -> void:
	_assert_equal(GameVersion.VERSION, "1.0.1", "version constant")
	_assert_equal(GameVersion.SAVE_VERSION, 6, "V1.0 milestone progression advances save format 6")
	_assert_equal(GameVersion.GENERATION_VERSION, 4, "V1.0 landmark overlay preserves generation version 4")


func _test_event_bus_contract() -> void:
	_assert_true(EventBus.has_signal("scene_change_requested"), "scene signal exists")
	_assert_true(EventBus.has_signal("settings_changed"), "settings signal exists")
	_assert_true(EventBus.has_signal("notification_requested"), "notification signal exists")
	_assert_true(EventBus.has_signal("resource_prompt_changed"), "resource prompt signal exists")
	_assert_true(EventBus.has_signal("inventory_changed"), "inventory signal exists")
	_assert_true(EventBus.has_signal("inventory_state_changed"), "slot inventory signal exists")
	_assert_true(EventBus.has_signal("crafting_state_changed"), "crafting recipe-view signal exists")
	_assert_true(EventBus.has_signal("attack_started"), "attack lifecycle signal exists")
	_assert_true(EventBus.has_signal("combat_status_changed"), "combat status signal exists")
	_assert_true(EventBus.has_signal("combat_feedback"), "combat feedback signal exists")
	_assert_true(EventBus.has_signal("grave_state_changed"), "grave state signal exists")
	_assert_true(EventBus.has_signal("enemy_state_changed"), "enemy population signal exists")
	_assert_true(EventBus.has_signal("time_state_changed"), "time-cycle signal exists")
	_assert_true(EventBus.has_signal("milestone_state_changed"), "milestone progression signal exists")
	_assert_true(EventBus.has_signal("save_status_changed"), "save status signal exists")


func _test_settings_round_trip() -> void:
	var original: Variant = SettingsManager.get_value("accessibility/reduce_motion", false)
	SettingsManager.set_value("accessibility/reduce_motion", not bool(original), false)
	_assert_equal(SettingsManager.get_value("accessibility/reduce_motion"), not bool(original), "settings mutate")
	SettingsManager.set_value("accessibility/reduce_motion", original, false)
	_assert_true(SettingsManager.save_settings(), "settings save")


func _test_scene_transition_contract() -> void:
	_assert_true(ResourceLoader.exists(GameManager.MAIN_MENU_SCENE), "manager main scene path")
	_assert_true(ResourceLoader.exists(GameManager.GAME_SCENE), "manager game scene path")


func _test_player_motor_frame_independence() -> void:
	var direction := Vector2(1.0, 0.35)
	var at_30 := PlayerMotor.integrated_distance(direction, false, 30, 1.0)
	var at_60 := PlayerMotor.integrated_distance(direction, false, 60, 1.0)
	var at_120 := PlayerMotor.integrated_distance(direction, false, 120, 1.0)
	_assert_true(at_30.is_equal_approx(at_60) and at_60.is_equal_approx(at_120), "movement is frame-rate independent at 30/60/120 FPS")
	_assert_true(is_equal_approx(PlayerMotor.velocity_for(Vector2.ONE, false).length(), PlayerMotor.WALK_SPEED), "diagonal movement is normalized")
	_assert_true(PlayerMotor.velocity_for(Vector2.RIGHT, true).length() > PlayerMotor.velocity_for(Vector2.RIGHT, false).length(), "run speed exceeds walk speed")


func _test_world_seed_contract() -> void:
	var stable_seed := WorldSeed.from_text("无尽边境")
	_assert_equal(stable_seed, 6266252184503203218, "text seed has a platform-stable fixture")
	_assert_equal(WorldSeed.from_text("无尽边境"), stable_seed, "same text produces same 64-bit seed")
	_assert_equal(WorldSeed.from_text("-42"), -42, "numeric text preserves numeric seed")
	_assert_true(WorldSeed.derive(stable_seed, &"elevation") != WorldSeed.derive(stable_seed, &"detail"), "derived systems use independent seeds")
	_assert_true(WorldSeed.for_chunk(stable_seed, &"surface", Vector2i(-1, -1), &"terrain") != WorldSeed.for_chunk(stable_seed, &"surface", Vector2i(0, -1), &"terrain"), "coordinate seeds include signed chunk coordinates")


func _test_world_coordinate_contract() -> void:
	_assert_equal(WorldCoordinates.tile_to_chunk(Vector2i(31, 31)), Vector2i(0, 0), "positive tile maps to origin chunk")
	_assert_equal(WorldCoordinates.tile_to_chunk(Vector2i(-1, -1)), Vector2i(-1, -1), "negative edge maps with floor division")
	_assert_equal(WorldCoordinates.tile_to_chunk(Vector2i(-33, 64)), Vector2i(-2, 2), "negative multi-chunk coordinate maps correctly")
	_assert_equal(WorldCoordinates.tile_to_local(Vector2i(-1, -33)), Vector2i(31, 31), "negative tile has positive local coordinate")
	var tile := Vector2i(-65, 97)
	_assert_equal(WorldCoordinates.chunk_local_to_tile(WorldCoordinates.tile_to_chunk(tile), WorldCoordinates.tile_to_local(tile)), tile, "chunk/local conversion round trips")
	_assert_equal(WorldCoordinates.chunk_key(&"surface", Vector2i(-2, 3)), "surface_-2_3", "chunk key preserves layer and signs")


func _test_biome_catalog_contract() -> void:
	var catalog := BiomeCatalog.new()
	_assert_true(catalog.is_valid(), "external biome configuration loads and validates")
	_assert_equal(catalog.biome_count(), 9, "catalog contains six land biomes plus coast and two ocean depths")
	for biome_id in BiomeCatalog.REQUIRED_IDS:
		_assert_true(catalog.has_biome(biome_id), "catalog contains stable biome ID %s" % biome_id)
	_assert_true(catalog.threshold("deep_water") < catalog.threshold("shallow_water") and catalog.threshold("shallow_water") < catalog.threshold("coast"), "data-driven terrain thresholds are ordered")
	_assert_equal(catalog.classify_land(0.12, 0.50, 0.52, 0.50), catalog.code_for_id(&"snowfield"), "temperature rule selects snowfield")
	_assert_equal(catalog.classify_land(0.80, 0.12, 0.52, 0.50), catalog.code_for_id(&"desert"), "hot dry rule selects desert")
	_assert_equal(catalog.classify_land(0.62, 0.82, 0.52, 0.50), catalog.code_for_id(&"swamp"), "warm wet lowland rule selects swamp")
	_assert_equal(catalog.classify_land(0.52, 0.78, 0.64, 0.72), catalog.code_for_id(&"forest"), "wet rule selects forest outside swamp")
	_assert_equal(catalog.classify_land(0.52, 0.42, 0.82, 0.40), catalog.code_for_id(&"mountain"), "high low-erosion rule selects mountain")
	_assert_equal(catalog.classify_land(0.70, 0.30, 0.52, 0.50), catalog.code_for_id(&"plains"), "transition band routes a biome edge through plains")


func _test_resource_catalog_contract() -> void:
	var catalog := ResourceCatalog.new()
	_assert_true(catalog.is_valid(), "external resource configuration loads and validates")
	_assert_equal(catalog.resource_count(), 5, "resource catalog contains tree, rock, grass, flower and berry bush")
	for resource_id in ResourceCatalog.REQUIRED_RESOURCE_IDS:
		_assert_true(catalog.has_resource(resource_id), "catalog contains stable resource ID %s" % resource_id)
	_assert_equal(catalog.tool_ids(), [&"hands", &"axe", &"pickaxe"], "tool order is data-driven and stable")
	_assert_equal(catalog.required_tool_for_code(catalog.code_for_id(&"tree")), &"axe", "trees require an axe")
	_assert_equal(catalog.required_tool_for_code(catalog.code_for_id(&"rock")), &"pickaxe", "rocks require a pickaxe")
	_assert_true(catalog.candidate_code_for_biome(&"deep_ocean", 0.0) < 0, "deep ocean has no resource rule")
	_assert_true(catalog.drop_pool_capacity() == 32 and catalog.max_resources_per_chunk() == 128, "resource and drop limits come from configuration")


func _test_item_catalog_contract() -> void:
	var catalog := ItemCatalog.new()
	_assert_true(catalog.is_valid(), "external item configuration loads and validates")
	_assert_equal(catalog.slot_count(), 24, "inventory capacity is data-driven at 24 slots")
	_assert_equal(catalog.hotbar_slot_count(), 8, "hotbar exposes the first eight inventory slots")
	var ids := catalog.item_ids()
	_assert_equal(ids.size(), 20, "item catalog contains 20 unique material, enemy-drop, tool, station, food, utility and reward IDs")
	for item_id in ItemCatalog.REQUIRED_ITEM_IDS:
		_assert_true(ids.has(StringName(item_id)), "item catalog contains stable unique ID %s" % item_id)
	_assert_equal(catalog.category_name(&"wood"), "材料", "wood exposes its item category")
	_assert_equal(catalog.category_name(&"berry"), "食物", "berry exposes its item category")
	_assert_true(catalog.maximum_stack(&"wood") == 50 and catalog.maximum_stack(&"berry") == 20, "stack limits come from item data resources")
	_assert_true(catalog.tool_kind(&"wood_axe") == &"axe" and catalog.tool_power(&"stone_axe") == 2, "wood and stone tool kinds/power are data-driven")
	_assert_true(catalog.maximum_durability(&"wood_pickaxe") == 30 and catalog.maximum_durability(&"stone_pickaxe") == 60, "tool durability comes from item resources")
	_assert_true(catalog.station_kind(&"workbench") == &"workbench" and catalog.station_kind(&"campfire") == &"campfire", "workbench and campfire are stable station items")
	_assert_true(catalog.maximum_stack(&"slime_gel") == 50 and catalog.has_item(&"wolf_pelt") and catalog.has_item(&"bat_wing"), "enemy drops are stable stackable item IDs")
	_assert_true(catalog.maximum_stack(&"ancient_core") == 10 and catalog.category_name(&"ancient_core") == "奖励", "Boss reward is a stable stackable item ID")


func _test_inventory_model() -> void:
	var inventory := InventoryModel.new()
	var wood_result := inventory.add_item(&"wood", 55)
	_assert_true(int(wood_result["accepted"]) == 55 and int(wood_result["remainder"]) == 0, "inventory accepts a quantity across stack boundaries")
	_assert_true(int(inventory.slot(0)["quantity"]) == 50 and int(inventory.slot(1)["quantity"]) == 5, "wood stacks at its exact configured limit")
	inventory.add_item(&"stone", 3)
	var before_drag := inventory.count_snapshot()
	_assert_true(inventory.move_or_swap(1, 2), "drag operation swaps unlike occupied stacks")
	_assert_equal(inventory.count_snapshot(), before_drag, "drag swap preserves every item and quantity")
	_assert_true(inventory.split_stack(0, 3), "right-click split moves half a stack to an empty slot")
	_assert_true(int(inventory.slot(0)["quantity"]) == 25 and int(inventory.slot(3)["quantity"]) == 25, "stack split quantities are exact")
	_assert_true(inventory.move_or_swap(2, 3), "dragging like items combines into available stack space")
	_assert_equal(inventory.quantity(&"wood"), 55, "combine and split never duplicate or lose wood")
	_assert_true(inventory.select_hotbar(7), "eighth hotbar slot can be selected")
	var exact_snapshot := inventory.snapshot()
	var exact_checksum := inventory.checksum()
	var restored := InventoryModel.new()
	_assert_true(restored.restore_snapshot(exact_snapshot), "versioned slot snapshot validates and restores")
	_assert_equal(restored.snapshot(), exact_snapshot, "save/load restores identical slot order and quantities")
	_assert_equal(restored.checksum(), exact_checksum, "save/load inventory checksum is byte-stable")
	var removed := restored.discard(3, 7)
	_assert_true(String(removed.get("item_id", "")) == "wood" and int(removed.get("quantity", 0)) == 7, "discard returns the exact removed item stack")
	_assert_equal(restored.quantity(&"wood"), 48, "discard decrements the source without duplication")
	var counts_before_sort := restored.count_snapshot()
	restored.sort_inventory()
	_assert_equal(restored.count_snapshot(), counts_before_sort, "inventory sort preserves all item totals")
	var full_inventory := InventoryModel.new()
	var fill_result := full_inventory.add_item(&"wood", 24 * 50)
	var overflow := full_inventory.add_item(&"stone", 1)
	_assert_true(int(fill_result["remainder"]) == 0 and bool(overflow["full"]) and int(overflow["remainder"]) == 1, "full inventory returns an explicit unaccepted remainder")
	var invalid_snapshot := exact_snapshot.duplicate(true)
	(invalid_snapshot["slots"] as Array)[0] = {"item_id": "wood", "quantity": 51}
	_assert_true(not InventoryModel.new().restore_snapshot(invalid_snapshot), "invalid over-limit stack is rejected instead of silently coerced")
	var migrated := InventoryModel.new()
	_assert_true(migrated.restore_legacy_counts({"wood": 7, "stone": 3}), "V0.7 count dictionary migrates into V0.8 slots")
	_assert_true(migrated.quantity(&"wood") == 7 and migrated.quantity(&"stone") == 3, "legacy migration preserves exact item totals")


func _test_recipe_catalog_contract() -> void:
	var catalog := RecipeCatalog.new()
	_assert_true(catalog.is_valid(), "external recipe configuration loads and validates")
	_assert_equal(catalog.station_ids(), [&"hands", &"workbench", &"campfire"], "hands, workbench and campfire stations are data-driven")
	_assert_equal(catalog.recipes().size(), 10, "recipe catalog contains wooden/stone tools, stations, torch and food")
	_assert_true(catalog.recipe(&"wood_axe") != null and catalog.recipe(&"stone_pickaxe") != null, "wooden and stone tool recipes use stable IDs")
	_assert_true(catalog.recipe(&"torch").output_quantity == 2, "torch recipe produces its configured output quantity")


func _test_crafting_system() -> void:
	var inventory := InventoryModel.new()
	inventory.add_item(&"branch", 2)
	inventory.add_item(&"fiber", 2)
	var crafting := CraftingSystem.new(inventory)
	crafting.refresh_discoveries()
	_assert_true(crafting.is_unlocked(&"wood_axe"), "discovering branch and fiber unlocks the wooden axe recipe")
	var before_insufficient := inventory.snapshot()
	var insufficient := crafting.craft(&"wood_axe")
	_assert_true(not bool(insufficient["ok"]) and "材料不足" in String(insufficient["message"]), "insufficient materials prevent crafting with an explicit reason")
	_assert_equal(inventory.snapshot(), before_insufficient, "failed crafting consumes no materials")
	inventory.add_item(&"branch", 1)
	var crafted_wood := crafting.craft(&"wood_axe")
	_assert_true(bool(crafted_wood["ok"]), "hands crafting creates a wooden axe after requirements are met")
	_assert_true(inventory.quantity(&"branch") == 0 and inventory.quantity(&"fiber") == 0, "successful crafting deducts the exact wooden-axe materials")
	var wood_axe_slot := _find_item_slot(inventory, &"wood_axe")
	_assert_true(wood_axe_slot >= 0 and int(inventory.slot(wood_axe_slot)["durability"]) == 30, "crafted wooden axe starts at full durability")
	_assert_true(not crafting.station_available(&"workbench") and not crafting.is_unlocked(&"stone_axe"), "stone tools stay locked without a workbench")
	inventory.add_item(&"workbench", 1)
	inventory.add_item(&"branch", 10)
	inventory.add_item(&"stone", 10)
	inventory.add_item(&"fiber", 10)
	crafting.refresh_discoveries()
	_assert_true(crafting.station_available(&"workbench") and crafting.is_unlocked(&"stone_axe"), "possessing a workbench and discovering stone unlocks stone tools")
	var branch_before := inventory.quantity(&"branch")
	var stone_before := inventory.quantity(&"stone")
	var fiber_before := inventory.quantity(&"fiber")
	_assert_true(bool(crafting.craft(&"stone_axe")["ok"]), "workbench crafts a stone axe")
	_assert_true(inventory.quantity(&"branch") == branch_before - 2 and inventory.quantity(&"stone") == stone_before - 4 and inventory.quantity(&"fiber") == fiber_before - 2, "stone axe deducts every material exactly once")
	var stone_axe_slot := _find_item_slot(inventory, &"stone_axe")
	_assert_true(stone_axe_slot >= 0 and int(inventory.slot(stone_axe_slot)["durability"]) == 60, "crafted stone axe starts at full durability")
	inventory.add_item(&"campfire", 1)
	inventory.add_item(&"berry", 3)
	crafting.refresh_discoveries()
	_assert_true(crafting.station_available(&"campfire") and bool(crafting.craft(&"cooked_berries")["ok"]), "campfire crafts the basic cooked-berry food")
	_assert_true(inventory.quantity(&"berry") == 0 and inventory.quantity(&"cooked_berries") == 1, "basic food recipe deducts berries and adds one output")
	var unlock_snapshot := crafting.persistence_snapshot()
	var restored_unlocks := CraftingSystem.new(InventoryModel.new())
	_assert_true(restored_unlocks.restore_snapshot(unlock_snapshot) and restored_unlocks.is_unlocked(&"wood_axe"), "discovery unlock conditions persist after materials are spent")
	var full_inventory := InventoryModel.new()
	for _index in 22:
		full_inventory.add_item(&"wood_sword", 1)
	full_inventory.add_item(&"wood", 50)
	full_inventory.add_item(&"fiber", 50)
	var full_crafting := CraftingSystem.new(full_inventory)
	full_crafting.refresh_discoveries()
	var full_counts := full_inventory.count_snapshot()
	var no_space := full_crafting.craft(&"torch")
	_assert_true(not bool(no_space["ok"]) and "空间不足" in String(no_space["message"]), "crafting rejects an output when no slot can receive it")
	_assert_equal(full_inventory.count_snapshot(), full_counts, "no-space crafting transaction deducts nothing")


func _test_tool_speed_and_durability() -> void:
	var resource_catalog := ResourceCatalog.new()
	var tree_code := resource_catalog.code_for_id(&"tree")
	var wood_state := ResourceHarvestState.new()
	var stone_state := ResourceHarvestState.new()
	var wood_hit := wood_state.hit("100:100:%d" % tree_code, tree_code, &"axe", resource_catalog, 1)
	var stone_hit := stone_state.hit("101:100:%d" % tree_code, tree_code, &"axe", resource_catalog, 2)
	_assert_true(int(wood_hit["remaining"]) == 2 and int(stone_hit["remaining"]) == 1, "stone tool power harvests the same resource faster than wood")
	var inventory := InventoryModel.new()
	inventory.add_item(&"wood_axe", 1)
	var tool_slot := _find_item_slot(inventory, &"wood_axe")
	for _index in 29:
		inventory.damage_tool_at(tool_slot, 1)
	_assert_equal(int(inventory.slot(tool_slot)["durability"]), 1, "tool durability decrements exactly once per accepted use")
	var broken := inventory.damage_tool_at(tool_slot, 1)
	_assert_true(bool(broken["broken"]) and inventory.slot(tool_slot).is_empty(), "tool is removed cleanly when durability reaches zero")
	var sort_inventory := InventoryModel.new()
	sort_inventory.add_item(&"stone_pickaxe", 1)
	var pickaxe_slot := _find_item_slot(sort_inventory, &"stone_pickaxe")
	sort_inventory.damage_tool_at(pickaxe_slot, 7)
	sort_inventory.add_item(&"wood", 4)
	sort_inventory.sort_inventory()
	pickaxe_slot = _find_item_slot(sort_inventory, &"stone_pickaxe")
	_assert_equal(int(sort_inventory.slot(pickaxe_slot)["durability"]), 53, "inventory sorting preserves individual tool durability")


func _test_weapon_catalog_contract() -> void:
	var catalog := WeaponCatalog.new()
	_assert_true(catalog.is_valid(), "external weapon configuration loads and validates")
	_assert_equal(catalog.weapon_ids(), [&"unarmed", &"wood_sword", &"stone_sword"], "weapon IDs are unique, stable and data-driven")
	var unarmed := catalog.weapon(&"unarmed")
	var wooden := catalog.weapon(&"wood_sword")
	var stone := catalog.weapon(&"stone_sword")
	_assert_true(unarmed != null and wooden != null and stone != null, "unarmed, wooden sword and stone sword definitions exist")
	_assert_true(stone.damage > wooden.damage and wooden.damage > unarmed.damage, "weapon damage progression increases by material tier")
	_assert_true(stone.attack_range > unarmed.attack_range and stone.knockback > wooden.knockback, "weapon range and knockback come from weapon data")
	_assert_equal(stone.combo_count(), 3, "stone sword exposes the planned three-hit combo")


func _test_attack_sequence_and_damage() -> void:
	var definition := WeaponCatalog.new().weapon(&"wood_sword")
	var sequence := AttackSequenceModel.new()
	var first := sequence.request_attack(definition, Vector2.RIGHT)
	_assert_true(bool(first["ok"]) and int(first["combo_index"]) == 1, "normal attack starts the first combo step")
	_assert_true((first["direction"] as Vector2).is_equal_approx(Vector2.RIGHT), "attack direction follows normalized player facing")
	_assert_true((first["hitbox_position"] as Vector2).is_equal_approx(Vector2(definition.attack_range * 0.5, 0.0)) and is_zero_approx(float(first["hitbox_rotation"])), "directional hitbox is centered in front of the player")
	_assert_true(sequence.register_target_hit(101), "active attack accepts its first target hit")
	_assert_true(not sequence.register_target_hit(101), "same attack cannot hit the same target twice")
	_assert_true(not bool(sequence.request_attack(definition, Vector2.RIGHT)["ok"]), "attack cooldown rejects an early repeated input")
	sequence.tick(definition.cooldown() + 0.01)
	var second := sequence.request_attack(definition, Vector2.DOWN)
	_assert_true(bool(second["ok"]) and int(second["combo_index"]) == 2, "attack inside the combo window advances the chain")
	_assert_true(sequence.register_target_hit(101), "new attack ID may hit the same target again")
	sequence.tick(AttackSequenceModel.COMBO_RESET_SECONDS + 0.01)
	var reset := sequence.request_attack(definition, Vector2.LEFT)
	_assert_true(bool(reset["ok"]) and int(reset["combo_index"]) == 1, "expired combo window resets to the first attack")
	_assert_equal(DamageCalculator.calculate(20.0, 5.0), 17, "damage formula applies the documented defense coefficient")
	_assert_equal(DamageCalculator.calculate(2.0, 999.0), 1, "defense calculation preserves minimum one damage")


func _test_player_combat_state_and_graves() -> void:
	var combat := PlayerCombatState.new()
	combat.defense = 5.0
	combat.respawn_position = Vector2(-64.0, 96.0)
	var first_hit := combat.apply_hit(30.0, 100.0, 20.0, Vector2.RIGHT, 180.0)
	_assert_true(bool(first_hit["accepted"]) and int(first_hit["damage"]) == 17 and float(first_hit["health"]) == 13.0, "incoming hit applies attack, defense and health exactly")
	_assert_equal(first_hit["knockback"], Vector2(180.0, 0.0), "accepted hit applies directional knockback")
	var blocked := combat.apply_hit(13.0, 100.0, 20.0, Vector2.RIGHT, 180.0)
	_assert_true(not bool(blocked["accepted"]), "hit invulnerability rejects overlapping damage")
	combat.tick(PlayerCombatState.HIT_INVULNERABILITY_SECONDS + 0.01)
	var lethal := combat.apply_hit(13.0, 100.0, 99.0, Vector2.LEFT, 0.0)
	_assert_true(bool(lethal["died"]) and combat.status == &"dead" and combat.death_count == 1, "lethal damage enters death state exactly once")
	combat.respawn()
	_assert_true(combat.status == &"alive" and combat.invulnerability_remaining > 0.0, "respawn restores alive state with protection")
	var combat_snapshot := combat.persistence_snapshot()
	var restored_combat := PlayerCombatState.new()
	_assert_true(restored_combat.restore_snapshot(combat_snapshot) and restored_combat.persistence_snapshot() == combat_snapshot, "combat status round trip preserves defense, deaths and respawn position")
	var inventory := InventoryModel.new()
	inventory.add_item(&"wood", 7)
	inventory.add_item(&"stone_sword", 1)
	var sword_slot := _find_item_slot(inventory, &"stone_sword")
	inventory.damage_tool_at(sword_slot, 9)
	var graves := GraveModel.new()
	var grave := graves.deposit(Vector2(-128.0, 256.0), inventory)
	_assert_true(not grave.is_empty() and inventory.is_empty() and graves.grave_count() == 1, "death deposit moves the complete inventory into one grave")
	var grave_snapshot := graves.persistence_snapshot()
	var restored_graves := GraveModel.new()
	_assert_true(restored_graves.restore_snapshot(grave_snapshot), "grave state validates and restores")
	_assert_equal(int(restored_graves.nearest_grave(Vector2(-130.0, 255.0), 8.0)["id"]), int(grave["id"]), "nearest grave uses world-space distance")
	var reclaimed_inventory := InventoryModel.new()
	var reclaimed := restored_graves.reclaim(int(grave["id"]), reclaimed_inventory)
	var reclaimed_sword_slot := _find_item_slot(reclaimed_inventory, &"stone_sword")
	_assert_true(bool(reclaimed["complete"]) and restored_graves.grave_count() == 0, "grave reclaim removes a fully recovered grave")
	_assert_true(reclaimed_inventory.quantity(&"wood") == 7 and int(reclaimed_inventory.slot(reclaimed_sword_slot)["durability"]) == 71, "grave reclaim preserves exact item counts and weapon durability")


func _test_enemy_catalog_and_state_machine() -> void:
	var catalog := EnemyCatalog.new()
	_assert_true(catalog.is_valid(), "external enemy configuration loads and validates")
	_assert_equal(catalog.enemy_ids(), [&"slime", &"wolf", &"cave_bat"], "enemy IDs are unique, stable and data-driven")
	_assert_true(catalog.maximum_active() == 18 and catalog.maximum_per_chunk() == 3, "enemy population hard limits come from data")
	_assert_true(catalog.enemy(&"slime").biomes == [&"plains", &"forest"], "slime biome rule is explicit")
	_assert_true(catalog.enemy(&"wolf").biomes.has(&"forest") and catalog.enemy(&"wolf").biomes.has(&"snowfield"), "wolf forest and snowfield rules are explicit")
	_assert_equal(catalog.enemy(&"cave_bat").biomes, [&"mountain"], "cave bat uses the surface mountain rule until caves exist")
	_assert_equal(catalog.enemy_id_for_biome(&"desert", 0.5), &"", "unsupported biome produces no enemy type")
	var slime := catalog.enemy(&"slime")
	var machine := EnemyStateMachine.new(slime)
	machine.tick(EnemyStateMachine.IDLE_DURATION + 0.01, 999.0, 0.0)
	_assert_equal(machine.state_name(), &"WANDER", "enemy state machine enters deterministic wander")
	machine.tick(0.01, slime.detection_range - 1.0, 0.0)
	_assert_equal(machine.state_name(), &"ALERT", "nearby player moves enemy into alert")
	machine.tick(EnemyStateMachine.ALERT_DURATION + 0.01, slime.detection_range - 1.0, 0.0)
	_assert_equal(machine.state_name(), &"CHASE", "alert transitions into chase")
	machine.tick(0.01, slime.attack_range - 1.0, 0.0)
	_assert_equal(machine.state_name(), &"ATTACK", "chase enters attack at configured range")
	var attack_result := machine.tick(slime.attack_windup + 0.01, slime.attack_range - 1.0, 0.0)
	_assert_true(bool(attack_result["attack_ready"]) and machine.cooldown_remaining > 0.0, "enemy attack triggers once after its windup and starts cooldown")
	var duplicate_attack := machine.tick(0.01, slime.attack_range - 1.0, 0.0)
	_assert_true(not bool(duplicate_attack["attack_ready"]), "one attack state cannot damage twice")
	machine.tick(slime.attack_recovery + 0.01, slime.attack_range + 10.0, 0.0)
	machine.hurt()
	_assert_equal(machine.state_name(), &"HURT", "accepted player hit enters enemy hurt state")
	machine.tick(EnemyStateMachine.HURT_DURATION + 0.01, 999.0, slime.return_distance + 1.0)
	_assert_equal(machine.state_name(), &"RETURN", "hurt enemy outside its activity area returns home")
	machine.tick(0.01, 999.0, 0.0)
	_assert_equal(machine.state_name(), &"IDLE", "return completes at the home position")
	machine.die()
	machine.tick(10.0, 0.0, 0.0)
	_assert_equal(machine.state_name(), &"DEAD", "dead is a terminal enemy state")
	var first_drops := catalog.resolve_drops(&"wolf", "fixture:wolf:1")
	var second_drops := catalog.resolve_drops(&"wolf", "fixture:wolf:1")
	_assert_equal(first_drops, second_drops, "enemy drops are deterministic for a stable spawn ID")
	_assert_true(not first_drops.is_empty() and StringName(first_drops[0]["item_id"]) == &"wolf_pelt" and int(first_drops[0]["quantity"]) >= 1 and int(first_drops[0]["quantity"]) <= 2, "wolf death resolves a bounded canonical drop")


func _test_enemy_spawn_planner() -> void:
	var seed := WorldSeed.from_text("enemy-planner-fixture")
	var catalog := EnemyCatalog.new()
	var first := EnemySpawnPlanner.new(seed, catalog)
	var second := EnemySpawnPlanner.new(seed, catalog)
	var biome_catalog := BiomeCatalog.new()
	var terrain := TerrainGenerator.new(seed)
	var seen_ids := {}
	var seen_spawn_ids := {}
	var candidate_total := 0
	var deterministic := true
	var per_chunk_bounded := true
	var unique_ids := true
	var land_only := true
	var biome_correct := true
	for chunk_y in range(-10, 11):
		for chunk_x in range(-10, 11):
			var coordinate := Vector2i(chunk_x, chunk_y)
			var first_candidates := first.candidates_for_chunk(coordinate)
			var second_candidates := second.candidates_for_chunk(coordinate)
			deterministic = deterministic and first_candidates == second_candidates
			per_chunk_bounded = per_chunk_bounded and first_candidates.size() <= catalog.maximum_per_chunk()
			for candidate in first_candidates:
				candidate_total += 1
				var spawn_id := String(candidate["spawn_id"])
				var enemy_id := candidate["enemy_id"] as StringName
				var world_tile := candidate["world_tile"] as Vector2i
				var biome_id := biome_catalog.id_for_code(terrain.biome_at(world_tile))
				seen_ids[enemy_id] = true
				unique_ids = unique_ids and not seen_spawn_ids.has(spawn_id)
				seen_spawn_ids[spawn_id] = true
				land_only = land_only and terrain.terrain_at(world_tile) == ChunkData.Terrain.LAND
				biome_correct = biome_correct and catalog.enemy(enemy_id).biomes.has(biome_id)
	_assert_true(deterministic, "enemy candidates are deterministic across planner restarts")
	_assert_true(per_chunk_bounded, "enemy candidates obey the per-chunk cap")
	_assert_true(unique_ids, "enemy spawn IDs stay unique across signed chunks")
	_assert_true(land_only, "enemy candidates never appear in water")
	_assert_true(biome_correct, "enemy candidates match data-driven biome rules")
	_assert_true(candidate_total > 0, "broad deterministic region contains enemy candidates")
	_assert_true(seen_ids.has(&"slime") and seen_ids.has(&"wolf") and seen_ids.has(&"cave_bat"), "broad deterministic region contains all three planned enemy types")
	first.retain_chunks([Vector2i.ZERO])
	_assert_equal(first.cache_size(), 1, "enemy candidate cache is pruned to the retained chunk set")


func _test_milestone_models() -> void:
	var catalog := MilestoneCatalog.new()
	_assert_true(catalog.is_valid(), "external milestone configuration loads and validates")
	_assert_true(catalog.reward_item_id() == &"ancient_core" and catalog.reward_quantity() == 1, "canonical Boss reward is data-driven")
	var cycle := DayNightCycle.new(0.0)
	_assert_equal(cycle.snapshot()["phase"], &"DAY", "new world begins in the basic daytime phase")
	cycle.advance(DayNightCycle.CYCLE_SECONDS * DayNightCycle.DAY_FRACTION + 0.01)
	_assert_equal(cycle.snapshot()["phase"], &"NIGHT", "basic cycle reaches the night phase deterministically")
	cycle.advance(DayNightCycle.CYCLE_SECONDS * (1.0 - DayNightCycle.DAY_FRACTION))
	_assert_equal(int(cycle.snapshot()["day"]), 2, "day counter advances after one complete cycle")
	var state := MilestoneState.new()
	_assert_true(state.discover_ruin() and state.defeat_boss() and state.claim_reward(), "milestone state completes discover, Boss and reward sequence")
	var restored := MilestoneState.new()
	_assert_true(restored.restore_snapshot(state.persistence_snapshot()) and restored.reward_claimed, "milestone progression round trips exactly")
	var invalid := MilestoneState.new()
	_assert_true(not invalid.restore_snapshot({"schema_version": 1, "ruin_discovered": false, "boss_defeated": false, "reward_claimed": true}), "milestone validation rejects reward-before-Boss state")
	var seed := WorldSeed.from_text("V1.0-ruin-fixture")
	var first := RuinPlanner.new(seed, catalog).plan()
	var second := RuinPlanner.new(seed, catalog).plan()
	_assert_equal(first, second, "canonical ruin is deterministic across planner restarts")
	var ruin_tile := first.get("world_tile", Vector2i.ZERO) as Vector2i
	var terrain := TerrainGenerator.new(seed)
	_assert_equal(terrain.terrain_at(ruin_tile), ChunkData.Terrain.LAND, "canonical ruin always occupies land")
	var ruin_chunk := first.get("chunk", Vector2i.ZERO) as Vector2i
	var radius := ChunkStreamPlanner.chebyshev_distance(ruin_chunk, RuinPlanner.ORIGIN_CHUNK)
	_assert_true(radius >= 3 and radius <= 6, "canonical ruin stays inside the planned discovery ring")
	var tone := AudioCuePlayer.synthesize_tone(440.0)
	_assert_true(tone.data.size() > 100 and tone.mix_rate == AudioCuePlayer.SAMPLE_RATE, "procedural basic sound cue contains valid PCM samples")


func _test_deterministic_generation() -> void:
	var seed := WorldSeed.from_text("无尽边境")
	var first_generator := TerrainGenerator.new(seed)
	var showcase_chunk := Vector2i(-1, -4)
	var first := first_generator.generate_chunk(showcase_chunk)
	var repeated := TerrainGenerator.new(seed).generate_chunk(showcase_chunk)
	_assert_equal(first.checksum, repeated.checksum, "same seed and coordinate survive generator restart")
	_assert_true(first.base_tiles == repeated.base_tiles, "deterministic tile bytes match exactly")
	_assert_equal(first.base_tiles.size(), 1024, "chunk contains 32×32 base tiles")
	_assert_equal(first.continental_map.size(), 1024, "chunk contains 32×32 continental samples")
	_assert_equal(first.elevation_map.size(), 1024, "chunk contains 32×32 elevation samples")
	_assert_equal(first.erosion_map.size(), 1024, "chunk contains 32×32 erosion samples")
	_assert_equal(first.temperature_map.size(), 1024, "chunk contains 32×32 temperature samples")
	_assert_equal(first.moisture_map.size(), 1024, "chunk contains 32×32 moisture samples")
	_assert_equal(first.biome_map.size(), 1024, "chunk contains 32×32 biome samples")
	_assert_equal(first.checksum, "25b17b18822faa6c", "generation v4 checksum fixture remains stable")
	var other_seed := TerrainGenerator.new(WorldSeed.from_text("另一片边境")).generate_chunk(showcase_chunk)
	_assert_true(first.checksum != other_seed.checksum, "different seeds produce different chunks")
	var chunk_a := Vector2i(-3, 2)
	var chunk_b := Vector2i(4, -5)
	var order_one := TerrainGenerator.new(seed)
	var a_then_b_a := order_one.generate_chunk(chunk_a).checksum
	var a_then_b_b := order_one.generate_chunk(chunk_b).checksum
	var order_two := TerrainGenerator.new(seed)
	var b_then_a_b := order_two.generate_chunk(chunk_b).checksum
	var b_then_a_a := order_two.generate_chunk(chunk_a).checksum
	_assert_true(a_then_b_a == b_then_a_a and a_then_b_b == b_then_a_b, "chunk generation is independent of request order")
	var counts := first.terrain_counts()
	_assert_equal(counts[0] + counts[1] + counts[2] + counts[3], 1024, "terrain histogram accounts for every tile")
	var represented_types := 0
	for count in counts:
		if count > 0:
			represented_types += 1
	if represented_types < 2:
		var nearby_counts := PackedInt32Array([0, 0, 0, 0])
		for offset_y in range(-1, 2):
			for offset_x in range(-1, 2):
				var nearby := first_generator.generate_chunk(showcase_chunk + Vector2i(offset_x, offset_y)).terrain_counts()
				for terrain_index in nearby_counts.size():
					nearby_counts[terrain_index] += nearby[terrain_index]
		represented_types = 0
		for count in nearby_counts:
			represented_types += 1 if count > 0 else 0
	_assert_true(represented_types >= 2, "start region contains a visible terrain transition")
	var isolated_tiles := 0
	for y in range(1, WorldCoordinates.CHUNK_SIZE - 1):
		for x in range(1, WorldCoordinates.CHUNK_SIZE - 1):
			var local := Vector2i(x, y)
			var terrain := first.tile_at(local)
			var matching_neighbors := 0
			for offset_y in range(-1, 2):
				for offset_x in range(-1, 2):
					if offset_x == 0 and offset_y == 0:
						continue
					if first.tile_at(local + Vector2i(offset_x, offset_y)) == terrain:
						matching_neighbors += 1
			if matching_neighbors == 0:
				isolated_tiles += 1
	_assert_equal(isolated_tiles, 0, "coast cleanup removes isolated single-tile noise")


func _test_biome_regions() -> void:
	var catalog := BiomeCatalog.new()
	var generator := TerrainGenerator.new(WorldSeed.from_text("无尽边境"))
	var broad_counts := PackedInt32Array()
	broad_counts.resize(catalog.biome_count())
	for y in range(-2048, 2049, 64):
		for x in range(-2048, 2049, 64):
			broad_counts[generator.biome_at(Vector2i(x, y))] += 1
	for biome_code in catalog.biome_count():
		_assert_true(broad_counts[biome_code] > 0, "broad deterministic scan contains %s" % catalog.display_name_for_code(biome_code))
	var origin := Vector2i(-96, -144)
	var side := 96
	var cells := PackedByteArray()
	cells.resize(side * side)
	for y in side:
		for x in side:
			cells[y * side + x] = generator.biome_at(origin + Vector2i(x, y))
	var matching_edges := 0
	var total_edges := 0
	var isolated_cells := 0
	for y in side:
		for x in side:
			var biome_code := cells[y * side + x]
			if x + 1 < side:
				total_edges += 1
				matching_edges += 1 if biome_code == cells[y * side + x + 1] else 0
			if y + 1 < side:
				total_edges += 1
				matching_edges += 1 if biome_code == cells[(y + 1) * side + x] else 0
			if x > 0 and y > 0 and x + 1 < side and y + 1 < side:
				var matching_neighbors := 0
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					matching_neighbors += 1 if biome_code == cells[(y + offset.y) * side + x + offset.x] else 0
				isolated_cells += 1 if matching_neighbors == 0 else 0
	_assert_true(float(matching_edges) / float(total_edges) > 0.90, "biomes form large continuous regions instead of random fragments")
	_assert_true(isolated_cells <= 4, "biome transition cleanup limits isolated single cells")


func _test_resource_generation() -> void:
	var seed := WorldSeed.from_text("无尽边境")
	var generator := TerrainGenerator.new(seed)
	var catalog := ResourceCatalog.new()
	var chunks: Array[ChunkData] = []
	var represented := PackedInt32Array()
	represented.resize(catalog.resource_count())
	var keys := {}
	var water_safe := true
	var capped := true
	for chunk_y in range(-5, 0):
		for chunk_x in range(-3, 2):
			var chunk := generator.generate_chunk(Vector2i(chunk_x, chunk_y))
			chunks.append(chunk)
			capped = capped and chunk.resource_count() <= catalog.max_resources_per_chunk()
			for index in chunk.resource_count():
				var local := chunk.resource_local_at(index)
				var terrain := chunk.tile_at(local)
				water_safe = water_safe and terrain != ChunkData.Terrain.DEEP_WATER and terrain != ChunkData.Terrain.SHALLOW_WATER
				represented[chunk.resource_code_at(index)] += 1
				keys[chunk.resource_key_at(index)] = true
	_assert_true(water_safe, "resources never spawn in deep or shallow water")
	_assert_true(capped, "resource counts remain under the configured per-chunk limit")
	for resource_code in catalog.resource_count():
		_assert_true(represented[resource_code] > 0, "deterministic region contains %s" % catalog.display_name_for_code(resource_code))
	var all_spawns: Array[Dictionary] = []
	for chunk in chunks:
		for index in chunk.resource_count():
			all_spawns.append({"tile": chunk.resource_world_tile_at(index), "code": chunk.resource_code_at(index)})
	var spacing_valid := true
	for first_index in all_spawns.size():
		for second_index in range(first_index + 1, all_spawns.size()):
			var first := all_spawns[first_index]
			var second := all_spawns[second_index]
			var required := maxi(catalog.minimum_distance_for_code(int(first["code"])), catalog.minimum_distance_for_code(int(second["code"])))
			if (first["tile"] as Vector2i).distance_squared_to(second["tile"] as Vector2i) < required * required:
				spacing_valid = false
	_assert_true(spacing_valid, "minimum spacing holds within and across chunk borders")
	_assert_equal(keys.size(), all_spawns.size(), "resource world keys are unique across chunks")
	var showcase := generator.generate_chunk(Vector2i(-1, -4))
	var repeated := TerrainGenerator.new(seed).generate_chunk(Vector2i(-1, -4))
	_assert_true(showcase.resource_codes == repeated.resource_codes and showcase.resource_local_x == repeated.resource_local_x and showcase.resource_local_y == repeated.resource_local_y, "resource bytes are deterministic across generator restarts")
	var spawn := generator.find_land_near(showcase)
	_assert_true(not showcase.has_resource_at(WorldCoordinates.tile_to_local(spawn)), "initial player spawn avoids resource collision")


func _test_resource_harvest_state() -> void:
	var catalog := ResourceCatalog.new()
	var state := ResourceHarvestState.new()
	var tree_code := catalog.code_for_id(&"tree")
	var key := "-7:12:%d" % tree_code
	var wrong_tool := state.hit(key, tree_code, &"hands", catalog)
	_assert_true(not bool(wrong_tool["accepted"]) and String(wrong_tool["reason"]) == "wrong_tool", "wrong tool cannot damage a resource")
	var first_hit := state.hit(key, tree_code, &"axe", catalog)
	var second_hit := state.hit(key, tree_code, &"axe", catalog)
	var final_hit := state.hit(key, tree_code, &"axe", catalog)
	_assert_true(bool(first_hit["accepted"]) and not bool(first_hit["destroyed"]) and int(first_hit["remaining"]) == 2, "resource durability decreases by tool power")
	_assert_true((first_hit["drops"] as Array).is_empty() and (second_hit["drops"] as Array).is_empty(), "resource does not drop items before destruction")
	_assert_true(bool(final_hit["destroyed"]) and state.collected_resources.has(key), "final valid hit records the resource difference")
	var drops := final_hit["drops"] as Array
	_assert_equal(drops.size(), 1, "destroyed tree resolves one controlled drop stack")
	var tree_drop := drops[0] as Dictionary
	_assert_equal(tree_drop["item_id"], &"wood", "tree produces the correct item")
	_assert_true(int(tree_drop["quantity"]) >= 2 and int(tree_drop["quantity"]) <= 4, "tree drop quantity stays inside configured bounds")
	var duplicate := state.hit(key, tree_code, &"axe", catalog)
	_assert_true(not bool(duplicate["accepted"]) and (duplicate["drops"] as Array).is_empty(), "same resource cannot drop twice")
	state.collect_item(tree_drop["item_id"] as StringName, int(tree_drop["quantity"]))
	_assert_equal(state.quantity(&"wood"), int(tree_drop["quantity"]), "automatic pickup target inventory accepts resolved quantity")


func _test_save_system() -> void:
	SaveManager.clear_current_world()
	_assert_true(SaveManager.create_world("自动测试边境", "存档种子-070"), "world creation writes initial metadata and player state")
	var root := SaveManager.current_world_root_absolute()
	_assert_true(FileAccess.file_exists(root.path_join("world.json")) and FileAccess.file_exists(root.path_join("player.json")), "new world contains metadata and player documents")
	var metadata := _read_json_for_test(root.path_join("world.json"))
	_assert_equal(int(metadata.get("save_version", 0)), 6, "world metadata records save format 6")
	_assert_equal(int(metadata.get("generation_version", 0)), 4, "world metadata records generation format 4")
	_assert_equal(String(metadata.get("world_name", "")), "自动测试边境", "world metadata preserves the world name")
	_assert_equal(String(metadata.get("seed_text", "")), "存档种子-070", "world metadata preserves the text seed")
	var chunks_path := root.path_join("chunks/surface")
	_assert_equal(_json_file_count(chunks_path), 0, "new unmodified world creates no chunk difference file")
	var initial_player := SaveManager.loaded_player_snapshot()
	var empty_inventory := InventoryModel.new()
	var empty_state := {
		"collected_resources": [],
		"inventory": empty_inventory.snapshot(),
		"crafting_state": CraftingSystem.new(empty_inventory).persistence_snapshot(),
		"grave_state": GraveModel.new().persistence_snapshot(),
		"milestone_state": MilestoneState.new().persistence_snapshot(),
		"active_tool": "hands",
	}
	_assert_true(SaveManager.request_save(initial_player, empty_state, 1.25, false), "automatic save request accepts an immutable snapshot")
	SaveManager.flush_pending_save()
	_assert_equal(_json_file_count(chunks_path), 0, "saving an unmodified world still creates no chunk difference file")
	var player := initial_player.duplicate(true)
	player["position"] = [-2048.5, 1024.25]
	player["health"] = 73.0
	player["stamina"] = 41.0
	var saved_combat := PlayerCombatState.new()
	saved_combat.defense = 4.0
	saved_combat.death_count = 2
	saved_combat.invulnerability_remaining = 0.25
	saved_combat.respawn_position = Vector2(-2016.0, 992.0)
	player["combat_state"] = saved_combat.persistence_snapshot()
	var removed_keys := ["-1:-129:0", "33:65:1"]
	var changed_inventory := InventoryModel.new()
	changed_inventory.add_item(&"wood", 7)
	changed_inventory.add_item(&"stone", 3)
	changed_inventory.add_item(&"wood_axe", 1)
	var saved_tool_slot := _find_item_slot(changed_inventory, &"wood_axe")
	changed_inventory.damage_tool_at(saved_tool_slot, 7)
	changed_inventory.select_hotbar(saved_tool_slot)
	var changed_inventory_snapshot := changed_inventory.snapshot()
	var changed_crafting := CraftingSystem.new(changed_inventory)
	changed_crafting.refresh_discoveries()
	var changed_crafting_snapshot := changed_crafting.persistence_snapshot()
	var grave_inventory := InventoryModel.new()
	grave_inventory.add_item(&"branch", 4)
	grave_inventory.add_item(&"stone_sword", 1)
	var grave_sword_slot := _find_item_slot(grave_inventory, &"stone_sword")
	grave_inventory.damage_tool_at(grave_sword_slot, 11)
	var changed_graves := GraveModel.new()
	changed_graves.deposit(Vector2(-1990.0, 1004.0), grave_inventory)
	var changed_grave_snapshot := changed_graves.persistence_snapshot()
	var changed_milestones := MilestoneState.new()
	changed_milestones.discover_ruin()
	changed_milestones.defeat_boss()
	changed_milestones.claim_reward()
	var changed_milestone_snapshot := changed_milestones.persistence_snapshot()
	var changed_state := {
		"collected_resources": removed_keys,
		"inventory": changed_inventory_snapshot,
		"crafting_state": changed_crafting_snapshot,
		"grave_state": changed_grave_snapshot,
		"milestone_state": changed_milestone_snapshot,
		"active_tool": "axe",
	}
	var dispatch_started := Time.get_ticks_usec()
	_assert_true(SaveManager.request_save(player, changed_state, 42.5, false), "changed world dispatches an autosave")
	var dispatch_ms := float(Time.get_ticks_usec() - dispatch_started) / 1000.0
	_assert_true(dispatch_ms < 50.0, "autosave snapshot dispatch does not block the main thread")
	SaveManager.flush_pending_save()
	_assert_true(SaveManager.last_save_duration_ms < 500.0, "background save completes without a visible-length stall")
	_assert_equal(_json_file_count(chunks_path), 2, "only the two modified chunks create difference files")
	var world_id := SaveManager.current_world_id()
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "saved world reloads after manager state is cleared")
	var restored_player := SaveManager.loaded_player_snapshot()
	_assert_equal(restored_player["position"], [-2048.5, 1024.25], "player position restores exactly")
	_assert_equal(float(restored_player["health"]), 73.0, "player health restores exactly")
	_assert_equal(float(restored_player["stamina"]), 41.0, "player stamina restores exactly")
	_assert_equal(restored_player["combat_state"], saved_combat.persistence_snapshot(), "player defense, invulnerability, death count and respawn point restore exactly")
	var restored_world_state := SaveManager.loaded_world_state_snapshot()
	var restored_removed := restored_world_state["collected_resources"] as Array
	_assert_true(restored_removed.has(removed_keys[0]) and restored_removed.has(removed_keys[1]), "destroyed resources restore from chunk differences")
	_assert_equal(restored_world_state["inventory"], changed_inventory_snapshot, "V0.8 slot order and stack quantities restore identically")
	var restored_inventory_model := InventoryModel.new()
	restored_inventory_model.restore_snapshot(restored_world_state["inventory"] as Dictionary)
	var restored_tool_slot := _find_item_slot(restored_inventory_model, &"wood_axe")
	_assert_true(restored_tool_slot == saved_tool_slot and int(restored_inventory_model.slot(restored_tool_slot)["durability"]) == 23, "selected hotbar tool and individual durability restore exactly")
	_assert_equal(restored_world_state["crafting_state"], changed_crafting_snapshot, "V0.9 recipe discoveries restore identically")
	_assert_equal(restored_world_state["grave_state"], changed_grave_snapshot, "V0.10 grave position, contents and durability restore identically")
	_assert_equal(restored_world_state["milestone_state"], changed_milestone_snapshot, "V1.0 ruin, Boss and reward progression restore identically")
	_assert_equal(String(restored_world_state["active_tool"]), "axe", "active tool restores with player attributes")
	var restored_harvest := ResourceHarvestState.new()
	_assert_true(restored_harvest.restore_snapshot(restored_removed, restored_world_state["inventory"]), "restored inventory snapshot passes schema validation")
	_assert_true(restored_harvest.collected_resources.has(removed_keys[0]), "restored collected key prevents a generated resource from reappearing")
	_assert_true(restored_harvest.quantity(&"wood") == 7 and restored_harvest.quantity(&"stone") == 3, "restored inventory exposes exact item totals")
	_assert_true(SaveManager.request_save(restored_player, restored_world_state, 44.0, true), "manual save requests a backup")
	SaveManager.flush_pending_save()
	_assert_true(_directory_count(root.path_join("backups")) >= 1, "manual save creates a recoverable backup directory")
	var legacy_metadata := _read_json_for_test(root.path_join("world.json"))
	legacy_metadata["save_version"] = 2
	var legacy_player := _read_json_for_test(root.path_join("player.json"))
	legacy_player["save_version"] = 2
	legacy_player["inventory"] = {"wood": 7, "stone": 3}
	_write_json_for_test(root.path_join("world.json"), legacy_metadata)
	_write_json_for_test(root.path_join("player.json"), legacy_player)
	var difference_directory := DirAccess.open(chunks_path)
	for filename in difference_directory.get_files():
		if filename.ends_with(".json"):
			var legacy_difference := _read_json_for_test(chunks_path.path_join(filename))
			legacy_difference["save_version"] = 2
			_write_json_for_test(chunks_path.path_join(filename), legacy_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V0.7 save format loads through the explicit V0.10 migration path")
	var migrated_state := SaveManager.loaded_world_state_snapshot()
	var migrated_inventory := InventoryModel.new()
	_assert_true(migrated_inventory.restore_snapshot(migrated_state["inventory"] as Dictionary), "migrated legacy counts produce a valid slot inventory")
	_assert_true(migrated_inventory.quantity(&"wood") == 7 and migrated_inventory.quantity(&"stone") == 3, "save migration preserves legacy item totals exactly")
	_assert_true(SaveManager.request_save(SaveManager.loaded_player_snapshot(), migrated_state, 45.0, false), "migrated world can be committed as save format 6")
	SaveManager.flush_pending_save()
	_assert_equal(int(_read_json_for_test(root.path_join("world.json")).get("save_version", 0)), 6, "next save commits V0.7 world metadata as format 6")
	_assert_equal(int(_read_json_for_test(root.path_join("player.json")).get("save_version", 0)), 6, "next save commits V0.7 player inventory as format 6")
	var v08_metadata := _read_json_for_test(root.path_join("world.json"))
	v08_metadata["save_version"] = 3
	var v08_player := _read_json_for_test(root.path_join("player.json"))
	v08_player["save_version"] = 3
	(v08_player["inventory"] as Dictionary)["schema_version"] = 1
	v08_player.erase("crafting_state")
	_write_json_for_test(root.path_join("world.json"), v08_metadata)
	_write_json_for_test(root.path_join("player.json"), v08_player)
	for filename in difference_directory.get_files():
		if filename.ends_with(".json"):
			var v08_difference := _read_json_for_test(chunks_path.path_join(filename))
			v08_difference["save_version"] = 3
			_write_json_for_test(chunks_path.path_join(filename), v08_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V0.8 save format 3 migrates to milestone-capable format 6")
	_assert_equal(int(SaveManager.loaded_player_snapshot().get("save_version", 0)), 6, "V0.8 migration normalizes player save version in memory")
	_assert_equal(int((SaveManager.loaded_world_state_snapshot()["inventory"] as Dictionary).get("schema_version", 0)), 2, "V0.8 inventory schema upgrades from 1 to 2")
	_assert_true((SaveManager.loaded_world_state_snapshot()["crafting_state"] as Dictionary).has("discovered_items"), "V0.8 migration initializes crafting discovery state")
	_assert_true((SaveManager.loaded_player_snapshot()["combat_state"] as Dictionary).has("respawn_position") and (SaveManager.loaded_world_state_snapshot()["grave_state"] as Dictionary).has("graves"), "V0.8 migration initializes combat and grave state")
	var v09_metadata := _read_json_for_test(root.path_join("world.json"))
	v09_metadata["save_version"] = 4
	var v09_player := SaveManager.loaded_player_snapshot()
	v09_player["save_version"] = 4
	var v09_crafting_snapshot := (v09_player["crafting_state"] as Dictionary).duplicate(true)
	v09_player.erase("combat_state")
	v09_player.erase("grave_state")
	_write_json_for_test(root.path_join("world.json"), v09_metadata)
	_write_json_for_test(root.path_join("player.json"), v09_player)
	for filename in difference_directory.get_files():
		if filename.ends_with(".json"):
			var v09_difference := _read_json_for_test(chunks_path.path_join(filename))
			v09_difference["save_version"] = 4
			_write_json_for_test(chunks_path.path_join(filename), v09_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V0.9 save format 4 migrates to milestone-capable format 6")
	_assert_equal(SaveManager.loaded_world_state_snapshot()["crafting_state"], v09_crafting_snapshot, "V0.9 migration preserves the exact crafting-state object")
	_assert_true((SaveManager.loaded_player_snapshot()["combat_state"] as Dictionary).has("death_count") and (SaveManager.loaded_world_state_snapshot()["grave_state"] as Dictionary).has("next_id"), "V0.9 migration initializes combat status and an empty grave list")
	_assert_true((SaveManager.loaded_world_state_snapshot()["milestone_state"] as Dictionary).has("ruin_discovered"), "legacy migration initializes incomplete V1.0 milestone state")
	var v010_metadata := _read_json_for_test(root.path_join("world.json"))
	v010_metadata["save_version"] = 5
	var v010_player := SaveManager.loaded_player_snapshot()
	v010_player["save_version"] = 5
	v010_player.erase("milestone_state")
	_write_json_for_test(root.path_join("world.json"), v010_metadata)
	_write_json_for_test(root.path_join("player.json"), v010_player)
	for filename in difference_directory.get_files():
		if filename.ends_with(".json"):
			var v010_difference := _read_json_for_test(chunks_path.path_join(filename))
			v010_difference["save_version"] = 5
			_write_json_for_test(chunks_path.path_join(filename), v010_difference)
	SaveManager.clear_current_world()
	_assert_true(SaveManager.load_world(world_id), "V0.10/V0.11 save format 5 migrates to V1.0 format 6")
	var migrated_milestone := SaveManager.loaded_world_state_snapshot()["milestone_state"] as Dictionary
	_assert_true(not bool(migrated_milestone["ruin_discovered"]) and not bool(migrated_milestone["boss_defeated"]), "format-5 migration starts the new milestone incomplete")
	var corrupt_file := FileAccess.open(root.path_join("world.json"), FileAccess.WRITE)
	corrupt_file.store_string("{broken save")
	corrupt_file.flush()
	corrupt_file = null
	SaveManager.clear_current_world()
	_assert_true(not SaveManager.load_world(world_id), "corrupted world metadata is rejected")
	_assert_true("损坏" in SaveManager.last_error and "world.json" in SaveManager.last_error, "corrupted save reports a clear file-specific error")
	SaveManager.clear_current_world()
	_remove_test_save_tree(root)


func _test_stream_planner() -> void:
	var center := Vector2i(-12, 7)
	_assert_equal(ChunkStreamPlanner.coordinates_in_radius(center, ChunkStreamPlanner.ACTIVE_RADIUS).size(), 25, "active radius contains at most 25 chunks")
	_assert_equal(ChunkStreamPlanner.coordinates_in_radius(center, ChunkStreamPlanner.PRELOAD_RADIUS).size(), 49, "preload radius contains at most 49 chunks")
	var ahead := center + Vector2i(3, 0)
	var behind := center + Vector2i(-3, 0)
	_assert_true(ChunkStreamPlanner.priority_score(ahead, center, Vector2i.RIGHT) < ChunkStreamPlanner.priority_score(behind, center, Vector2i.RIGHT), "movement direction receives queue priority")
	var simulated_cache: Array[Vector2i] = []
	var peak_cache := 0
	for minute_step in 1800:
		var simulated_center := Vector2i(minute_step - 900, -17)
		for coordinate in ChunkStreamPlanner.coordinates_in_radius(simulated_center, ChunkStreamPlanner.PRELOAD_RADIUS):
			if not simulated_cache.has(coordinate):
				simulated_cache.append(coordinate)
		simulated_cache = ChunkStreamPlanner.trim_to_cache_radius(simulated_cache, simulated_center)
		peak_cache = maxi(peak_cache, simulated_cache.size())
	_assert_true(peak_cache <= 81 and simulated_cache.size() <= 81, "30-minute traversal simulation keeps cache bounded to 9×9")


func _test_chunk_seams() -> void:
	var generator := TerrainGenerator.new(WorldSeed.from_text("无尽边境"))
	var left_coordinate := Vector2i(-1, -4)
	var right_coordinate := Vector2i(0, -4)
	var left := generator.generate_chunk(left_coordinate)
	var right := generator.generate_chunk(right_coordinate)
	var seam_coordinates_correct := true
	var samples_match_global_field := true
	var biome_samples_match_global_field := true
	for y in WorldCoordinates.CHUNK_SIZE:
		var left_world := WorldCoordinates.chunk_local_to_tile(left_coordinate, Vector2i(31, y))
		var right_world := WorldCoordinates.chunk_local_to_tile(right_coordinate, Vector2i(0, y))
		seam_coordinates_correct = seam_coordinates_correct and left_world + Vector2i.RIGHT == right_world
		var left_expected := clampi(roundi(generator.elevation_at(left_world) * 255.0), 0, 255)
		var right_expected := clampi(roundi(generator.elevation_at(right_world) * 255.0), 0, 255)
		samples_match_global_field = samples_match_global_field and left.elevation_map[y * 32 + 31] == left_expected and right.elevation_map[y * 32] == right_expected
		biome_samples_match_global_field = biome_samples_match_global_field and left.biome_at(Vector2i(31, y)) == generator.biome_at(left_world) and right.biome_at(Vector2i(0, y)) == generator.biome_at(right_world)
	_assert_true(seam_coordinates_correct, "adjacent chunk border tiles are consecutive world coordinates")
	_assert_true(samples_match_global_field, "both sides of a seam sample the same global noise field")
	_assert_true(biome_samples_match_global_field, "both sides of a seam sample the same global biome field")
	var original_checksum := left.checksum
	generator.generate_chunk(Vector2i(120, -75))
	_assert_equal(generator.generate_chunk(left_coordinate).checksum, original_checksum, "evicted region regenerates identically on return")


func _test_background_generation() -> void:
	var job := ChunkGenerationJob.new(WorldSeed.from_text("线程边境"), Vector2i(-9, 11))
	var task_id := WorkerThreadPool.add_task(job.execute, false, "test_chunk_generation")
	var error := WorkerThreadPool.wait_for_task_completion(task_id)
	_assert_equal(error, OK, "background chunk task completes successfully")
	_assert_equal(job.worker_task_id, task_id, "chunk data was generated on the worker pool")
	_assert_true(job.result is ChunkData and not job.result.has_method("add_child"), "background task returns pure ChunkData without scene-tree APIs")


func _test_chunk_renderer() -> void:
	var renderer := ChunkRenderer.new()
	add_child(renderer)
	await get_tree().process_frame
	var chunk := TerrainGenerator.new(WorldSeed.from_text("无尽边境")).generate_chunk(Vector2i(-1, -4))
	renderer.apply_chunk(chunk)
	_assert_equal(renderer.get_used_cells().size(), 1024, "TileMapLayer renders every chunk tile")
	_assert_equal(renderer.get_used_rect(), Rect2i(0, 0, 32, 32), "chunk renderer uses bounded local TileMap coordinates")
	_assert_equal(renderer.position, WorldCoordinates.tile_to_world_pixel(Vector2i(-32, -128)), "chunk renderer node carries the world offset")
	_assert_equal(renderer.visible_resource_count(), chunk.resource_count(), "resource TileMapLayer renders every generated resource without per-tile nodes")
	var resource_layer: ResourceChunkLayer
	for child in renderer.get_children():
		if child is ResourceChunkLayer:
			resource_layer = child as ResourceChunkLayer
			break
	_assert_true(resource_layer != null and resource_layer.tile_set.get_physics_layers_count() == 1, "resource TileMapLayer owns a shared collision layer")
	var solid_collision_found := false
	if resource_layer != null:
		var catalog := ResourceCatalog.new()
		for index in chunk.resource_count():
			if not catalog.is_solid(chunk.resource_code_at(index)):
				continue
			var local := chunk.resource_local_at(index)
			var source := resource_layer.tile_set.get_source(resource_layer.get_cell_source_id(local)) as TileSetAtlasSource
			var tile_data := source.get_tile_data(resource_layer.get_cell_atlas_coords(local), 0)
			solid_collision_found = tile_data.get_collision_polygons_count(0) > 0
			break
	_assert_true(solid_collision_found, "solid trees, rocks or berry bushes expose physical collision polygons")
	if chunk.resource_count() > 0:
		var collected := {chunk.resource_key_at(0): true}
		renderer.set_collected_resources(collected)
		_assert_equal(renderer.visible_resource_count(), chunk.resource_count() - 1, "collected resource remains hidden when a chunk renderer refreshes")
	renderer.set_debug_options(ChunkRenderer.ViewMode.BIOME, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "biome debug view preserves cell coverage")
	renderer.set_debug_options(ChunkRenderer.ViewMode.CLIMATE, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "climate debug view preserves cell coverage")
	renderer.set_debug_options(ChunkRenderer.ViewMode.ELEVATION, true)
	_assert_equal(renderer.get_used_cells().size(), 1024, "elevation debug view preserves cell coverage")
	renderer.queue_free()


func _test_drop_pool() -> void:
	var pool := WorldDropPool.new()
	pool.configure(2)
	add_child(pool)
	await get_tree().process_frame
	_assert_true(pool.spawn_drop(&"wood", 2, Vector2(10, 10)), "drop pool activates a free object")
	_assert_true(pool.spawn_drop(&"stone", 1, Vector2(80, 10)), "drop pool activates a second free object")
	_assert_true(not pool.spawn_drop(&"berry", 1, Vector2(150, 10)), "drop pool refuses an unmergeable overflow")
	_assert_true(pool.spawn_drop(&"wood", 3, Vector2(12, 10)), "full pool merges a matching item stack")
	_assert_equal(pool.active_count(), 2, "drop object count remains capped at pool capacity")
	pool._process(0.25)
	var blocked := pool.transfer_near(Vector2(10, 10), 24.0, func(_item_id: StringName, _quantity: int, _metadata: Dictionary) -> int:
		return 0
	)
	_assert_true((blocked["transferred"] as Array).is_empty() and not (blocked["blocked"] as Array).is_empty(), "full inventory refuses pickup explicitly")
	_assert_equal(pool.active_quantity(&"wood"), 5, "refused pickup remains on the ground without loss or duplication")
	var pickup := pool.collect_near(Vector2(10, 10), 24.0)
	_assert_equal(pickup.size(), 1, "automatic pickup collects only nearby mature drops")
	_assert_equal(int((pickup[0] as Dictionary)["quantity"]), 5, "merged drop stack preserves total quantity")
	_assert_equal(pool.active_count(), 1, "picked-up object returns to the pool")
	_assert_true(pool.spawn_drop(&"wood_axe", 1, Vector2(12, 10), {"durability": 11}), "discarded damaged tool enters a free ground-drop slot")
	pool._process(0.25)
	var tool_pickup := pool.collect_near(Vector2(12, 10), 24.0)
	var found_tool_durability := false
	for stack in tool_pickup:
		if StringName((stack as Dictionary).get("item_id", "")) == &"wood_axe":
			found_tool_durability = int((stack as Dictionary).get("durability", 0)) == 11
	_assert_true(found_tool_durability, "discard and pickup preserve individual tool durability metadata")
	pool.queue_free()


func _test_player_scene_contract() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	add_child(player)
	await get_tree().physics_frame
	var collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	_assert_true(collision != null and collision.shape != null, "player has physical collision")
	_assert_true(camera != null and camera.position_smoothing_enabled, "camera smoothing enabled")
	player.take_damage(25.0)
	_assert_equal(player.health, 75.0, "player damage updates health")
	player.heal(10.0)
	_assert_equal(player.health, 85.0, "player healing clamps correctly")
	player.restore_snapshot({"position": [-96.5, 160.25], "health": 64.0, "maximum_health": 120.0, "stamina": 33.0, "maximum_stamina": 80.0})
	_assert_equal(player.position, Vector2(-96.5, 160.25), "player restore applies signed position")
	_assert_true(player.health == 64.0 and player.maximum_health == 120.0 and player.stamina == 33.0 and player.maximum_stamina == 80.0, "player restore applies health and stamina attributes")
	player.combat_state().tick(2.0)
	player.combat_state().respawn_position = Vector2(-64.0, 96.0)
	var lethal := player.receive_hit(999.0, Vector2.LEFT, 100.0)
	_assert_true(bool(lethal["died"]) and player.health == 0.0 and player.combat_state().status == &"dead", "player enters a valid death state after lethal damage")
	player.respawn_at(player.combat_state().respawn_position)
	_assert_true(player.health == player.maximum_health and player.global_position == Vector2(-64.0, 96.0) and player.combat_state().status == &"alive", "player death can complete a normal safe-position respawn")
	_assert_true((player.persistence_snapshot()["combat_state"] as Dictionary).has("death_count"), "player persistence includes combat status")
	player.queue_free()


func _test_generation_hud_layout() -> void:
	var hud := GenerationHud.new()
	add_child(hud)
	await get_tree().process_frame
	hud.configure("无尽边境", WorldSeed.from_text("无尽边境"), Vector2i(-1, -4), "47c1e52c4fe80f9c")
	hud.update_streaming({
		"current_chunk": Vector2i(-1, -4),
		"current_checksum": "47c1e52c4fe80f9c",
		"view_mode": "群系",
		"biome_name": "森林",
		"temperature": 0.48,
		"moisture": 0.73,
		"elevation": 0.57,
		"erosion": 0.41,
		"active": 25,
		"preload": 24,
		"cache": 49,
		"peak_cache": 49,
	})
	await get_tree().process_frame
	var panel := hud.find_child("GenerationPanel", true, false) as Control
	var world_label := hud.find_child("WorldLabel", true, false) as Label
	var stream_label := hud.find_child("StreamLabel", true, false) as Label
	_assert_true(panel != null and world_label != null and stream_label != null, "generation HUD diagnostic nodes exist")
	if panel != null and world_label != null and stream_label != null:
		_assert_true(panel.get_global_rect().encloses(world_label.get_global_rect()), "biome and climate diagnostics stay inside generation panel")
		_assert_true(panel.get_global_rect().encloses(stream_label.get_global_rect()), "stream diagnostics stay inside generation panel")
	hud.queue_free()


func _test_resource_hud_layout() -> void:
	var hud := ResourceHud.new()
	add_child(hud)
	await get_tree().process_frame
	EventBus.active_tool_changed.emit(&"axe", "斧头")
	EventBus.inventory_changed.emit({"wood": 4, "stone": 2, "fiber": 1})
	EventBus.resource_prompt_changed.emit("[E] 采集树木 · 耐久 3")
	await get_tree().process_frame
	var panel := hud.find_child("ResourcePanel", true, false) as Control
	var tool_label := hud.find_child("ToolLabel", true, false) as Label
	var inventory_label := hud.find_child("InventoryLabel", true, false) as Label
	var prompt_label := hud.find_child("ResourcePromptLabel", true, false) as Label
	_assert_true(panel != null and tool_label != null and inventory_label != null and prompt_label != null, "resource HUD tool, inventory and prompt nodes exist")
	if panel != null and tool_label != null and inventory_label != null:
		_assert_true(panel.get_global_rect().encloses(tool_label.get_global_rect()), "active tool stays inside resource panel")
		_assert_true(panel.get_global_rect().encloses(inventory_label.get_global_rect()), "inventory summary stays inside resource panel")
	hud.queue_free()


func _test_inventory_panel_layout() -> void:
	var panel := InventoryPanel.new()
	add_child(panel)
	await get_tree().process_frame
	var window := panel.find_child("InventoryWindow", true, false) as Control
	var hotbar := panel.find_child("Hotbar", true, false) as Control
	var grid := panel.find_child("InventoryGrid", true, false) as GridContainer
	var split_button := panel.find_child("SplitStackButton", true, false) as Button
	var discard_button := panel.find_child("DiscardItemButton", true, false) as Button
	var sort_button := panel.find_child("SortInventoryButton", true, false) as Button
	_assert_true(window != null and hotbar != null and grid != null, "inventory window, 8-slot hotbar and grid exist")
	_assert_equal(panel.find_children("InventorySlot*", "", true, false).size(), 24, "inventory UI creates exactly 24 drag-capable slots")
	_assert_equal(panel.find_children("HotbarSlot*", "", true, false).size(), 8, "hotbar UI mirrors exactly eight inventory slots")
	_assert_true(split_button != null and discard_button != null and sort_button != null, "split, discard and category-sort controls exist")
	panel.set_inventory_open(true)
	await get_tree().process_frame
	_assert_true(panel.is_inventory_open(), "inventory can be opened and captures its own UI state")
	var viewport_rect := get_viewport().get_visible_rect()
	_assert_true(viewport_rect.encloses(window.get_global_rect()), "open inventory window remains inside the 1280×720 viewport")
	_assert_true(viewport_rect.encloses(hotbar.get_global_rect()), "always-visible hotbar remains inside the 1280×720 viewport")
	panel.set_inventory_open(false)
	_assert_true(not panel.is_inventory_open(), "inventory can close without changing gameplay state")
	panel.queue_free()


func _test_crafting_panel_layout() -> void:
	var inventory := InventoryModel.new()
	inventory.add_item(&"branch", 4)
	inventory.add_item(&"fiber", 3)
	var crafting := CraftingSystem.new(inventory)
	crafting.refresh_discoveries()
	var panel := CraftingPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel._on_crafting_state_changed(crafting.recipe_views())
	var window := panel.find_child("CraftingWindow", true, false) as Control
	var tabs := panel.find_child("CraftingStationTabs", true, false) as HBoxContainer
	var list := panel.find_child("CraftingRecipeList", true, false) as VBoxContainer
	var status := panel.find_child("CraftingStatusLabel", true, false) as Label
	_assert_true(window != null and tabs != null and list != null and status != null, "crafting window, station tabs, recipe list and status exist")
	_assert_equal(tabs.get_child_count(), 3, "crafting UI exposes hands, workbench and campfire tabs")
	_assert_true(panel.find_child("Recipe_wood_axe", true, false) != null and panel.find_child("Craft_wood_axe", true, false) != null, "unlocked wooden-axe recipe has a data-driven row and action")
	panel.set_crafting_open(true)
	await get_tree().process_frame
	_assert_true(panel.is_crafting_open(), "crafting panel can be opened independently")
	_assert_true(get_viewport().get_visible_rect().encloses(window.get_global_rect()), "crafting window remains inside the 1280×720 viewport")
	panel.set_crafting_open(false)
	_assert_true(not panel.is_crafting_open(), "crafting panel closes without mutating recipes")
	panel.queue_free()


func _test_responsive_ui_layouts() -> void:
	var resolutions := [
		Vector2i(1280, 720),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3440, 1440),
	]
	for resolution in resolutions:
		var viewport := SubViewport.new()
		viewport.size = resolution
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		var canvas := Control.new()
		canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		viewport.add_child(canvas)
		var gameplay := GameplayHud.new()
		var generation := GenerationHud.new()
		var combat := CombatHud.new()
		var enemy := EnemyHud.new()
		var milestone := MilestoneHud.new()
		var resource := ResourceHud.new()
		var inventory := InventoryPanel.new()
		for hud in [gameplay, generation, combat, enemy, milestone, resource, inventory]:
			canvas.add_child(hud)
		await get_tree().process_frame
		EventBus.resource_prompt_changed.emit("[E] 采集树木 · 耐久 3")
		await get_tree().process_frame
		var visible := Rect2(Vector2.ZERO, Vector2(resolution))
		var controls := [
			gameplay.find_child("GameplayPanel", true, false) as Control,
			gameplay.find_child("ControlHintsLabel", true, false) as Control,
			generation.find_child("GenerationPanel", true, false) as Control,
			combat.find_child("CombatPanel", true, false) as Control,
			combat.find_child("CombatFeedbackLabel", true, false) as Control,
			enemy.find_child("EnemyPanel", true, false) as Control,
			milestone.find_child("MilestonePanel", true, false) as Control,
			resource.find_child("ResourcePanel", true, false) as Control,
			resource.find_child("ResourcePromptLabel", true, false) as Control,
			inventory.find_child("Hotbar", true, false) as Control,
		]
		var all_inside := true
		for control in controls:
			all_inside = all_inside and control != null and visible.encloses(control.get_global_rect())
		_assert_true(all_inside, "all HUD controls stay inside %d×%d" % [resolution.x, resolution.y])
		var prompt := resource.find_child("ResourcePromptLabel", true, false) as Control
		var hotbar := inventory.find_child("Hotbar", true, false) as Control
		var hints := gameplay.find_child("ControlHintsLabel", true, false) as Control
		_assert_true(
			prompt != null and hotbar != null and hints != null
			and not prompt.get_global_rect().intersects(hotbar.get_global_rect())
			and not hints.get_global_rect().intersects(prompt.get_global_rect())
			and not hints.get_global_rect().intersects(hotbar.get_global_rect()),
			"interaction prompt, hints and hotbar keep safe spacing at %d×%d" % [resolution.x, resolution.y]
		)
		viewport.queue_free()
		await get_tree().process_frame


func _test_combat_nodes_and_hud() -> void:
	var controller := PlayerCombatController.new()
	add_child(controller)
	var dummy := CombatTargetDummy.new()
	dummy.position = Vector2(120, 120)
	add_child(dummy)
	var hazard := TrainingHazard.new()
	hazard.position = Vector2(180, 120)
	add_child(hazard)
	var hud := CombatHud.new()
	add_child(hud)
	await get_tree().physics_frame
	await get_tree().process_frame
	var hitbox := controller.find_child("PlayerAttackHitbox", true, false) as Area2D
	var hit_shape := controller.find_child("AttackCollisionShape2D", true, false) as CollisionShape2D
	_assert_true(hitbox != null and hit_shape != null and hitbox.collision_mask == 8, "player attack uses a short-lived Area2D enemy hitbox")
	_assert_true(dummy.collision_layer == 8 and hazard.collision_mask == 2, "training target and hazard use isolated enemy/player collision layers")
	var dummy_hit := dummy.receive_attack({"attack_id": 7, "damage": 12.0, "direction": Vector2.RIGHT, "knockback": 170.0})
	_assert_true(bool(dummy_hit["accepted"]) and int(dummy_hit["damage"]) == 10, "training target applies defense-adjusted melee damage")
	_assert_true((dummy.debug_snapshot()["knockback"] as Vector2).x > 0.0, "training target receives directional knockback")
	EventBus.combat_status_changed.emit({"weapon_name": "石剑", "combo_index": 2, "combo_count": 3, "cooldown_remaining": 0.2, "cooldown_total": 0.4})
	EventBus.grave_state_changed.emit({"count": 1, "graves": []})
	EventBus.combat_feedback.emit("石剑 · 第 2 段", true)
	await get_tree().process_frame
	var panel := hud.find_child("CombatPanel", true, false) as Control
	var weapon_label := hud.find_child("CombatWeaponLabel", true, false) as Label
	var combo_label := hud.find_child("CombatComboLabel", true, false) as Label
	var grave_label := hud.find_child("CombatGraveLabel", true, false) as Label
	var feedback_label := hud.find_child("CombatFeedbackLabel", true, false) as Label
	_assert_true(panel != null and weapon_label != null and combo_label != null and grave_label != null and feedback_label != null, "combat HUD exposes weapon, combo, cooldown, grave and feedback nodes")
	_assert_true("石剑" in weapon_label.text and "2/3" in combo_label.text and "1" in grave_label.text, "combat HUD reflects weapon combo and grave state")
	_assert_true(get_viewport().get_visible_rect().encloses(panel.get_global_rect()) and get_viewport().get_visible_rect().encloses(feedback_label.get_global_rect()), "combat HUD remains inside the 1280×720 viewport")
	var integration_player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	integration_player.position = Vector2(-2048.0, -4096.0)
	add_child(integration_player)
	var integration_chunk := TerrainGenerator.new(WorldSeed.from_text("combat-integration")).generate_chunk(Vector2i(-2, -4))
	var integration_stream := ChunkStreamManager.new()
	integration_stream.configure(WorldSeed.from_text("combat-integration"), integration_player, integration_chunk)
	add_child(integration_stream)
	await get_tree().physics_frame
	var integration_inventory := integration_stream.harvest_state().inventory_model()
	integration_inventory.add_item(&"wood_sword", 1)
	var integration_sword_slot := _find_item_slot(integration_inventory, &"wood_sword")
	integration_inventory.select_hotbar(integration_sword_slot)
	var integration_controller := PlayerCombatController.new()
	integration_controller.configure(integration_player, integration_stream)
	integration_player.add_child(integration_controller)
	var integration_dummy := CombatTargetDummy.new()
	integration_dummy.position = integration_player.position + Vector2.RIGHT * 30.0
	add_child(integration_dummy)
	await get_tree().physics_frame
	var started := integration_controller.request_attack()
	var first_contact := integration_controller._attempt_hit(integration_dummy)
	var repeated_contact := integration_controller._attempt_hit(integration_dummy)
	_assert_true(bool(started["ok"]) and first_contact and not repeated_contact and integration_dummy.hit_count == 1, "real attack controller applies one hit per target for each attack ID")
	_assert_equal(int(integration_inventory.slot(integration_sword_slot)["durability"]), 39, "one successful swing consumes weapon durability exactly once")
	controller.queue_free()
	dummy.queue_free()
	hazard.queue_free()
	hud.queue_free()
	integration_dummy.queue_free()
	integration_stream.queue_free()
	integration_player.queue_free()


func _test_enemy_runtime_and_hud() -> void:
	var catalog := EnemyCatalog.new()
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = Vector2.ZERO
	add_child(player)
	var far_enemy := EnemyBase.new()
	far_enemy.configure(catalog.enemy(&"slime"), player, "test:far:slime", Vector2(1000.0, 0.0), 500.0)
	add_child(far_enemy)
	await get_tree().physics_frame
	var sleeping_ticks := far_enemy.complex_tick_count()
	_assert_true(far_enemy.sleeping and sleeping_ticks == 0, "far enemy sleeps without running complex state logic")
	player.position = Vector2(900.0, 0.0)
	await get_tree().physics_frame
	_assert_true(not far_enemy.sleeping and far_enemy.complex_tick_count() > sleeping_ticks, "nearby player wakes a sleeping enemy")
	var defeat_events: Array = []
	far_enemy.defeated.connect(func(spawn_id: String, enemy_id: StringName, world_position: Vector2, drops: Array) -> void:
		defeat_events.append({"spawn_id": spawn_id, "enemy_id": enemy_id, "position": world_position, "drops": drops})
	)
	var lethal := far_enemy.receive_attack({"damage": 999.0, "direction": Vector2.RIGHT, "knockback": 30.0})
	_assert_true(bool(lethal["accepted"]) and bool(lethal["died"]) and far_enemy.state_name() == &"DEAD", "lethal player hit completes enemy death state")
	_assert_true(defeat_events.size() == 1 and not (defeat_events[0]["drops"] as Array).is_empty(), "enemy death emits one complete drop transaction")
	var attack_enemy := EnemyBase.new()
	attack_enemy.configure(catalog.enemy(&"wolf"), player, "test:attack:wolf", player.position + Vector2(20.0, 0.0), 500.0)
	add_child(attack_enemy)
	var health_before_attack := player.health
	attack_enemy._attack_player()
	_assert_true(player.health < health_before_attack, "enemy attack applies configured damage to the player")
	player.combat_state().tick(PlayerCombatState.HIT_INVULNERABILITY_SECONDS + 0.01)
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 8
	wall.position = Vector2(55.0, 0.0)
	var wall_shape := CollisionShape2D.new()
	var wall_rectangle := RectangleShape2D.new()
	wall_rectangle.size = Vector2(20.0, 2000.0)
	wall_shape.shape = wall_rectangle
	wall.add_child(wall_shape)
	add_child(wall)
	player.position = Vector2(120.0, 0.0)
	var wall_enemy := EnemyBase.new()
	wall_enemy.configure(catalog.enemy(&"wolf"), player, "test:wall:wolf", Vector2.ZERO, 500.0)
	add_child(wall_enemy)
	for _frame in 150:
		wall_enemy._physics_process(1.0 / 60.0)
	_assert_true(wall_enemy.global_position.x < 43.0, "ground enemy collision prevents continuous movement through a wall")
	var hud := EnemyHud.new()
	add_child(hud)
	await get_tree().process_frame
	EventBus.enemy_state_changed.emit({"active": 12, "maximum": 18, "sleeping": 5, "counts": {"slime": 5, "wolf": 4, "cave_bat": 3}, "states": {"CHASE": 2, "ATTACK": 1}})
	await get_tree().process_frame
	var enemy_panel := hud.find_child("EnemyPanel", true, false) as Control
	var population_label := hud.find_child("EnemyPopulationLabel", true, false) as Label
	var types_label := hud.find_child("EnemyTypesLabel", true, false) as Label
	var states_label := hud.find_child("EnemyStatesLabel", true, false) as Label
	_assert_true(enemy_panel != null and population_label != null and types_label != null and states_label != null, "enemy HUD exposes population, type and state nodes")
	_assert_true("12/18" in population_label.text and "史莱姆 5" in types_label.text and "ATTACK 1" in states_label.text, "enemy HUD reflects bounded population and active states")
	_assert_true(get_viewport().get_visible_rect().encloses(enemy_panel.get_global_rect()), "enemy HUD remains inside the 1280×720 viewport")
	var director_player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	director_player.position = Vector2(8192.0, -4096.0)
	add_child(director_player)
	var drop_pool := WorldDropPool.new()
	drop_pool.configure(32, ResourceCatalog.new())
	add_child(drop_pool)
	var director := EnemyDirector.new()
	director.configure(WorldSeed.from_text("enemy-director-fixture"), director_player, drop_pool)
	add_child(director)
	await get_tree().process_frame
	for _step in 24:
		director.population_step()
	_assert_true(director.active_count() > 0 and director.active_count() <= director.maximum_active(), "repeated population updates never exceed the active-enemy hard cap")
	var all_offscreen := true
	var spawn_minimum_held := true
	for snapshot in director.active_snapshots():
		var world_position := snapshot["position"] as Vector2
		var screen_position := get_viewport().get_canvas_transform() * world_position
		all_offscreen = all_offscreen and not Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(96.0).has_point(screen_position)
		spawn_minimum_held = spawn_minimum_held and world_position.distance_to(director_player.global_position) >= float(catalog.population_value("spawn_minimum_distance_pixels", 760.0))
	_assert_true(all_offscreen and spawn_minimum_held, "new enemies appear outside the visible screen and minimum spawn radius")
	director._on_enemy_defeated("test:drop:slime", &"slime", director_player.position + Vector2(20.0, 0.0), catalog.resolve_drops(&"slime", "test:drop:slime"))
	_assert_true(drop_pool.active_quantity(&"slime_gel") >= 1, "enemy director sends canonical death drops through the bounded object pool")
	far_enemy.queue_free()
	attack_enemy.queue_free()
	wall_enemy.queue_free()
	wall.queue_free()
	hud.queue_free()
	director.queue_free()
	drop_pool.queue_free()
	director_player.queue_free()
	player.queue_free()


func _test_adventure_runtime_and_hud() -> void:
	var catalog := MilestoneCatalog.new()
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerCharacter
	player.position = Vector2.ZERO
	add_child(player)
	var state := MilestoneState.new()
	var encounter := RuinEncounter.new()
	encounter.configure({"id": "test_ruin", "world_position": Vector2.ZERO, "biome_id": "desert"}, player, state, catalog)
	add_child(encounter)
	var hud := MilestoneHud.new()
	add_child(hud)
	var overlay := DayNightOverlay.new()
	add_child(overlay)
	var audio := AudioCuePlayer.new()
	add_child(audio)
	await get_tree().process_frame
	encounter._process(0.0)
	var guardian := encounter.guardian()
	_assert_true(state.ruin_discovered and guardian != null, "entering the canonical ruin discovers it and activates one Boss")
	var health_before := player.health
	guardian._attack_player()
	_assert_true(player.health < health_before, "small Boss applies its data-driven attack to the player")
	player.combat_state().tick(PlayerCombatState.HIT_INVULNERABILITY_SECONDS + 0.01)
	var lethal := guardian.receive_attack({"damage": 999.0, "direction": Vector2.RIGHT, "knockback": 40.0})
	_assert_true(bool(lethal["died"]) and state.boss_defeated, "lethal player attack completes the ruin Boss encounter once")
	var inventory := InventoryModel.new()
	_assert_true(encounter.try_interact(inventory), "ruin core handles nearby reward interaction")
	_assert_true(state.reward_claimed and inventory.quantity(&"ancient_core") == 1, "Boss reward enters inventory and completes the survival loop")
	encounter.try_interact(inventory)
	_assert_equal(inventory.quantity(&"ancient_core"), 1, "completed ruin cannot duplicate its one-time reward")
	EventBus.time_state_changed.emit(DayNightCycle.new(210.0).snapshot())
	EventBus.milestone_state_changed.emit({"objective": state.objective_text(), "reward_claimed": true, "boss_defeated": true})
	overlay.apply_time(DayNightCycle.new(210.0).snapshot())
	await get_tree().process_frame
	var panel := hud.find_child("MilestonePanel", true, false) as Control
	var time_label := hud.find_child("TimeLabel", true, false) as Label
	var objective_label := hud.find_child("ObjectiveLabel", true, false) as Label
	var boss_label := hud.find_child("BossLabel", true, false) as Label
	_assert_true(panel != null and time_label != null and objective_label != null and boss_label != null, "milestone HUD exposes time, objective and Boss nodes")
	_assert_true("夜晚" in time_label.text and "继续探索" in objective_label.text and "核心已领取" in boss_label.text, "milestone HUD reflects the completed flow and persisted time")
	_assert_true(get_viewport().get_visible_rect().encloses(panel.get_global_rect()), "milestone HUD remains inside the 1280×720 viewport")
	_assert_true(overlay.color.a > 0.0, "night phase applies a visible basic lighting overlay")
	_assert_true(audio.played_cues > 0 or audio.play_cue(&"success"), "combat and milestone events drive a playable basic sound cue")
	encounter.queue_free()
	hud.queue_free()
	overlay.queue_free()
	audio.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_main_menu_layout() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var menu_scene := packed.instantiate() as Control
	add_child(menu_scene)
	await get_tree().process_frame
	var panel := menu_scene.find_child("MenuPanel", true, false) as Control
	var version_label := menu_scene.find_child("VersionLabel", true, false) as Control
	var footer := menu_scene.find_child("OfflineFooter", true, false) as Control
	var world_panel := menu_scene.find_child("WorldCreationPanel", true, false) as Control
	var world_name := menu_scene.find_child("WorldNameInput", true, false) as LineEdit
	var seed_input := menu_scene.find_child("SeedInput", true, false) as LineEdit
	var continue_button := menu_scene.find_child("ContinueButton", true, false) as Button
	_assert_true(panel != null and version_label != null and footer != null, "menu layout nodes exist")
	_assert_true(world_panel != null and world_name != null and seed_input != null and continue_button != null, "world creation and continue controls exist")
	if panel != null and version_label != null and footer != null:
		_assert_true(panel.get_global_rect().encloses(version_label.get_global_rect()), "version label stays inside menu panel")
		_assert_true(panel.get_global_rect().encloses(footer.get_global_rect()), "footer stays inside menu panel")
	menu_scene.queue_free()


func _read_json_for_test(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _write_json_for_test(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t", true, true) + "\n")
		file.flush()


func _find_item_slot(inventory: InventoryModel, item_id: StringName) -> int:
	for index in inventory.slot_count():
		if StringName(inventory.slot(index).get("item_id", "")) == item_id:
			return index
	return -1


func _json_file_count(path: String) -> int:
	var directory := DirAccess.open(path)
	if directory == null:
		return 0
	var result := 0
	for filename in directory.get_files():
		result += 1 if filename.ends_with(".json") else 0
	return result


func _directory_count(path: String) -> int:
	var directory := DirAccess.open(path)
	return directory.get_directories().size() if directory != null else 0


func _remove_test_save_tree(path: String) -> void:
	var saves_root := ProjectSettings.globalize_path(SaveManager.SAVE_ROOT)
	if not path.begins_with(saves_root.path_join("world_")):
		push_error("Refusing to remove a path outside the test save root: %s" % path)
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		DirAccess.remove_absolute(path.path_join(filename))
	for dirname in directory.get_directories():
		_remove_test_save_tree(path.path_join(dirname))
	DirAccess.remove_absolute(path)


func _assert_true(value: bool, label: String) -> void:
	if value:
		_passes += 1
		print("PASS | %s" % label)
	else:
		_failures.append(label)
		printerr("FAIL | %s" % label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	_assert_true(actual == expected, "%s (expected=%s actual=%s)" % [label, expected, actual])


func _finish() -> void:
	print("=== %d passed, %d failed ===" % [_passes, _failures.size()])
	if not _failures.is_empty():
		printerr("Failures: %s" % ", ".join(_failures))
		get_tree().quit(1)
	else:
		get_tree().quit(0)
