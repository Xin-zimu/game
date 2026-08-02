# V0.11.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 73 required files; version 0.11.0, save format 5 and generation format 4 present |
| Godot import | PASS - enemy catalog, planner, FSM, runtime actors, director and HUD compile without warnings/errors |
| Automated suite | PASS - 377 passed, 0 failed |
| Enemy data | PASS - three unique IDs, valid biomes/stats/profiles and canonical drop references |
| AI state coverage | PASS - all eight planned states plus terminal death and single-fire attack semantics |
| Deterministic spawning | PASS - restart-stable signed-chunk candidates; land-only, biome-valid and unique |
| Population limits | PASS - 18 active globally, 3 per chunk and 49 retained candidate chunks |
| Spawn safety | PASS - candidates activate outside the expanded viewport and beyond the 760-pixel minimum |
| Far simulation | PASS - complex FSM work sleeps beyond 920 pixels and actors despawn beyond 1700 pixels |
| Collision | PASS - a ground enemy cannot sustain movement through a world wall |
| Combat loop | PASS - player damages enemy; enemy damages player; lethal hit emits one drop transaction |
| Drop integration | PASS - slime gel, wolf pelt and bat wing resolve through the bounded world drop pool |
| Existing world suite | PASS - generation-v4 checksum, seams, biomes, resources, crafting and saves remain stable |
| Enemy UI | PASS - population/type/state diagnostics stay inside the 1280×720 viewport |
| Runtime font | PASS - all 496 required source/data/test characters are present |
| Main/game scene smoke | PASS - both scenes start and exit without engine/script errors |
| Visual evidence | PASS - exact 1280×720 enemy-system reconstruction inspected with no clipping |

```bash
GODOT_BIN=/path/to/godot tools/run_tests.sh
GODOT_BIN=/path/to/godot tools/build_release.sh
```
