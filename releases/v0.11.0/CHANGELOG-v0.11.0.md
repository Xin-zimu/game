# V0.11.0 - Basic enemies

Released locally on 2026-08-02.

## Added

- Data-driven enemy catalog for slime, wolf and cave bat, including biome rules, combat stats, movement profiles and canonical drops.
- Reusable enemy base and deterministic eight-state AI: `IDLE`, `WANDER`, `ALERT`, `CHASE`, `ATTACK`, `HURT`, `RETURN` and `DEAD`.
- Deterministic chunk enemy candidates with a global active cap, per-chunk cap, respawn cooldown, screen exclusion and minimum spawn radius.
- Distance-based AI sleeping and despawning, plus bounded candidate-cache retention.
- World-collision avoidance, player/enemy combat integration and bounded drop-pool delivery.
- Enemy HUD with population, species and state diagnostics.
- Stable inventory items for slime gel, wolf pelt and bat wing.

## Compatibility

- Game version: 0.11.0
- Save format: 5 (unchanged)
- Generation format: 4 (unchanged)
- Active enemies and respawn cooldowns are session state; picked drops persist through inventory schema 2.

## Verification

- 377 automated checks passed, 0 failed.
- Structural verification, import, main/game scene smoke and Windows export passed.
- Exact 1280×720 enemy-system reconstruction inspected with no clipping.
