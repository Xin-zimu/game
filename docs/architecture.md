# Architecture

Infinite Frontier uses a layered, data-oriented Godot architecture. This document records the foundation through V0.10.0 and will evolve with every version.

## Runtime layers

| Layer | Responsibility | Components through V0.10.0 |
|---|---|---|
| Core | Application lifecycle, settings, logging, events | `GameManager`, `SettingsManager`, `SaveManager`, `LogManager`, `EventBus` |
| Presentation | Scenes, menus and debug UI | `main_menu.gd`, `world_sandbox.gd`, `GameplayHud`, `CombatHud`, `GenerationHud`, `ResourceHud`, `InventoryPanel`, `CraftingPanel`, `DebugPanel` |
| Gameplay | Player, interaction, combat and progression | `PlayerCharacter`, `PlayerMotor`, `PlayerVisual`, `PixelCamera`, `ResourceHarvestState`, `InventoryModel`, `CraftingSystem`, `PlayerCombatController`, `PlayerCombatState`, `GraveModel` |
| World | Coordinates, chunk data, persistence and streaming | `WorldCoordinates`, `ChunkData`, `ChunkStreamPlanner`, `ChunkGenerationJob`, `ChunkStreamManager`, `ChunkRenderer`, `ResourceChunkLayer`, `WorldDropPool`, `SaveWriteJob` |
| Generation | Pure deterministic world data | `WorldSeed`, `BiomeCatalog`, `ResourceCatalog`, `ResourceGenerator`, `TerrainGenerator` |
| Data | Stable IDs and data-driven content | `data/biomes.json`, `data/resources.json`, `data/items.json`, `data/recipes.json`, `data/weapons.json`, catalog and definition resources |

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

## Resource generation ownership

`ResourceCatalog` validates stable resource, tool and item IDs plus biome weights, durability, spacing and drop bounds. `ResourceGenerator` evaluates one jittered candidate per global 2×2 tile cell. A candidate is accepted only when its stable rank wins every conflicting neighbor within the larger of their configured spacing radii. Because selection reads global cells rather than adjacent chunk objects, the result is independent of request order and remains valid across negative chunk borders.

Accepted coordinates, resource codes and visual variants are packed into `ChunkData` and its checksum. Water rejection happens before selection. `ResourceChunkLayer` creates one shared-atlas `TileMapLayer` per active chunk; it does not create a `Node2D` for every resource. Solid atlas entries carry collision polygons, while hit feedback swaps only the affected cell to a temporary highlighted atlas row.

## Resource interaction ownership

`ChunkStreamManager` performs proximity queries against active chunk data and delegates hit rules to `ResourceHarvestState`. The state layer owns partial durability, collected keys and the slot inventory. A collected key is never resolved twice and remains hidden when the chunk renderer is recreated. V0.7 serializes resource differences; V0.8 replaces bridge counts with exact slot/stack persistence.

`WorldDropPool` preallocates 32 visual objects. Destroyed resources resolve bounded item stacks from the stable resource key, then activate or merge a pooled object. Nearby mature drops return to the pool after automatic pickup. `ResourceHud` receives prompt, tool, inventory and feedback events; it never calculates harvest rules.

## Item and inventory ownership

`data/items.json` is the canonical source for unique item IDs, presentation, category and stack limit. `ItemCatalog` validates it and materializes immutable `ItemData` resources. Resource drops reference those IDs but do not duplicate item definitions.

`InventoryModel` is a pure `RefCounted` value model with 24 ordered slots; the first eight slots are also the hotbar. Add, move/combine, split, discard and sort operations mutate only validated slot dictionaries and expose conservation-friendly return values. `InventoryPanel` translates drag, right-click and button input into manager API calls; it never owns stack rules. A pooled ground drop is decremented only by the quantity the inventory confirms, so a full inventory leaves the remainder active in the world.

Durable items are individual stack-size-one slot objects with an integer `durability` field. Sorting preserves each instance, discarding carries the field into `WorldDropPool`, and pickup passes it back to the inventory. `ChunkStreamManager` derives the active tool from the selected hotbar slot, applies catalog power only when the resource accepts that tool kind, then consumes one durability for an accepted hit. A broken tool is removed exactly once.

## Crafting ownership

`data/recipes.json` defines stable station IDs, ingredients, outputs and discovery requirements. `RecipeCatalog` validates every station, material, output and unlock item against the canonical item catalog. `CraftingSystem` owns discovery state and crafting rules; `CraftingPanel` displays recipe views and forwards a recipe ID without changing inventory data directly.

Each craft clones the complete inventory, deducts inputs and adds output on that clone, then commits the normalized snapshot only when every operation succeeds. Insufficient materials, a missing station, a locked recipe or missing output capacity therefore leaves the original slots byte-for-byte unchanged. V0.9 models workbench and campfire availability by possession of their station item; placement in the world remains a later building-system responsibility.

## Combat ownership

`data/weapons.json` is the canonical source for stable weapon IDs, damage, attack speed, range, hitbox width, active duration, knockback, stamina cost and combo multipliers. `WeaponCatalog` validates weapon values and sword-item references. `AttackSequenceModel` owns cooldown/combo timing, normalized facing and the per-attack set of already-hit target instance IDs; it has no scene-tree dependency.

`PlayerCombatController` translates an accepted attack into a short-lived `Area2D` rectangle on collision mask 4/“Enemy”. It sends an immutable attack payload only to bodies implementing `receive_attack`. Target damage remains target-owned and uses `DamageCalculator`; the controller consumes sword durability only after the first accepted contact. `CombatHud` displays event data and owns no damage or timing rules.

`PlayerCombatState` owns defense, hit invulnerability, death count, alive/dead status and safe respawn position. `PlayerCharacter` owns health and physical knockback, granting roll invulnerability through the state API. A lethal result emits one death event; `world_sandbox.gd` asks the stream manager to deposit inventory, respawns the player synchronously and requests a persistence update.

`GraveModel` owns a versioned list of graves and transfers normalized inventory snapshots transactionally. `ChunkStreamManager` renders the small set of grave markers, prioritizes nearby grave interaction over resource interaction and includes grave state in persistence. Partial reclaim retains every unaccepted remainder inside the grave.

## Persistence ownership

`SaveManager` is an autoload because it must survive scene changes and join outstanding file tasks at shutdown. It owns world selection, schema validation, immutable save snapshots and last-error state. It never asks `PlayerCharacter` to write a file: the player and resource systems expose plain dictionaries, and `world_sandbox.gd` orchestrates the save request.

`SaveWriteJob` receives a deep-copied snapshot and performs JSON transaction writes and backup copies on `WorkerThreadPool`. It owns no nodes and calls no UI or gameplay APIs. Completion returns duration, difference-file count and an actionable error; `SaveManager` publishes that result on the main thread.

World metadata, player attributes and generated-world differences are separate documents. Collected resource keys are grouped by mathematical chunk coordinate. Only groups with at least one permanent change are written, so visiting or unloading an unmodified chunk cannot create a save file. See `docs/save-format.md` for the normative schema.

Save format 5 adds player combat state and versioned grave snapshots to the format-4 inventory/crafting data. Format-2 count dictionaries, format-3 inventory-schema-1 documents and format-4 crafting documents are accepted only by explicit migration paths and are committed as format 5 on the next save. Generation stays at format 4 because combat does not alter deterministic base-world bytes.
