# Architecture

Infinite Frontier uses a layered, data-oriented Godot architecture. This document records the foundation through V0.5.0 and will evolve with every version.

## Runtime layers

| Layer | Responsibility | Components through V0.5.0 |
|---|---|---|
| Core | Application lifecycle, settings, logging, events | `GameManager`, `SettingsManager`, `LogManager`, `EventBus` |
| Presentation | Scenes, menus and debug UI | `main_menu.gd`, `world_sandbox.gd`, `GameplayHud`, `GenerationHud`, `DebugPanel` |
| Gameplay | Player, interaction, combat and progression | `PlayerCharacter`, `PlayerMotor`, `PlayerVisual`, `PixelCamera` |
| World | Coordinates, chunk data, persistence and streaming | `WorldCoordinates`, `ChunkData`, `ChunkStreamPlanner`, `ChunkGenerationJob`, `ChunkStreamManager`, `ChunkRenderer` |
| Generation | Pure deterministic world data | `WorldSeed`, `BiomeCatalog`, `TerrainGenerator` |
| Data | Stable IDs and data-driven content | `data/biomes.json` |

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

## Deterministic generation flow

`WorldSeed` converts text with a documented SHA-256 fixture and derives independent system seeds. `WorldCoordinates` converts signed world tiles to chunk/local coordinates with floor division, including negative boundaries. `TerrainGenerator` reads only seeds, biome configuration and integer world coordinates and returns `ChunkData`; it never reads the player or scene tree. `ChunkRenderer` is the only component that translates those bytes into `TileMapLayer` cells.

## Biome ownership

`BiomeCatalog` validates the external JSON schema, unique stable IDs, contiguous byte codes, ordered water thresholds and land-biome rules. `TerrainGenerator` owns noise sampling and classification. `ChunkData` stores the resulting maps. `ChunkRenderer` owns palette presentation, while `GenerationHud` only displays values supplied by the stream manager. Editing biome thresholds, priorities, colors or transition widths therefore does not require changing generation code.

The generation pipeline uses independent seed domains for continentalness, elevation, erosion, temperature, moisture and local detail. Altitude cools the temperature field and nearby oceans influence moisture. Hard-rule boundaries include configured transition bands, then a global 3×3 majority pass removes sparse outliers without depending on chunk generation order.

## Streaming ownership

`ChunkStreamPlanner` is a pure policy module for radii, retention and priority. `ChunkStreamManager` owns the queue, job lifecycle, bounded cache and renderer lifecycle. A `ChunkGenerationJob` constructs a private generator on a worker and returns only `ChunkData`; every task is joined before its result is read or the manager exits. `ChunkRenderer` creation, TileMap updates, HUD signals and node removal happen only on the main thread.

The active radius is 2 (at most 25 renderer nodes), the preload radius is 3 (at most 49 nearby data targets), and the retention radius is 4 (at most 81 cached coordinates under sustained travel). Each renderer stores local cells `0..31` and applies its signed chunk position as a node transform, avoiding large serialized TileMap coordinates.
