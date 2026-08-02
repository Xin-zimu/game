#!/usr/bin/env python3
"""Repository-level structural checks that do not require the Godot editor."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED_PATHS = (
    "project.godot",
    "README.md",
    "AGENTS.md",
    "CHANGELOG.md",
    "docs/save-format.md",
    "scenes/main/main.tscn",
    "scenes/main/game.tscn",
    "scenes/player/player.tscn",
    "scripts/core/event_bus.gd",
    "scripts/core/game_manager.gd",
    "scripts/core/settings_manager.gd",
    "scripts/core/log_manager.gd",
    "scripts/save/save_manager.gd",
    "scripts/save/save_write_job.gd",
    "scripts/ui/ui_theme_factory.gd",
    "scripts/main/world_sandbox.gd",
    "scripts/player/player_character.gd",
    "scripts/player/player_motor.gd",
    "scripts/generation/world_seed.gd",
    "scripts/generation/biome_catalog.gd",
    "scripts/generation/resource_catalog.gd",
    "scripts/generation/resource_generator.gd",
    "scripts/generation/terrain_generator.gd",
    "scripts/crafting/recipe_data.gd",
    "scripts/crafting/recipe_catalog.gd",
    "scripts/crafting/crafting_system.gd",
    "scripts/combat/weapon_definition.gd",
    "scripts/combat/weapon_catalog.gd",
    "scripts/combat/damage_calculator.gd",
    "scripts/combat/attack_sequence_model.gd",
    "scripts/combat/player_combat_state.gd",
    "scripts/combat/grave_model.gd",
    "scripts/combat/player_combat_controller.gd",
    "scripts/combat/combat_target_dummy.gd",
    "scripts/combat/training_hazard.gd",
    "scripts/combat/grave_marker.gd",
    "scripts/items/item_data.gd",
    "scripts/items/item_catalog.gd",
    "scripts/items/inventory_model.gd",
    "data/biomes.json",
    "data/resources.json",
    "data/items.json",
    "data/recipes.json",
    "data/weapons.json",
    "scripts/world/world_coordinates.gd",
    "scripts/world/chunk_data.gd",
    "scripts/world/chunk_renderer.gd",
    "scripts/world/chunk_boundary_overlay.gd",
    "scripts/world/chunk_stream_planner.gd",
    "scripts/world/chunk_generation_job.gd",
    "scripts/world/chunk_stream_manager.gd",
    "scripts/world/resource_chunk_layer.gd",
    "scripts/world/world_drop_pool.gd",
    "scripts/gameplay/resource_harvest_state.gd",
    "scripts/ui/resource_hud.gd",
    "scripts/ui/inventory_panel.gd",
    "scripts/ui/crafting_panel.gd",
    "scripts/ui/combat_hud.gd",
    "assets/fonts/NotoSansCJKsc-ProjectSubset.otf",
    "tests/run_all.gd",
    "tests/test_runner.tscn",
    "tools/build_release.sh",
    "tools/render_biome_map.gd",
    "tools/render_resource_map.gd",
    "tools/render_save_diff_map.gd",
)


def main() -> int:
    failures: list[str] = []
    for relative in REQUIRED_PATHS:
        if not (ROOT / relative).is_file():
            failures.append(f"missing required file: {relative}")

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    for autoload in ("EventBus", "LogManager", "SettingsManager", "SaveManager", "GameManager"):
        if not re.search(rf"^{autoload}=", project, flags=re.MULTILINE):
            failures.append(f"autoload not registered: {autoload}")

    version_text = (ROOT / "scripts/core/game_version.gd").read_text(encoding="utf-8")
    if 'const VERSION := "0.10.0"' not in version_text:
        failures.append("game version is not 0.10.0")

    if "const SAVE_VERSION := 5" not in version_text:
        failures.append("save version is not 5")

    if "const GENERATION_VERSION := 4" not in version_text:
        failures.append("generation version is not 4")

    if failures:
        print("Structural verification failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"Structural verification passed ({len(REQUIRED_PATHS)} required files).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
