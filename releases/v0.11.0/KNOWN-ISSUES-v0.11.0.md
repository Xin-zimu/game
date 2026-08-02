# V0.11.0 Known Issues

- Cave generation does not exist yet, so cave bats use a documented mountain-surface spawn rule.
- Enemies use local steering and collision tangents rather than full navigation meshes; they may take an indirect route around complex concave obstacles.
- Active enemy positions, health and respawn cooldowns are intentionally session-only and are regenerated after loading a world.
- The Windows build is cross-exported and PE-validated on Linux; native Windows runtime smoke testing remains a downstream release check.
- The current environment cannot provide an interactive X11 gameplay capture, so the checked-in 1280×720 visual is an exact data-driven reconstruction backed by scene and integration tests.
