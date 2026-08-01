# V0.8.0 Release Notes

V0.8.0 begins the second project stage with a complete item-and-backpack foundation.

## Player-visible changes

- Press `I` or `Tab` to open a 24-slot backpack; the first eight slots remain visible as the hotbar.
- Press `1–8` or click a hotbar slot to select it.
- Drag an occupied slot onto an empty slot to move it, an unlike item to swap, or a like item to combine up to its limit.
- Right-click a stack or use “拆分一半” to move half into the first empty slot.
- Select a stack and use “丢弃整组” to place it back in the world.
- Use “按分类整理” or `R` while the backpack is open to consolidate and sort items.
- When the backpack is full, unaccepted pickups remain visibly on the ground and a clear warning is shown.

## Data and storage changes

- `data/items.json` defines stable unique item IDs, material/food categories, colors and per-item stack limits.
- Inventory state contains exactly 24 ordered slots, eight hotbar slots and the selected hotbar index.
- Save format advances to 3; generation remains 4.
- V0.7 save-format-2 count dictionaries migrate explicitly into validated V0.8 stacks and commit as format 3 on the next save.
- JSON-loaded numbers are normalized through the inventory model so a save/load round trip produces an identical typed snapshot and checksum.

## Controls

- `I` / `Tab`: open or close backpack.
- `1–8`: select a hotbar slot.
- `R`: sort while the backpack is open.
- Mouse drag: move, combine or swap stacks.
- Right mouse button: split an occupied stack in half.
- Existing `E`, `Q`, `Ctrl+S`, `N`, `B`, movement and return controls remain unchanged.
