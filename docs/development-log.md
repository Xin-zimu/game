# Development Log

## V0.8.0 - Items and inventory

- Added canonical item resources with stable IDs, categories, colors and stack limits.
- Replaced bridge counts with a pure 24-slot model and eight-slot hotbar projection.
- Added conservation-tested add, drag swap/combine, half split, exact discard and category sort operations.
- Added the inventory window, hotbar, selection details and gameplay input integration.
- Changed ground-drop pickup to an accepted-quantity transfer so full inventories leave remainders in place.
- Advanced save format to 3 with normalized ordered-slot snapshots and explicit format-2 migration.
- Expanded the suite from 177 to 227 passing tests, including checksum identity, overflow, migration and UI containment gates.

### Iteration findings

- JSON numbers parse as floating-point Variants. Schema validation alone was insufficient for strict dictionary equality, so load now reconstructs the inventory through `InventoryModel` and exposes an integer-normalized snapshot.
- Deactivating a pooled drop before capacity validation can lose an overflow remainder. The pool now asks a receiver for the accepted quantity and decrements only that amount.
- Duplicating item display data between resource and inventory catalogs risks diverging IDs. `data/items.json` is now canonical and the resource catalog delegates item lookups.

### Decisions

- Slots are ordered and persisted exactly because user hotbar organization is gameplay state.
- The hotbar is a view of slots 0–7, not a second inventory, eliminating cross-container duplication paths.
- Sorting consolidates by stable item ID and category order while proving total conservation in tests.
- V0.8 introduces no recipes, workstations, durability-bearing tools or crafting unlocks; those remain V0.9 scope.

## V0.7.0 - Basic saves and chunk differences

- Added a world-creation overlay with world name and stable text/numeric seed input.
- Added versioned world metadata, player state and sparse surface-chunk difference files.
- Restored signed player position, health, stamina, selected tool, pickup counts and removed resource keys.
- Added 30-second autosave, `Ctrl+S`, return-to-menu and window-close save triggers.
- Added worker-thread writes, atomic temporary/previous transactions, five backups and shutdown task joins.
- Added file/line-specific corruption errors and exact save/generation compatibility checks.
- Added a normative save-format document and a headless difference-state visual.
- Expanded the suite from 148 to 177 passing tests, including empty-world sparsity, exact restore, backup, corruption and dispatch-latency gates.

### Iteration findings

- Godot's warnings-as-errors rejects a local inferred from `Dictionary.get` as Variant; persistence restore values now use explicit `Variant` annotations before shape checks.
- `PackedStringArray` has no `pop_front`; backup pruning copies directory names into a typed `Array[String]` before removing the oldest entry.
- Arbitrary Variant values should not be passed through the `String` constructor during schema validation; `str()` is used only for required non-empty metadata checks.
- A scene compilation failure can leave a prior cached script usable long enough for later assertions to run. The error-aware shell gate correctly rejected that run despite a zero-failure assertion summary.

### Decisions

- V0.7 uses readable JSON for small metadata/player/difference documents; the sparse data model matters more than premature database complexity.
- Save version advances to 2 while generation remains 4 because persistence changed without changing base world bytes.
- The main thread captures state and dispatches; file I/O, transaction replacement and backups run in a worker job.
- Corrupt or incompatible worlds never fall back to a new world automatically.
- The first project stage (V0.1–V0.7) now closes with engineering foundation, movement, deterministic infinite terrain, biomes, resources, interaction and persistence all independently releasable.

## V0.6.0 - Resources and interaction

- Added a validated JSON catalog for five resource nodes, three tools and five item drops.
- Added deterministic global candidate cells with biome weights and pairwise minimum spacing across chunk borders.
- Packed resource codes, local coordinates and variants into worker-safe `ChunkData`; advanced generation format to 4.
- Added a shared resource atlas, physical collision for solid nodes and a temporary hit-highlight row.
- Added nearest-resource prompts, strict tool checks, durability, correct deterministic drops and automatic pickup.
- Added a fixed 32-object drop pool and shared harvest-difference state that prevents duplicate drops after chunk reload.
- Added a dedicated resource/tool/inventory HUD and exact-data resource distribution map.
- Expanded the suite from 99 to 148 passing tests, including water exclusion, five-type coverage, cross-chunk spacing, collision, durability, duplicate-drop and pool-capacity gates.

### Iteration findings

