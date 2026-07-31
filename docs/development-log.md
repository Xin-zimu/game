# Development Log

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
