# V0.11.0 Self Review

Status: **PASS after fixes**

## Findings and resolutions

| Finding | Resolution |
|---|---|
| A short test wall allowed a wolf to navigate around its end and looked like penetration | Extended the integration fixture across the full movement corridor; sustained wall crossing is now distinguished from valid pathing around an obstacle |
| Candidate caches could grow during indefinite travel even while active enemies stayed capped | Retain only the current 7×7 preload region after every population update |
| Screen-only exclusion could still place an enemy uncomfortably close at a viewport corner | Require both an expanded-screen exclusion and the configured 760-pixel radial minimum |
| Per-frame AI for distant enemies would scale poorly | Stop complex FSM updates beyond 920 pixels and despawn beyond 1700 pixels |
| Death callbacks could be repeated by overlapping combat paths | Make `DEAD` terminal and guard the defeat/drop transaction so it emits exactly once |
| Bat underground habitat is unavailable before cave generation | Use the explicit mountain surface rule for V0.11 and record the limitation for later cave migration |

## Review conclusion

- Every candidate is deterministic, land-only, biome-valid and bounded to three per chunk.
- Active population never exceeds 18; screen exclusion, respawn cooldown and despawn rules prevent sudden or unlimited spawning.
- All eight planned states are reachable under deterministic tests, and a single attack state cannot damage twice.
- Ground enemies remain blocked by world collision and use a tangent fallback rather than continuously pushing through walls.
- Far enemies stop complex logic and candidate metadata remains bounded during long traversal.
- Player attacks, enemy attacks, death and canonical drops complete one end-to-end combat loop.
- Runtime enemies require no save or world-generation format change.

No release-blocking issue remains.