- `TileData` does not expose physics layers until its atlas source has been registered with the owning `TileSet`; source registration now precedes collision polygon creation.
- Godot can exit zero after a failed custom assertion summary. The shell gate now also parses the final `passed/failed` line and rejects any non-zero failure count.
- Advancing the generation format changes domain-derived terrain fields as well as resource bytes, so the V0.6 exact checksum fixture and nearby start-region coverage gate were refreshed together.
- A real X11 gameplay frame remains unavailable in this sandbox. Visual QA uses the same generated `ChunkData` rendered into a 6×6-chunk resource map, plus scene smoke, collision and UI containment tests.

### Decisions

- Resource candidate selection compares stable global ranks, never a shared random sequence or generation order.
- Solid resource collision is batched in one `TileMapLayer` per chunk; drop objects are the only pooled per-object visuals.
- The harvest state stores differences rather than rewriting generated chunks. V0.7 will serialize this state without changing V0.6 generation ownership.
- Building entrances do not exist yet, so the applicable exclusion gate is all deep and shallow water; later structure versions add entrance exclusion zones.

## V0.5.0 - Layered terrain and ecological biomes

- Added independent continentalness, elevation, erosion, temperature, moisture and detail fields.
- Added a validated external biome catalog with nine stable IDs and configurable colors, thresholds, priorities and transition bands.
- Added six land biomes plus coast, ocean and deep ocean to every streamed chunk.
- Expanded `ChunkData` with five new field maps and a biome map; advanced generation format to 3.
- Added terrain, biome, climate and elevation renderer modes and live current-cell diagnostics.
- Added a deterministic headless biome-map renderer for release evidence.
- Expanded the suite from 58 to 99 passing tests, including broad biome coverage, continuity, seams and HUD containment.

### Iteration findings

- `PackedStringArray([...])` is not a valid GDScript constant expression; the stable required-ID list now uses an array literal.
- The original V0.3 showcase coordinate no longer contains all four base terrain categories after the multi-field generation upgrade, so the obsolete single-chunk assertion was replaced by broad coverage and continuity gates.
- The bundled font lacked the new Chinese biome and climate glyphs; the subset was rebuilt from all runtime source strings and reimported before release.
- A real X11 window cannot be opened in the current sandbox because local display sockets are blocked. The new feature was visually verified through a headless, exact-data biome map; HUD layout is covered by containment tests and both scenes pass runtime smoke tests.

### Decisions

- Biome configuration is shipped as JSON and explicitly included in exports.
- Transition bands route threshold edges through configured neighbor biomes before global-neighbour cleanup.
- The release map uses the same `TerrainGenerator.biome_at` path as streamed chunks, not a separate visualization approximation.
- Resource nodes, collection and persistent modifications remain V0.6.0 and V0.7.0 work.

## V0.4.0 - Infinite chunk streaming

- Added active, preload and retention radii of 2, 3 and 4 chunks.
- Added a distance-sorted queue biased toward the player's current movement direction.
- Added four concurrent WorkerThreadPool jobs with mandatory completion joins.
- Added main-thread renderer activation/removal, shared TileSet reuse and bounded local TileMap coordinates.
- Added current/peak cache, queue, worker and memory metrics plus visible boundary debugging.
- Added 1,800-step retention simulation, seam-coordinate/global-field checks, return consistency and worker-ID tests.
- Captured an actual fully warmed 25-active/24-preloaded frame spanning chunk boundaries.

### Iteration findings

- A statically impossible `ChunkData is Node` test was rejected by the GDScript compiler; the test now checks absence of scene-tree APIs.
- `Array.pop_front()` returns Variant, and warning-as-error required an explicit `Vector2i` annotation.
- The expanded font had not been reimported before the first capture, producing missing-glyph boxes despite a correct cmap.
- A TileMap batch covered the first custom boundary draw, so boundaries moved to an independent `Line2D` child layer.
- `PixelCamera._ready()` overwrote pre-tree unbounded zoom configuration; removing that override exposed adjacent chunks correctly.

### Decisions

- Workers never receive players, renderers or scene-tree references.
- Completed jobs outside the current retention radius are joined and discarded rather than inserted into cache.
- The manager waits every outstanding task on shutdown, following WorkerThreadPool's resource contract.
- V0.4 streams only base terrain; biome, decoration and resource activation begin in later versions.

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
