# V0.8.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 48 required files, version 0.8.0, save format 3 and generation format 4 present |
| Godot import | PASS - item resources, inventory model/UI, migration and scenes compile without warnings/errors |
| Automated suite | PASS - 227 passed, 0 failed |
| Item data | PASS - five unique IDs, material/food categories and per-item stack limits validated |
| Inventory capacity | PASS - exactly 24 ordered slots and eight hotbar slots |
| Stack creation | PASS - wood 55 resolves to 50 + 5 with zero remainder |
| Drag swap | PASS - unlike stacks swap and complete totals remain identical |
| Drag combine | PASS - like stacks combine only into configured capacity |
| Stack split | PASS - 50 divides into 25 + 25; total remains 50 |
| Discard | PASS - exact requested stack quantity is returned and removed once |
| Sort | PASS - category sort/consolidation preserves all item totals |
| Full inventory | PASS - 24 full wood stacks reject stone 1 with explicit remainder 1 |
| Ground remainder | PASS - refused pickup keeps the exact active world-drop quantity |
| Snapshot validation | PASS - over-limit stack 51/50 is rejected |
| In-memory round trip | PASS - ordered snapshot and SHA-256 checksum are identical after restore |
| Disk round trip | PASS - player JSON reload normalizes to identical integer slot/order data |
| Format-2 migration | PASS - real V0.7 metadata/player/chunk documents load and preserve wood 7/stone 3 |
| Migration commit | PASS - next save writes both world and player documents as format 3 |
| Sparse differences | PASS - unmodified world has zero files; two removals create exactly two files |
| Inventory UI | PASS - 24 drag-capable grid nodes, eight hotbar nodes and split/discard/sort controls |
| Visual evidence | PASS - 1280×720 24-slot/hotbar reconstruction inspected with clear labels and no clipping |
| Existing world suite | PASS - generation-v4 checksum, seams, biomes, resources, collision, pools and saves unchanged |
| Runtime font | PASS - 410 required runtime/data/test characters, 0 missing from 415-character cmap |
| Main/game scene smoke | PASS - both scenes start and exit without engine/script errors |
| Linux exported build | PASS - release binary starts, reports V0.8.0 and exits cleanly |
| Windows export | PASS - 64-bit PE release executable generated successfully |
| Exported data | PASS - `biomes.json`, `resources.json` and `items.json` are packed |

```bash
GODOT_BIN=/path/to/godot tools/run_tests.sh
GODOT_BIN=/path/to/godot tools/build_release.sh
```

The Windows executable is cross-exported and PE-validated on Linux. Runtime smoke testing uses the equivalent Linux release template.
