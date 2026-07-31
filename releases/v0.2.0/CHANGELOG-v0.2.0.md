# V0.2.0 Changelog

V0.2.0 turns the engineering skeleton into a playable movement sandbox. It adds the player state machine, physics movement and collision, smooth camera, gameplay HUD, bounded health and stamina, and a release gate that smoke-tests the game scene itself.

## Player

- Eight-direction walk and run with normalized diagonal speed.
- Roll state with a fixed burst velocity, duration, cooldown and stamina cost.
- Bounded health, damage, healing, stamina drain and stamina recovery.
- Signals for state, health and stamina changes.

## World and presentation

- Finite 2400×1600 collision sandbox with grid terrain, river and ambient particles.
- Static obstacle bodies and code-drawn pixel visuals.
- Pixel-aligned smooth camera constrained to world limits.
- HUD for health, stamina, movement state, coordinates and controls.

## Verification

- Expanded automated suite from 16 to 24 passing tests.
- Added distance-equivalence checks at 30, 60 and 120 FPS.
- Added game-scene smoke testing and fatal log-pattern detection.
- Produced and visually reviewed an actual 1280×720 OpenGL frame.
