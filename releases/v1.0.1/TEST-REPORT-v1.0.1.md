# V1.0.1 test report

Date: 2026-08-02  
Status: PASS

## Automated gates

- Structural verification: 86 required paths and project invariants passed.
- Godot automated suite: 417 passed, 0 failed.
- Resource import: passed.
- Main menu smoke test: passed.
- Game scene smoke test: passed.
- ObjectDB leak and script/runtime error gates: passed.

## Display verification

Actual Godot 4.7.1 GPU captures were checked at 1280×720, 1920×1080, 2560×1440 and 3440×1440. Exclusive fullscreen was checked at 2560×1440. The world filled each viewport; HUD controls remained inside the viewport; the interaction prompt did not overlap the hotbar.

## Windows build

- Godot: 4.7.1 stable
- Target: Windows x86_64
- Export smoke test: passed
- Executable SHA-256: `4D9F7A61E1FD438FC831F8ED5A60F4FD61201BCB31322CE7CB21CAFFA2C7EB1C`
- Windows ZIP SHA-256: `AC90CF0C67FFBB80EFAB727907E42DF85BCEF1F282E1A8CD2B1AE068B5A718A6`

## Compatibility

- Game version: 1.0.1
- Save format: 6 (unchanged)
- Generation format: 4 (unchanged)
