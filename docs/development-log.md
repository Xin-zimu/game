# Development Log

## V0.3.0 - Deterministic single-chunk generation

- Added stable SHA-256-derived 64-bit seeds and independent domain/chunk seed derivation.
- Added signed tile, chunk, local and pixel coordinate conversion with negative-boundary regression tests.
- Added `ChunkData` as the scene-independent output of a multi-scale FastNoiseLite terrain generator.
- Rendered a 32×32 chunk through one `TileMapLayer` using a generated nearest-neighbour pixel atlas.
- Added deep water, shallow water, beach and land thresholds plus global-neighbour cleanup.
- Added `R` regeneration, `N` terrain/noise switching, a generation HUD and two actual render captures.
- Raised the generation format version from 1 to 2.

### Iteration findings

- `namespace` is reserved in GDScript 4.7; the initial parameter name prevented class registration and was renamed to `seed_domain`.
- The first fixed negative chunk happened to be entirely land, so a deterministic four-terrain fixture at `(-1, -4)` was selected through data probing rather than hard-coded tile output.
- Visual review exposed one isolated shallow-water cell; global neighbour-majority cleanup removed it, and a zero-isolated-cell regression was added.

### Decisions

- Text seeds use the first 63 bits of SHA-256 so results do not depend on Godot's default hash implementation.
- Generation algorithms use continuous world coordinates; they do not seed a shared random sequence or depend on requested chunk order.
- Rendering and generation remain separate so V0.4 can schedule pure data without touching the scene tree from workers.
- V0.3 renders exactly one chunk. Multi-chunk streaming is deliberately not pre-implemented.

## V0.2.0 - Player movement and camera

- Replaced the static game shell with a playable movement sandbox.
- Added eight-direction walk, run and roll states with health and stamina models.
- Kept velocity math in a pure helper and verified equivalent distance at 30, 60 and 120 FPS.
- Added physics obstacles, a pixel-aligned smooth camera and camera/world limits.
- Added a gameplay HUD and expanded the bundled CJK font subset for the new labels.
- Added an independent game-scene smoke test and made any Godot script error fail the release gate.
- Captured and inspected an actual 1280×720 OpenGL gameplay frame before packaging.

### Decisions

- `CharacterBody2D` is the authoritative movement and collision body.
- Player state is explicit (`IDLE`, `WALK`, `RUN`, `ROLL`) rather than inferred by UI code.
- The V0.2 terrain and avatar are code-drawn validation art so later world-generation work does not inherit temporary asset dependencies.
- The movement sandbox remains finite until deterministic generation and chunk streaming arrive in V0.3 and V0.4.

## V0.1.0 - Engineering skeleton

- Selected Godot 4.7.1 stable and GDScript.
- Created the public repository foundation and standard project structure.
- Added the boot menu, game-shell scene, settings persistence, bounded file logging, global event bus and lifecycle manager.
- Added a runtime debug panel, headless test entry point and structural verification script.
- Added a shared Noto Sans CJK SC UI font subset after the first visual render exposed missing Chinese glyphs; the subset is kept offline and expanded with each content release.
- Added automated containment checks after visual QA exposed a long-label overflow risk.
- Kept gameplay and procedural generation out of this version as required by the staged plan.

### Decisions

- The base viewport is 1280×720. Pixel assets use nearest-neighbour filtering.
- The compatibility renderer is the default to support more Windows computers.
- Core content uses stable IDs and separate save/generation version numbers from the beginning.
- Generated and downloaded binaries are release assets rather than source-controlled files.
