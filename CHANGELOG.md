# Changelog

All notable changes are recorded here. Version numbers follow the staged project plan.

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
