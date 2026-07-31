# V0.2.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 18 required files, all autoloads and version 0.2.0 present |
| Godot import | PASS - Godot 4.7.1 imported resources without script errors |
| Automated suite | PASS - 24 passed, 0 failed |
| Frame-rate independence | PASS - integrated walk distance matches at 30, 60 and 120 FPS |
| Movement normalization | PASS - diagonal walk/run speeds remain bounded |
| Player resources | PASS - damage, healing and stamina remain within declared limits |
| Main scene smoke | PASS - main menu started and exited cleanly |
| Game scene smoke | PASS - player sandbox started and exited cleanly |
| Visual render | PASS - actual 1280×720 OpenGL gameplay frame inspected; glyphs, HUD and layers correct |
| Linux exported build | PASS - release binary started headlessly and exited cleanly |
| Windows export | PASS - 64-bit PE release executable generated successfully |

## Commands

```bash
GODOT_BIN=/path/to/Godot_v4.7.1-stable_linux.x86_64 tools/run_tests.sh
godot --headless --path . --export-release "Windows Desktop" build/windows/InfiniteFrontier.exe
godot --headless --path . --export-release "Linux/X11" build/linux/InfiniteFrontier.x86_64
build/linux/InfiniteFrontier.x86_64 --headless --quit-after 3
```

The Windows binary is cross-exported and validated as a 64-bit PE executable. Runtime smoke testing uses the equivalent Linux release template because the build environment is Linux.
