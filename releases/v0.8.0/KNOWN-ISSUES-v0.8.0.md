# V0.8.0 Known Issues

- The hotbar stores and selects items but V0.8 does not yet “use” food or equip inventory tools; those actions belong to later gameplay versions.
- Crafting recipes, workbench, campfire and tool durability remain V0.9 scope.
- Right-click split targets the first empty slot. Choosing an arbitrary destination is available by dragging the resulting stack.
- Discard currently removes the selected whole stack through the button; partial discard can be achieved by splitting first.
- V0.7 migration accepts only known item IDs that fit the current 24-slot capacity. Invalid legacy data is rejected with a migration error rather than truncated.
- The release visual is an exact-data/layout reconstruction because the build sandbox blocks local X11 display sockets; runtime node counts, containment and both scenes are still automated.
- The Windows executable is cross-built and PE-validated on Linux. Native Windows runtime verification remains a downstream release task.
