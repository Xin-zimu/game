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
    "scenes/main/main.tscn",
    "scenes/main/game.tscn",
    "scenes/player/player.tscn",
    "scripts/core/event_bus.gd",
    "scripts/core/game_manager.gd",
    "scripts/core/settings_manager.gd",
    "scripts/core/log_manager.gd",
    "scripts/ui/ui_theme_factory.gd",
    "scripts/main/world_sandbox.gd",
    "scripts/player/player_character.gd",
    "scripts/player/player_motor.gd",
    "scripts/generation/world_seed.gd",
    "scripts/generation/terrain_generator.gd",
    "scripts/world/world_coordinates.gd",
    "scripts/world/chunk_data.gd",
    "scripts/world/single_chunk_renderer.gd",
    "assets/fonts/NotoSansCJKsc-ProjectSubset.otf",
    "tests/run_all.gd",
    "tests/test_runner.tscn",
    "tools/build_release.sh",
)


def main() -> int:
    failures: list[str] = []
    for relative in REQUIRED_PATHS:
        if not (ROOT / relative).is_file():
            failures.append(f"missing required file: {relative}")

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    for autoload in ("EventBus", "LogManager", "SettingsManager", "GameManager"):
        if not re.search(rf"^{autoload}=", project, flags=re.MULTILINE):
            failures.append(f"autoload not registered: {autoload}")

    version_text = (ROOT / "scripts/core/game_version.gd").read_text(encoding="utf-8")
    if 'const VERSION := "0.3.0"' not in version_text:
        failures.append("game version is not 0.3.0")

    if "const GENERATION_VERSION := 2" not in version_text:
        failures.append("generation version is not 2")

    if failures:
        print("Structural verification failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"Structural verification passed ({len(REQUIRED_PATHS)} required files).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
