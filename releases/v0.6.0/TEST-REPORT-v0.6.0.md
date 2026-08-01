# V0.6.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 39 required files, all autoloads, version 0.6.0 and generation format 4 present |
| Godot import | PASS - catalogs, generator, resource atlas, interaction state, drop pool and HUD compile without warnings/errors |
| Automated suite | PASS - 148 passed, 0 failed |
| External configuration | PASS - five stable resource IDs, three stable tools, item/drop references, spacing and per-biome weight bounds validated |
| Water exclusion | PASS - no sampled resource occurs in deep or shallow water |
| Five-type coverage | PASS - tree, rock, grass, flower and berry bush all occur in the 25-chunk deterministic fixture |
| Spawn uniqueness | PASS - 1,155 sampled resource keys are unique |
| Cross-chunk spacing | PASS - pairwise configured minimum distance holds within and across all fixture chunk borders |
| Chunk resource contract | PASS - packed codes, signed-derived local coordinates and variants are deterministic |
| Exact checksum | PASS - seed `无尽边境`, chunk `(-1,-4)` resolves `25b17b18822faa6c` |
| Spawn safety | PASS - initial player spawn excludes generated resource cells |
| Tool and durability | PASS - wrong tools reject damage; correct hits decrease configured durability |
| Correct drops | PASS - tree resolves wood inside 2–4 bounds; no item appears before destruction |
| Duplicate protection | PASS - collected resource keys reject every later hit and emit no second drop |
| Renderer collision | PASS - one shared resource TileMap physics layer and solid-resource collision polygons present |
| Chunk return behavior | PASS - collected key remains hidden when a renderer is recreated |
| Drop object pool | PASS - capacity 2 fixture caps objects, merges matching overflow and returns collected objects |
| Automatic pickup | PASS - only nearby mature drops are collected and merged quantity is preserved |
| Resource HUD layout | PASS - tool and inventory labels remain inside the panel; prompt node exists |
| Stream regression | PASS - 25 active, 49 preload and 81 retained-data limits remain bounded |
| Background worker | PASS - WorkerThreadPool returns pure `ChunkData` and is joined |
| Main/game scene smoke | PASS - both scenes start and exit without engine/script errors |
| Resource debug map | PASS - 576×576 exact-data image generated and visually inspected |
| Linux exported build | PASS - release binary starts, reports V0.6.0 and exits cleanly |
| Windows export | PASS - 64-bit PE release executable generated successfully |
| Exported data | PASS - `res://data/biomes.json` and `res://data/resources.json` are present in both release packs |
| Runtime font | PASS - all 269 required runtime glyphs are present; 0 missing |

```bash
GODOT_BIN=/path/to/godot tools/run_tests.sh
GODOT_BIN=/path/to/godot tools/build_release.sh
godot4 --headless --path . --script res://tools/render_resource_map.gd
```

The Windows executable is cross-exported and PE-validated on Linux. Runtime smoke testing uses the equivalent Linux release template.
