# V0.9.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 53 required files, version 0.9.0, save format 4 and generation format 4 present |
| Godot import | PASS - item/recipe resources, crafting UI, durability, migrations and scenes compile without warnings/errors |
| Automated suite | PASS - 281 passed, 0 failed |
| Item data | PASS - 16 unique IDs across six categories; all durable definitions enforce stack one and positive durability |
| Recipe data | PASS - ten unique recipes and three valid stations; all referenced IDs resolve |
| Insufficient materials | PASS - craft rejects with exact original inventory snapshot retained |
| Successful craft | PASS - each declared input is deducted exactly and declared output is added once |
| Station gates | PASS - hands always available; workbench/campfire require their inventory item |
| Unlock persistence | PASS - discoveries survive consumption and restore in sorted stable-ID order |
| Full-inventory transaction | PASS - missing output capacity rejects without consuming any input |
| Tool power | PASS - stone power 2 reduces matching resource durability faster than wooden power 1 |
| Tool break | PASS - last accepted hit removes the tool and reports breakage exactly once |
| Durable sort | PASS - worn instances remain distinct with exact durability values |
| Durable drop/pickup | PASS - discard metadata and pooled transfer restore the exact worn value |
| Disk round trip | PASS - selected hotbar stone axe restores with durability 23 and normalized integer data |
| Format-2 migration | PASS - legacy count dictionary migrates to inventory schema 2/save format 4 |
| Format-3 migration | PASS - ordered schema-1 slots preserve order/selection and initialize crafting state |
| Existing world suite | PASS - generation-v4 checksum, seams, biomes, resources, collision, pools and sparse differences unchanged |
| Crafting UI | PASS - station tabs, recipe rows and actions remain inside the 1280×720 viewport |
| Visual evidence | PASS - exact 1280×720 progression/crafting reconstruction inspected with no clipping |
| Runtime font | PASS - 439 required runtime/data/test characters, 0 missing from 444-character cmap |
| Main/game scene smoke | PASS - both scenes start and exit without engine/script errors |
| Linux exported build | PASS - release binary starts, reports V0.9.0 and exits cleanly |
| Windows export | PASS - 64-bit PE release executable generated successfully |
| Exported data | PASS - `biomes.json`, `resources.json`, `items.json` and `recipes.json` are packed |

```bash
GODOT_BIN=/path/to/godot tools/run_tests.sh
GODOT_BIN=/path/to/godot tools/build_release.sh
```

The Windows executable is cross-exported and PE-validated on Linux. Runtime smoke testing uses the equivalent Linux release template.
