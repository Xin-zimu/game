# V1.0.0 - First complete playable build

Released locally on 2026-08-02.

## Added

- Basic persisted day/night cycle and night presentation overlay.
- One seed-deterministic canonical ruin with direction and distance guidance.
- Data-driven small Boss with chase, telegraphed slam, defense, knockback and one terminal defeat.
- One-time ancient-core reward with full-inventory retry and duplicate prevention.
- Persistent ordered milestone state and save-format-2/3/4/5 migrations.
- Day/objective/Boss HUD and locally synthesized PCM sound cues.

## Compatibility

- Game version: 1.0.0
- Save format: 6
- Generation format: 4 (unchanged)
- Inventory schema: 2 (unchanged)
- Milestone schema: 1

## Verification

- 409 automated checks passed, 0 failed.
- Structural verification, import, main/game smoke, Linux smoke and Windows PE64 export passed.
- Exact 1280×720 complete-loop reconstruction inspected with no clipping.
