# V0.10.0 Release Notes

V0.10.0 completes the planned player-side melee combat milestone without pre-implementing V0.11 enemy AI.

## Highlights

- Data-driven unarmed, wooden-sword and stone-sword combat definitions.
- Normal attacks and three-step combos with cooldown and stamina gates.
- Short-lived direction-following `Area2D` attack collision.
- One hit per target per attack ID, even across repeated overlap callbacks.
- Defense-aware damage, knockback, hit invulnerability and roll invulnerability.
- Sword durability charged exactly once on the first accepted contact.
- Death count, safe respawn, respawn protection and persistent multi-grave recovery.
- Training target/hazard and combat weapon/combo/cooldown/grave HUD.

## Compatibility

- Game version: `0.10.0`
- Godot version: `4.7.1-stable`
- Save format: `5`
- Generation format: `4` (unchanged)
- Inventory schema: `2` (unchanged)
- Crafting, combat and grave state schemas: `1`

V0.7–V0.9 local worlds are accepted through explicit validation and migration. Unsupported or damaged data is rejected rather than overwritten.
