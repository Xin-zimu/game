# V0.4.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 28 required files, all autoloads and version 0.4.0 present |
| Godot import | PASS - all stream, worker, renderer and overlay classes compile without warnings/errors |
| Automated suite | PASS - 58 passed, 0 failed |
| Active/preload policy | PASS - radii produce exactly 25 and 49 target coordinates |
| Direction priority | PASS - equidistant forward chunk sorts before the chunk behind the player |
| 30-minute-equivalent retention | PASS - 1,800 simulated chunk crossings never exceed the 9×9/81 cache bound |
| Seam coordinates | PASS - adjacent border tiles are consecutive and both sample the same global field |
| Return consistency | PASS - evicted region regenerates checksum `c7ca6bcf93667cd9` |
| Background worker | PASS - task completes with matching WorkerThreadPool task ID and pure `ChunkData` |
| TileMap coordinate bound | PASS - every renderer uses local `Rect2i(0,0,32,32)` and a node world offset |
| Main/game scene smoke | PASS - both scenes start and exit without engine/script errors |
| Warm stream visual | PASS - 25 active + 24 preloaded, 49 cache peak, zero queue/workers, visible seamless boundary |
| Linux exported build | PASS - release binary starts, reports V0.4.0 and exits cleanly |
| Windows export | PASS - 64-bit PE release executable generated successfully |

```bash
GODOT_BIN=/path/to/godot tools/run_tests.sh
GODOT_BIN=/path/to/godot tools/build_release.sh
```

The Windows executable is cross-exported and PE-validated on Linux. Runtime smoke testing uses the equivalent Linux release template.
