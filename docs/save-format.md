# Save Format Contract

## Version

- Game version: `0.9.0`
- Save version: `4`
- Generation version: `4`
- Inventory schema: `2`
- Crafting-state schema: `1`
- Storage root: `user://saves`

Save and generation formats are independent. Save version 4 adds individual tool durability and persistent crafting discoveries without changing deterministic world generation. Versions 2 and 3 are accepted only by the documented migration paths; any other save version or a mismatched generation version is rejected with a file-specific error.

## Directory layout

```text
saves/
└── world_<stable-local-id>/
    ├── world.json
    ├── player.json
    ├── chunks/
    │   └── surface/
    │       └── <chunk_x>_<chunk_y>.json
    └── backups/
        └── backup-<unix-time>-<suffix>/
            ├── world.json
            ├── player.json
            └── chunks/surface/*.json
```

The directory ID is local and collision-resistant; the player-facing name remains in metadata. Paths never use the unsanitized world name.

## World metadata

`world.json` is a UTF-8 JSON object:

```json
{
  "save_version": 4,
  "generation_version": 4,
  "game_version": "0.9.0",
  "world_id": "world_123456789",
  "world_name": "无尽边境",
  "seed_text": "无尽边境",
  "seed": 6266252184503203218,
  "created_at": "2026-08-01T14:00:00",
  "last_played_at": "2026-08-01T14:30:00",
  "game_time_seconds": 1800.0,
  "player_layer": "surface"
}
```

The 64-bit seed is stored together with its original text so the UI can reproduce the user's input without recalculating identity.

## Player state

`player.json` stores only player-owned state:

```json
{
  "save_version": 4,
  "position": [-2048.5, 1024.25],
  "health": 73.0,
  "maximum_health": 100.0,
  "stamina": 41.0,
  "maximum_stamina": 100.0,
  "active_tool": "axe",
  "inventory": {
    "schema_version": 2,
    "slot_count": 24,
    "hotbar_slot_count": 8,
    "selected_hotbar_slot": 0,
    "slots": [
      {"item_id": "stone_axe", "quantity": 1, "durability": 23},
      {"item_id": "wood", "quantity": 7},
      {"item_id": "stone", "quantity": 3},
      {}, {}, {}, {}, {}, {}, {}, {}, {},
      {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
    ]
  },
  "crafting_state": {
    "schema_version": 1,
    "discovered_items": ["branch", "fiber", "stone", "wood"]
  }
}
```

The slot array always contains exactly 24 objects in player-defined order. Empty objects represent empty slots; occupied entries reference a known stable item ID and contain `1..max_stack`. Durable items have stack limit one and an integer `durability` in `1..maximum`. Slots 0–7 are the hotbar, and the selected index must be `0..7`.

Crafting discoveries are sorted known item IDs. They persist even after the player consumes or discards the last copy of an item, while loading also discovers any items currently in the inventory. JSON numbers are validated and reconstructed through `InventoryModel` and `CraftingSystem` before gameplay receives a normalized snapshot.

## Chunk differences

Generated terrain, climate, biomes and unmodified resources are never written. A surface chunk file exists only after a permanent change:

```json
{
  "save_version": 4,
  "generation_version": 4,
  "layer": "surface",
  "chunk": [-1, -5],
  "removed_resources": ["-1:-129:0"]
}
```

Resource keys contain signed world tile X, signed world tile Y and stable resource code. On load, the generated chunk is unchanged; `ResourceHarvestState` hides keys listed by the difference layer. This guarantees that deterministic generation remains the source of truth and collected nodes cannot drop twice.

An unmodified world may contain the `chunks/surface` directory but contains zero difference files. The regression fixture modifies exactly two chunks and asserts that exactly two JSON files exist.

## Save lifecycle

- New world: metadata and initial player state are written synchronously before scene entry.
- Automatic save: every 30 seconds while a persistent world is active.
- Manual save: `Ctrl+S`, return to menu, or a normal window-close request.
- Settings: continue to use `user://settings.cfg` through `ConfigFile`.
- Shutdown: outstanding save tasks are joined before process exit.

Runtime state is copied into a small immutable snapshot on the main thread. `SaveWriteJob` writes JSON and copies backups through `WorkerThreadPool`; it never reads players, UI nodes or the scene tree. A completed job publishes its duration and difference-file count through the event bus.

## Transaction and backup rules

Each JSON document is first written to `<name>.tmp`. The prior valid document is moved to `<name>.previous`, the temporary file is committed, and the previous transaction file is removed only after success. If commit fails, the previous document is restored.

Manual saves copy the existing metadata, player document and difference files into a timestamped backup before overwriting. The five newest backup directories are retained. Backup deletion is restricted to descendants of the active world's `backups` directory.

## Corruption behavior

Loading validates readable JSON objects, save version 4 or migratable version 2/3, exact generation version, required metadata, player position/attributes, all inventory slots, durability bounds, crafting state and difference arrays. Parse failures include the filename, parser line and message. The Continue action leaves the player on the menu and displays `SaveManager.last_error`; it never silently starts a new world over damaged data.

## Format-2 and format-3 migration

V0.7 format-2 player documents stored `inventory` as an item-to-count dictionary. V0.9 validates the legacy fields, feeds those counts through canonical stack limits into a 24-slot inventory, assigns no invented tools and initializes crafting discoveries from the restored material slots.

V0.8 format-3 documents already contain 24 inventory slots under schema 1. V0.9 accepts and normalizes those non-durable slots under schema 2, initializes crafting discovery from the known contents and preserves slot order and hotbar selection. Unknown items, over-capacity counts, invalid slots or malformed documents fail with actionable migration errors rather than being truncated.

Both paths update metadata, player state and chunk-difference documents in memory to save format 4 and transactionally commit format 4 on the next save. Migration never changes generation format or recreates unmodified chunks.
