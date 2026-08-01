# V0.7.0 Release Notes

V0.7.0 closes the first project stage with local world creation and persistent generated-world differences.

## Player-visible changes

- New World opens a form for a 1–32-character world name and text or numeric seed.
- Continue loads the most recently played valid local world.
- Position, health, stamina, active tool and collected item counts restore after exit.
- Harvested resources remain removed after saving, exiting and loading again.
- The game automatically saves every 30 seconds. `Ctrl+S`, returning to the menu and normal close create manual save points.
- Save progress reports elapsed write time and number of modified chunk files.
- Damaged or incompatible saves show the exact file and reason instead of silently starting over.

## Storage changes

- Each world owns `world.json`, `player.json`, sparse `chunks/surface/*.json` differences and `backups/`.
- Unmodified generated chunks create zero difference files.
- File writes use temporary/previous transaction names and manual saves retain up to five backups.
- JSON writes and backup copies run in a worker task; the scene tree and player remain main-thread-only.
- Save format advances to 2; generation remains 4.

## Controls

- `Ctrl+S`: manual save with backup.
- `E`: collect nearest resource.
- `Q`: cycle hands / axe / pickaxe.
- `N`: cycle terrain / biome / climate / elevation views.
- `B`: toggle chunk boundaries.
- `WASD`, `Shift`, `Space`, `Esc`: movement, run, roll and save/return.
