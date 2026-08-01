# V0.5.0 Known Issues

- Biomes currently affect terrain color and diagnostics only; biome-specific resources and interactions arrive in V0.6.0.
- Biome configuration is read when a generator is created; changing JSON while the game is running requires restarting the world.
- Temperature is noise-driven with altitude cooling rather than a finite-world latitude model because the surface is infinite.
- The release visual is a headless exact-data biome map because the build sandbox blocks local X11 sockets; the game and HUD still pass runtime and geometry tests.
- Cached chunks still contain generated data only; persistent player modifications arrive with V0.7.0.
- The Windows executable is cross-built and PE-validated on Linux. Native Windows runtime verification remains a downstream release task.
