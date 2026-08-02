# V1.2.0 test report

Date: 2026-08-03  
Status: PASS

## Automated gates

- Structural verification: 88 required paths and invariants passed.
- Godot automated suite: 454 passed, 0 failed.
- Resource import, main-menu smoke and game-scene smoke: passed.
- Script/runtime error, crash and ObjectDB leak gates: passed.
- Four actual 1280×720 GPU screenshots were captured and visually reviewed.

## Requirement evidence

- Four weather types: catalog and runtime presentation assertions.
- Regional/biome rules: deterministic selection and ecological restriction assertions.
- Smooth switching: intermediate transition blend assertion.
- Particles/audio: runtime overlay and generated PCM assertions.
- Resource/enemy effects: resolved drop and runtime population-cap assertions.
- Persistence: exact round trip plus explicit format-2-through-6 migrations.

## Windows build

- Engine: Godot 4.7.1 stable
- Target: Windows x86_64
- Exported-program smoke test: passed.
- Executable SHA-256: `820AD4BB8FD0ECC3EB3F14760EBF262DF2B1C5361977997785AF32343C8FE236`
- Windows ZIP SHA-256: `E5DB97AE56B95D030D0FDBE21BCD9037ADFC290863E6AD01135DBB8B4612BA50`

## Compatibility

- Game version: 1.2.0
- Save format: 7
- Generation format: 4 (unchanged)
- Save formats 2–6 are migrated explicitly; existing terrain, inventory, progression and collected-resource keys remain valid.
