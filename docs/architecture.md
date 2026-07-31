# Architecture

Infinite Frontier uses a layered, data-oriented Godot architecture. This document records the V0.1.0 foundation and will evolve with every version.

## Runtime layers

| Layer | Responsibility | V0.1.0 components |
|---|---|---|
| Core | Application lifecycle, settings, logging, events | `GameManager`, `SettingsManager`, `LogManager`, `EventBus` |
| Presentation | Scenes, menus and debug UI | `main_menu.gd`, `game_shell.gd`, `DebugPanel` |
| Gameplay | Player, interaction, combat and progression | Begins in V0.2.0 |
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
