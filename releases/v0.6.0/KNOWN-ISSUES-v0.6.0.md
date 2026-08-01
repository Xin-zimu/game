# V0.6.0 Known Issues

- Collected resources and inventory persist across chunk unload/reload only for the current run. Disk save, backup and migration arrive in V0.7.0.
- Hands, axe and pickaxe are available as validation tools; obtaining, equipping and degrading crafted tools arrive with later inventory/crafting versions.
- Resource visuals and solid collision shapes are code-generated placeholders pending the later art/content passes.
- Building entrances do not exist in V0.6. Water exclusion and pairwise spacing are enforced now; structure entrance exclusion is added when buildings are generated.
- A full drop pool merges only a matching item stack. If all 32 slots contain different items and none are picked up, one new unmatched drop is rejected with an explicit warning.
- The release visual is a headless exact-data distribution map because the build sandbox blocks local X11 sockets; the game, interaction scripts, collisions and HUD still pass runtime/geometry tests.
- The Windows executable is cross-built and PE-validated on Linux. Native Windows runtime verification remains a downstream release task.
