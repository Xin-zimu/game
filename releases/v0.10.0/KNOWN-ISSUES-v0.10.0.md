# V0.10.0 Known Issues

- V0.10 validates player combat against an explicit training target and damage hazard. Slimes, wolves, bats, AI state machines, biome spawn rules and enemy drops begin in V0.11.
- Training fixtures are placed near the player when the gameplay scene starts; they are developer-visible validation fixtures, not procedurally generated world content.
- Melee has no sound asset or screen shake yet; presentation unification remains a later planned version.
- Graves have no minimap marker because the minimap system is not yet implemented. Nearby grave interaction takes priority over resource interaction and the combat HUD shows the current grave count.
- A partially full backpack may reclaim only part of a grave; the unrecovered normalized remainder stays in that grave and can be collected later.
- The release visual is an exact-data/layout reconstruction because the build sandbox blocks local X11 display sockets; real hitbox-controller integration, runtime node geometry and both scenes are automated.
- The Windows executable is cross-built and PE-validated on Linux. Native Windows runtime verification remains a downstream release task.
