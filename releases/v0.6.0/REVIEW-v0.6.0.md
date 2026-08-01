# V0.6.0 Self Review

Status: **PASS after fixes**

## Findings and resolutions

| Finding | Resolution |
|---|---|
| Per-resource scene nodes would scale poorly across 25 active chunks | Batch resources and solid collisions in one shared-atlas `TileMapLayer` per chunk |
| Minimum spacing can fail at seams if each chunk places resources independently | Compare candidates in signed global cells and use stable conflict ranks across neighboring cells |
| Resource `TileData` initially reported zero physics layers | Register the atlas source with its owning `TileSet` before creating collision polygons |
| A failed custom assertion can still leave Godot with exit status zero | Parse the final assertion summary and reject any non-zero failed count in `run_tests.sh` |
| Player spawn could coincide with a new resource | Exclude all chunk resource coordinates in `find_land_near` |
| An unbounded drop scene would leak nodes under repeated harvesting | Preallocate 32 objects, reuse collected entries and merge matching stacks at capacity |
| Local X11 sockets remain blocked | Inspect an exact-data resource map and retain scene smoke, collision and HUD containment checks |

## Review conclusion

- Resource generation reads only seed, validated catalogs and signed global coordinates.
- Candidate selection has no shared random stream and does not depend on chunk request order.
- Deep and shallow water are rejected before resource classification.
- Five resource types obey their biome rules and cross-chunk minimum distances.
- `ChunkData` resource bytes are worker-safe and included in the generation-v4 checksum.
- Solid resources expose collision without a `Node2D` allocation for every resource.
- Tool checks, durability, drops and quantities belong to the gameplay state rather than UI code.
- A collected key cannot resolve twice and remains hidden after renderer recreation.
- Drop visuals are bounded by a fixed reusable object pool.
- Resource configuration and both JSON catalogs are included in exports.

No release-blocking issue remains.
