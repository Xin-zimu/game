# Architecture

Infinite Frontier uses a layered, data-oriented Godot architecture. This document records the foundation through V0.2.0 and will evolve with every version.

## Runtime layers

| Layer | Responsibility | Components through V0.2.0 |
|---|---|---|
| Core | Application lifecycle, settings, logging, events | `GameManager`, `SettingsManager`, `LogManager`, `EventBus` |
| Presentation | Scenes, menus and debug UI | `main_menu.gd`, `world_sandbox.gd`, `GameplayHud`, `DebugPanel` |
| Gameplay | Player, interaction, combat and progression | `PlayerCharacter`, `PlayerMotor`, `PlayerVisual`, `PixelCamera` |
| World | Coordinates, chunks, persistence and streaming | Begins in V0.3.0 |
| Generation | Pure deterministic world data | Begins in V0.3.0 |
| Data | Stable IDs and data-driven content | Introduced as systems require it |

## Architectural rules

1. Generation code is pure with respect to scene-tree state.
2. Systems communicate through typed signals or explicit APIs.
3. UI scripts do not own world-generation or combat logic.
4. Background work produces data only; scene-tree mutation remains on the main thread.
5. Save and generation formats are independently versioned.
6. World coordinates support negative values from their first implementation.
7. Stable versions are immutable Git tags.

## Boot flow

`project.godot` loads the four core autoloads, then opens the main menu. `GameManager` owns scene transitions. `SettingsManager` loads local configuration before the first interactive frame, while `LogManager` creates a bounded session log under `user://logs`.

## Player flow

`PlayerCharacter` owns input, the finite state machine and `move_and_slide`. Pure velocity calculations live in `PlayerMotor`, allowing the same diagonal normalization and delta integration rules to be tested without a scene tree. `PixelCamera` follows the physics body independently, and `GameplayHud` consumes player signals without owning player state.

The V0.2 sandbox is intentionally finite. `SandboxTerrain` and static obstacle bodies are presentation and collision fixtures for validating player movement; V0.3 replaces the terrain source with deterministic generation, while V0.4 introduces streamed chunks.
