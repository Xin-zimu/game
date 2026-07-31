# Development Log

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
