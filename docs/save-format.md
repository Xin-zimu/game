# Save Format Contract

## Version

- Game version: `0.7.0`
- Save version: `2`
- Generation version: `4`
- Storage root: `user://saves`

Save and generation formats are independent. Save version 2 is the first complete world/player/difference format. A world whose save or generation version does not match is rejected with a file-specific error; silent coercion is not allowed.

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
  "save_version": 2,
  "generation_version": 4,
  "game_version": "0.7.0",
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
  "save_version": 2,
  "position": [-2048.5, 1024.25],
  "health": 73.0,
  "maximum_health": 100.0,
  "stamina": 41.0,
  "maximum_stamina": 100.0,
  "active_tool": "axe",
  "inventory": {"wood": 7, "stone": 3}
}
```

The V0.6 item counts are preserved as player attributes. V0.8 replaces this dictionary with the versioned slot/stack inventory model while retaining migration responsibility.

## Chunk differences

Generated terrain, climate, biomes and unmodified resources are never written. A surface chunk file exists only after a permanent change:

```json
{
  "save_version": 2,
  "generation_version": 4,
  "layer": "surface",
  "chunk": [-1, -5],
  "removed_resources": ["-1:-129:0"]
}
```

Resource keys contain signed world tile X, signed world tile Y and stable resource code. On load, the generated chunk is unchanged; `ResourceHarvestState` hides keys listed by the difference layer. This guarantees that deterministic generation remains the source of truth and collected nodes cannot drop twice.

An unmodified world may contain the `chunks/surface` directory but contains zero difference files. The V0.7 regression fixture modifies exactly two chunks and asserts that exactly two JSON files exist.

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

Loading validates readable JSON objects, exact save/generation versions, required metadata, player position/attributes and difference arrays. Parse failures include the filename, parser line and message. The Continue action leaves the player on the menu and displays `SaveManager.last_error`; it never silently starts a new world over damaged data.
