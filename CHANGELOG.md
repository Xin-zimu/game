# Changelog

All notable changes are recorded here. Version numbers follow the staged project plan.

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
