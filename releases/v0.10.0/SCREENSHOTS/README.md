# V0.10.0 Visual Evidence

`player-combat-and-grave.png` is a 1280×720 exact-data/layout reconstruction of the V0.10 runtime UI; the adjacent SVG is its editable vector source. It shows:

- a right-facing stone-sword swing and its short-lived rectangular hitbox;
- the training target, health reduction, attack ID and one-hit rule;
- weapon, combo, cooldown and sword-durability state;
- incoming training damage, hit invulnerability and directional knockback;
- death inventory transfer, safe respawn and persistent grave recovery flow;
- the gameplay health/stamina, hotbar and interaction context.

The image is inspected at original resolution for text rendering, containment, direction clarity and overlap. A direct X11 capture is unavailable because the build sandbox blocks local display sockets; the real controller/target integration test, runtime physics nodes and scene smoke tests cover the executable path.
