# V0.8.0 Self Review

Status: **PASS after fixes**

## Findings and resolutions

| Finding | Resolution |
|---|---|
| A hotbar implemented as a second container could duplicate items | Make the hotbar a view of ordered inventory slots 0–7 |
| Removing a pooled drop before knowing accepted capacity could lose overflow | Add accepted-quantity transfer; decrement/deactivate only what the inventory confirms |
| Unchecked drag code could overwrite a target stack | Put all combine/swap rules in `InventoryModel` and conservation-test totals before/after |
| JSON numbers reload as floating-point values | Validate then reconstruct an integer-normalized inventory snapshot |
| V0.7 worlds contain count dictionaries instead of slots | Accept only save format 2 through an explicit capacity-checked migration path |
| Item presentation duplicated in two catalogs could diverge | Make `data/items.json` canonical and delegate resource-drop item lookups |
| Build script attempted restricted `/root` paths | Give release builds the same isolated XDG runtime directories as tests |
| Local X11 sockets remain blocked | Use an exact 1280×720 inventory/hotbar layout visual plus UI geometry and scene smoke tests |

## Review conclusion

- Every static item has one stable ID, one category and a positive stack limit.
- Add, combine, swap, split, discard and sort preserve exact item totals except the explicit discarded quantity.
- A full backpack returns a precise remainder; the matching ground visual retains that remainder.
- Dragging never lets UI code apply stack rules or write slot state directly.
- All 24 slots and hotbar selection persist in order and normalize identically after JSON load.
- Format-2 migration preserves wood/stone totals and commits metadata/player documents as format 3.
- Generation bytes, resource keys and chunk differences remain unchanged at generation format 4.
- V0.9 crafting, workstations and tool durability were not pre-implemented.

No release-blocking issue remains.
