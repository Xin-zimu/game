# V0.6.0 Release Notes

V0.6.0 adds deterministic biome-aware resources and a complete first collection loop.

## Player-visible changes

- Trees, rocks, grass, flowers and berry bushes now populate streamed land and coast biomes.
- Press `Q` to switch between hands, axe and pickaxe; press `E` near a resource to collect it.
- The interaction prompt names the required tool and remaining durability.
- Valid hits flash the affected resource. Destroyed resources create bounded item stacks that are automatically picked up nearby.
- A new HUD shows active tool, collected wood/stone/fiber/flowers/berries and interaction feedback.
- Collected resources remain gone for the current session when their chunk unloads and later returns.

## Engineering changes

- `data/resources.json` owns stable resource/tool/item IDs, biome weights, spacing, durability, collision and drops.
- Global candidate cells and stable conflict ranks enforce minimum distance across chunk seams.
- Packed resource bytes participate in generation-v4 checksums.
- Solid resources share per-chunk TileMap collision instead of allocating one scene node per tile.
- A fixed 32-object drop pool merges matching overflow stacks and reuses visuals after pickup.
- The release gate now parses the automated assertion summary in addition to process and engine errors.

## Controls

- `E`: collect nearest resource.
- `Q`: cycle hands / axe / pickaxe.
- `N`: cycle terrain / biome / climate / elevation views.
- `B`: toggle chunk boundaries.
- `WASD`, `Shift`, `Space`, `Esc`: movement, run, roll and return.
