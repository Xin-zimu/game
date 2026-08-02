# V1.1.0 test report

Date: 2026-08-03  
Status: PASS

## Automated gates

- Structural verification: 88 required paths and invariants passed.
- Godot automated suite: 430 passed, 0 failed.
- Resource import: passed.
- Main menu smoke test: passed.
- Game scene smoke test: passed.
- Script/runtime error, crash and ObjectDB leak gates: passed.
- Three consecutive generation stress runs: passed after the typed biome-rule fix.

## Requirement evidence

- Dawn/day/dusk/night: configuration and boundary tests passed; five actual GPU screenshots reviewed.
- Environment color: smooth transition test and phase screenshots passed.
- Torch lighting: shader activation test and `night-torch.png` passed visual review.
- Night enemies: phase filtering and 27-enemy cap tests passed; night HUD capture shows the raised cap.
- Night resource: moonflower hidden-at-dawn/visible-at-night runtime tests passed; night capture shows moonflowers.
- Time persistence: existing save round-trip preserves exact `game_time_seconds`; save format remains 6.

## Windows build

- Engine: Godot 4.7.1 stable
- Target: Windows x86_64
- Exported-program smoke test: passed
- Executable SHA-256: `FA98D2EB0106BF280F2036760B7054E6597C383520F4787180181F75ECB08EF7`
- Windows ZIP SHA-256: `CE6F2B713CF4019168552E47266194E270B0BDF84D6537440D0C8A7DBCE672A5`

## Compatibility

- Game version: 1.1.0
- Save format: 6 (unchanged)
- Generation format: 4 (unchanged)
- V1.0.1 resource keys, collected resources and saves remain valid.
