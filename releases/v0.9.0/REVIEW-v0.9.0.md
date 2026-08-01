# V0.9.0 Self Review

Status: **PASS after fixes**

## Findings and resolutions

| Finding | Resolution |
|---|---|
| Deducting materials before checking output space could consume inputs on failure | Perform every craft on a cloned inventory and commit only the complete successful snapshot |
| Recipes could reference misspelled stations or items | Validate unique station/recipe IDs and every input, output and unlock item at catalog load |
| Two worn copies of one tool cannot share a stack durability value | Enforce stack size one for durable items and store durability on each slot object |
| Sorting could merge tools with different wear | Preserve and order durable slot objects individually while consolidating only non-durable stacks |
| Ground discard/pickup could reset worn tools | Carry durability as drop metadata through the exact accepted-quantity transfer |
| A button closure inside a recipe loop could invoke the wrong recipe | Bind each immutable recipe ID into its handler when the row is created |
| V0.8 saves contain no crafting state or durability schema | Accept format 3/schema 1 explicitly, normalize slots, and initialize discovery during migration |
| Local X11 sockets remain blocked | Use an exact 1280×720 crafting progression visual plus UI containment and scene smoke tests |

## Review conclusion

- Insufficient materials, locked recipes, unavailable stations and full output capacity leave inventory state unchanged.
- Successful crafting deducts each declared material exactly once and adds the declared output quantity.
- Stone axe/pickaxe power reduces matching resource durability by two per accepted hit; wooden tools reduce it by one.
- Accepted resource hits consume one equipped-tool durability, and zero durability removes that instance exactly once.
- Discovery remains after inputs are consumed and restores from disk in sorted stable-ID form.
- Save-format-2 counts and format-3 ordered slots migrate without changing generation format 4.
- Workbench/campfire world placement, sword attack behavior and food consumption were intentionally not pre-implemented beyond V0.9 scope.

No release-blocking issue remains.
