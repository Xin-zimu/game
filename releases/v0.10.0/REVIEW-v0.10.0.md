# V0.10.0 Self Review

Status: **PASS after fixes**

## Findings and resolutions

| Finding | Resolution |
|---|---|
| `body_entered` and overlap polling can report one target in the same active window | Register target instance IDs in the current attack before target code runs |
| Durability charged per target could overcharge a wide swing | Charge the equipped sword only on the first accepted contact of each attack |
| Center-distance checks would ignore direction and physical reach | Create a short-lived rectangular `Area2D`, rotate it to normalized player facing and use enemy collision mask only |
| Damage logic in UI/controller could diverge between targets | Keep the documented `max(1, attack - defense × 0.65)` rule in pure `DamageCalculator` |
| A second death could overwrite unrecovered inventory | Persist multiple positive-ID graves rather than one replaceable slot |
| Grave stacks could reset worn weapon durability | Store and validate a complete inventory-schema-2 snapshot per grave |
| Format-4 migration could accidentally erase crafting discoveries | Initialize crafting only below format 4 and combat/graves only below format 5 |
| Local X11 sockets remain blocked | Use an exact 1280×720 combat-state visual plus hitbox integration, containment and scene smoke tests |

## Review conclusion

- Each accepted attack has a unique ID, correct normalized direction, declared cooldown and bounded active window.
- Repeated contacts cannot hit the same target twice; a new attack ID can hit it again.
- Damage and defense obey the documented minimum-one formula; targets receive the declared direction and knockback.
- Hit invulnerability rejects overlapping damage, while a lethal accepted hit increments death count once.
- Death deposits normalized inventory before safe respawn; reclaim preserves quantities, order constraints and durability.
- Format-2/3/4 worlds migrate to format 5 without changing generation format 4.
- Slime/wolf/bat AI, procedural enemy spawning and combat drops remain V0.11 scope.

No release-blocking issue remains.
