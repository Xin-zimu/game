# V1.0.0 Known Issues

- V1.0 intentionally has only a basic day/night split; dawn, dusk, full lighting, night enemies and night resources are V1.1 scope.
- The canonical ruin is a single surface landmark and has no interior dungeon yet.
- The guardian uses direct collision-aware pursuit rather than a navigation mesh and may take an indirect path around complex obstacles.
- Procedural sound cues are deliberately minimal; mixing, music and authored sound assets remain later audio work.
- Active enemies and Boss position/health are session-only. Loading a pre-defeat encounter restarts the guardian at full health while preserving completed milestones.
- The Windows build is cross-exported and PE-validated on Linux; native Windows runtime smoke testing remains a downstream release check.
