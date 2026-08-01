# V0.7.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 43 required files, five autoloads, version 0.7.0, save format 2 and generation format 4 present |
| Godot import | PASS - world UI, save manager, writer job, restore APIs and scenes compile without warnings/errors |
| Automated suite | PASS - 177 passed, 0 failed |
| World creation | PASS - validated name/seed create isolated metadata and player files |
| Metadata | PASS - save/generation/game versions, world name, original seed text and 64-bit seed stored |
| Empty-world sparsity | PASS - new and saved unmodified worlds contain 0 chunk difference files |
| Difference grouping | PASS - two removed resources in two signed chunks create exactly two JSON files |
| Position restore | PASS - `[-2048.5, 1024.25]` restores exactly after manager reset/load |
| Player attributes | PASS - health 73 and stamina 41 restore exactly; maxima also covered by player contract |
| Resource persistence | PASS - both destroyed keys reload and hide generated resources |
| Tool/item restore | PASS - active axe, wood 7 and stone 3 restore with player attributes |
| Duplicate protection | PASS - restored keys remain in `ResourceHarvestState` and cannot resolve drops again |
| Autosave dispatch | PASS - immutable snapshot dispatch below 50 ms on the main thread |
| Background write | PASS - measured fixture write about 1–2 ms and below 500 ms gate |
| Backup | PASS - manual save creates a timestamped recoverable backup directory |
| Corruption handling | PASS - malformed `world.json` is rejected with filename, line and parse reason |
| Version handling | PASS - exact save 2 and generation 4 required for world and difference documents |
| Settings persistence | PASS - `ConfigFile` round trip remains green |
| World creation UI | PASS - name, seed, Continue and overlay nodes exist; main-panel containment remains green |
| Save difference map | PASS - 512×512 exact-data image with 668 remaining and 75 restored removals visually inspected |
| Existing generation/stream/resource suite | PASS - deterministic checksum, seams, biomes, spacing, collision, harvest and pools unchanged |
| Main/game scene smoke | PASS - both scenes start and exit without engine/script errors |
| Linux exported build | PASS - release binary starts, reports V0.7.0 and exits cleanly |
| Windows export | PASS - 64-bit PE release executable generated successfully |
| Exported data | PASS - both external JSON catalogs are present in release packs |
| Runtime font | PASS - every required V0.7 runtime glyph is present |

```bash
GODOT_BIN=/path/to/godot tools/run_tests.sh
GODOT_BIN=/path/to/godot tools/build_release.sh
godot4 --headless --path . --script res://tools/render_save_diff_map.gd
```

The Windows executable is cross-exported and PE-validated on Linux. Runtime smoke testing uses the equivalent Linux release template.
