# V0.10.0 Test Report

Status: **PASS**

| Check | Result |
|---|---|
| Structural verifier | PASS - 65 required files, version 0.10.0, save format 5 and generation format 4 present |
| Godot import | PASS - weapon catalog, combat nodes, grave persistence, migrations and scenes compile without warnings/errors |
| Automated suite | PASS - 332 passed, 0 failed |
| Weapon data | PASS - three unique stable IDs with positive damage/speed/range/hitbox/combo values and valid sword references |
| Direction and reach | PASS - normalized facing produces the exact forward hitbox center and rotation |
| Attack cooldown | PASS - early repeated input rejects; valid input inside combo window advances the chain |
| Combo reset | PASS - expired window returns to combo step one |
| Duplicate-hit gate | PASS - one attack ID accepts a target once; a new attack ID can hit it again |
| Real controller integration | PASS - active `Area2D` applies one target hit and one sword durability cost despite repeated contact calls |
| Damage/defense | PASS - documented coefficient produces 17 from attack 20/defense 5 and clamps extreme defense to one damage |
| Knockback | PASS - accepted hits deliver the declared normalized direction and magnitude |
| Invulnerability | PASS - overlapping second hit rejects until the 0.55-second window expires; roll grants protection |
| Death/respawn | PASS - lethal hit enters death once, increments count and completes full-health safe-position respawn |
| Grave deposit | PASS - complete inventory moves out of the player into one positive-ID grave |
| Grave reclaim | PASS - exact wood count and stone-sword durability 71 restore; complete grave is removed |
| Combat disk round trip | PASS - defense 4, protection 0.25, death count 2 and signed respawn point restore exactly |
| Grave disk round trip | PASS - signed position, branch count and damaged sword durability 69 restore exactly |
| Format-2/3 migration | PASS - legacy counts/schema-1 slots normalize and initialize crafting/combat/graves |
| Format-4 migration | PASS - exact crafting discoveries persist while combat/grave defaults initialize |
| Existing world suite | PASS - generation-v4 checksum, seams, biomes, resources, crafting, collision and sparse differences unchanged |
| Combat UI | PASS - weapon/combo/cooldown/grave/feedback nodes remain inside the 1280×720 viewport |
| Visual evidence | PASS - exact 1280×720 melee/respawn/grave reconstruction inspected with no clipping |
| Runtime font | PASS - 458 required runtime/data/test characters, 0 missing from 458-character cmap |
| Main/game scene smoke | PASS - both scenes start and exit without engine/script errors |
| Linux exported build | PASS - release binary starts, reports V0.10.0 and exits cleanly |
| Windows export | PASS - 64-bit PE release executable generated successfully |
| Exported data | PASS - `biomes.json`, `resources.json`, `items.json`, `recipes.json` and `weapons.json` are packed |

```bash
GODOT_BIN=/path/to/godot tools/run_tests.sh
GODOT_BIN=/path/to/godot tools/build_release.sh
```

The Windows executable is cross-exported and PE-validated on Linux. Runtime smoke testing uses the equivalent Linux release template.
