# V0.3.0 Known Issues

- Only one fixed 32×32 chunk is instantiated. Dynamic loading, caching and unloading begin in V0.4.0.
- Terrain classes are currently visual/data categories; water traversal rules are introduced by later gameplay systems.
- Terrain thresholds are constants in V0.3.0. A richer in-game tuning panel arrives with later world-generation tooling.
- The pixel atlas is generated in code as validation art and is not final production terrain artwork.
- The Windows executable is cross-built and PE-validated on Linux. Native Windows runtime verification remains a downstream release task.
