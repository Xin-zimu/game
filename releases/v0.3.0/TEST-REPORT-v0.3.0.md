# V0.3.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 24 required files, all autoloads, game 0.3.0 and generation version 2 present |
| Godot import | PASS - Godot 4.7.1 imported all generation and TileMap resources without script errors |
| Automated suite | PASS - 47 passed, 0 failed |
| Stable text seed | PASS - `无尽边境` maps to `6266252184503203218` |
| Restart determinism | PASS - chunk `(-1,-4)` reproduces checksum `c7ca6bcf93667cd9` and exact tile bytes |
| Request ordering | PASS - chunks requested A→B and B→A produce the same individual checksums |
| Negative coordinates | PASS - floor division, positive local modulo, round trip and signed keys verified |
| Terrain coverage | PASS - 1024 terrain bytes and 1024 elevation bytes; all four V0.3 terrain classes represented |
| Coast cleanup | PASS - zero isolated interior single-category tiles in the showcase chunk |
| TileMapLayer | PASS - terrain and noise modes each render 1024 cells |
| Main/game scene smoke | PASS - both scenes started and exited without engine/script errors |
| Visual render | PASS - actual terrain and noise frames inspected; glyphs, HUD, coastline and layers correct |
| Linux exported build | PASS - release binary started headlessly and exited cleanly |
| Windows export | PASS - 64-bit PE release executable generated successfully |

## Commands

```bash
GODOT_BIN=/path/to/Godot_v4.7.1-stable_linux.x86_64 tools/run_tests.sh
godot --headless --path . --export-release "Windows Desktop" build/windows/InfiniteFrontier.exe
godot --headless --path . --export-release "Linux/X11" build/linux/InfiniteFrontier.x86_64
build/linux/InfiniteFrontier.x86_64 --headless --quit-after 3
GODOT_BIN=/path/to/godot tools/build_release.sh
```

The Windows binary is cross-exported and validated as a 64-bit PE executable. Runtime smoke testing uses the equivalent Linux release template because the build environment is Linux.
