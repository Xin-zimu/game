# V0.5.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 31 required files, all autoloads, version 0.5.0 and generation format 3 present |
| Godot import | PASS - biome catalog, six-field generator, renderer modes and HUD compile without warnings/errors |
| Automated suite | PASS - 99 passed, 0 failed |
| External configuration | PASS - JSON schema, nine required stable IDs, unique contiguous codes and ordered terrain thresholds |
| Rule selection | PASS - snowfield, desert, swamp, forest, mountain, plains transition fixtures |
| Chunk field contract | PASS - seven 1,024-byte maps and exact checksum `47c1e52c4fe80f9c` |
| Seed/order determinism | PASS - restart, request order, different-seed and return-to-region checks |
| Broad biome coverage | PASS - all nine biomes occur in 4,225 deterministic samples |
| Region continuity | PASS - 94.48% matching orthogonal edges in a 96×96 fixture; 2 isolated cells |
| Cross-chunk seams | PASS - elevation and biome borders sample the same global fields |
| Stream regression | PASS - 25 active, 49 preload targets and 81 retained-data maximum remain bounded |
| Background worker | PASS - WorkerThreadPool task returns pure `ChunkData` and is joined |
| Renderer modes | PASS - terrain, biome, climate and elevation modes each preserve all 1,024 cells |
| HUD layout | PASS - biome/climate and stream diagnostics remain inside the expanded panel |
| Main/game scene smoke | PASS - both scenes start and exit without engine/script errors |
| Biome debug map | PASS - 384×384 exact-data image generated and visually inspected |
| Linux exported build | PASS - release binary starts, reports V0.5.0 and exits cleanly |
| Windows export | PASS - 64-bit PE release executable generated successfully |
| Exported data | PASS - `res://data/biomes.json` is present in both release packs |

```bash
GODOT_BIN=/path/to/godot tools/run_tests.sh
GODOT_BIN=/path/to/godot tools/build_release.sh
godot4 --headless --path . --script res://tools/render_biome_map.gd
```

The Windows executable is cross-exported and PE-validated on Linux. Runtime smoke testing uses the equivalent Linux release template.
