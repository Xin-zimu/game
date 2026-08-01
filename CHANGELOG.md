# Changelog

All notable changes are recorded here. Version numbers follow the staged project plan.

## [0.6.0] - 2026-08-01

### Added

- Data-driven resource catalog for trees, rocks, grass, flowers and berry bushes.
- Deterministic global candidate-grid placement with biome rules and cross-chunk minimum spacing.
- Packed resource coordinates, codes and variants in `ChunkData` and generation checksums.
- Shared resource `TileMapLayer` atlas with physical collisions for solid resources.
- Hands, axe and pickaxe selection, proximity prompts, durability and tool validation.
- Hit-flash collection animation, deterministic item stacks and automatic proximity pickup.
- Fixed 32-object drop pool with matching-item overflow merging.
- Session difference state that prevents repeated drops or resource restoration after chunk reload.
- Exact-data 6×6-chunk resource distribution renderer and generation/interaction/pool regression tests.

### Changed

- Generation format advanced from 3 to 4 because resource spawn bytes became part of chunks.
- Project font subset expanded for V0.6 resource, tool, pickup and inventory labels.
- Test runner now treats a non-zero assertion summary as a release failure even if Godot exits zero.
- Export presets continue to include all external JSON catalogs.

### Fixed

- Register the runtime resource atlas with its `TileSet` before adding per-tile collision polygons.
- Player spawn selection now excludes generated resource cells.

## [0.5.0] - 2026-08-01

### Added

- Independently seeded continentalness, elevation, erosion, temperature, moisture and detail fields.
- Data-driven biome catalog loaded from `data/biomes.json` with schema and ID validation.
- Plains, forest, desert, snowfield, swamp, mountain, coast, ocean and deep-ocean biomes.
- Configurable transition bands and global-neighbour majority cleanup for coherent biome borders.
- Per-chunk continental, erosion, temperature, moisture and biome byte maps included in checksums.
- Terrain, biome, climate and elevation debug views plus live climate HUD values.
- Headless deterministic biome-map renderer and continuity/coverage regression tests.

### Changed

- Generation format advanced from 2 to 3 because chunk bytes and terrain fields changed.
- Project font subset expanded for all V0.5 Chinese biome and climate labels.
- Export presets explicitly include the external biome JSON configuration.

### Fixed

- Replaced a non-constant `PackedStringArray` class constant with a valid constant array.
- Added generation-HUD containment tests after expanding diagnostics to two lines.

## [0.4.0] - 2026-07-31

### Added

- Dynamic chunk activation, preloading, sleeping, cache retention and unloading.
- Distance-prioritized queue biased toward the player's movement direction.
- Up to four concurrent WorkerThreadPool jobs that return pure `ChunkData`.
- Main-thread-only creation and removal of per-chunk `TileMapLayer` renderers.
- Shared runtime pixel atlas and local 0–31 TileMap coordinates per renderer.
- Active/preload/cache/queue/worker/peak-memory streaming metrics.
- Toggleable chunk-boundary overlay and unbounded follow camera.
- Seam, return consistency, worker execution and 1,800-step bounded-cache tests.

### Fixed

- Added explicit `Vector2i` typing for queue values returned as Variant.
- Reimported the expanded CJK font subset before visual capture.
- Moved boundary lines above TileMap batches and prevented camera-ready zoom from overriding the streaming view.

## [0.3.0] - 2026-07-31

### Added

- Stable SHA-256-based 64-bit text seeds, numeric seeds and domain-derived seeds.
- Signed world-tile, 32×32 chunk, local-tile and pixel coordinate conversion.
- Pure `ChunkData` generation independent of scene-tree state and request order.
- Multi-scale FastNoiseLite elevation using continental, elevation and detail fields.
- Deep-water, shallow-water, beach and land classification with isolated-cell cleanup.
- Programmatic pixel atlas rendered through one `TileMapLayer`.
- Deterministic regeneration, terrain/noise debug toggle and generation HUD.
- Restart, ordering, negative-coordinate, exact-byte and isolated-cell regression tests.

### Fixed

- Replaced the all-land showcase coordinate with a stable negative-coordinate coastline fixture.
- Applied global-neighborhood majority cleanup to remove isolated shallow-water cells.

## [0.2.0] - 2026-07-31

### Added

- Eight-direction player movement with walk, run and roll states.
- Health and stamina models with bounded damage, healing, drain and recovery.
- Physics obstacles and collision-based movement through `CharacterBody2D`.
- Pixel-aligned smooth camera with finite sandbox limits.
- Gameplay HUD for health, stamina, movement state and world coordinates.
- Code-drawn sandbox terrain, river, particles and placeholder pixel visuals.
- Frame-rate independence, movement normalization, state and resource tests.
- Dedicated game-scene smoke test and error-aware Godot log validation.

### Fixed

- Renamed a helper that conflicted with Godot 4.7's native `draw_ellipse` API.
- Reworked HUD bar sizing to avoid anchor/layout warnings.

## [0.1.0] - 2026-07-31

### Added

- Godot 4.7.1 project skeleton and standard directory layout.
- Pixel-art styled main menu and game-shell scene.
- Event bus, game lifecycle, persistent settings and bounded logging autoloads.
- Runtime FPS, scene and memory debug panel.
- Headless automated tests and repository structural verification.
- Windows and Linux export presets.
- Architecture, development process and release-roadmap documentation.
