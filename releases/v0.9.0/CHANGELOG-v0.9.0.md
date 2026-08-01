# V0.9.0 Release Notes

V0.9.0 adds the first complete material-to-tool progression loop: gather branches and fiber, make wooden tools by hand, collect wood and stone, then unlock workbench, campfire and stone equipment.

## Highlights

- Ten validated recipes across hands, workbench and campfire stations.
- Discovery-based recipe unlocks and a dedicated `C` crafting panel.
- Exact transactional material deduction with no loss on rejection.
- Wooden and stone axes, pickaxes and swords with individual durability.
- Correct-tool power changes gathering speed; broken tools are removed once.
- Workbench, campfire, torch and cooked-berry outputs.
- Durability-preserving inventory sort, discard, ground pickup and disk restore.
- Explicit save-format-2 and format-3 migration into save format 4.

## Compatibility

- Game version: `0.9.0`
- Godot version: `4.7.1-stable`
- Save format: `4`
- Generation format: `4` (unchanged)
- Inventory schema: `2`
- Crafting-state schema: `1`

V0.7 and V0.8 local worlds are accepted through explicit validation and migration. Unsupported or damaged data is rejected rather than overwritten.
