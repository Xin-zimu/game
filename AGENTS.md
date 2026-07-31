# Codex Project Rules

1. Read `README.md`, this file, `CHANGELOG.md`, `docs/architecture.md`, the prior test report and current Git status before modifying a version.
2. Implement only the active version. Do not pre-implement later roadmap features.
3. Every version must start, run and pass its completion gate before the next version begins.
4. World generation must be deterministic and independent of generation order.
5. Never use a shared global random stream for generated world content.
6. Generation code must not access the player node or mutate the scene tree.
7. Persist generated-world differences, not complete unmodified chunks.
8. Do not create one `Node2D` per terrain tile.
9. Worker threads may return pure data but may not change the Godot scene tree.
10. Every new core algorithm needs an automated test or a focused verification scene.
11. Static game content should be data-driven and use stable, unique IDs.
12. UI scripts must not implement generation or combat rules.
13. Errors must be explicit and actionable; never silently swallow failures.
14. Increment `SAVE_VERSION` when the save format changes.
15. Increment `GENERATION_VERSION` when generation changes incompatibly.
16. Coordinate and chunk logic must handle negative world coordinates.
17. Test chunk seams and cross-chunk structures.
18. Do not hard-code showcase world results.
19. Update README, changelog, development log, test report, review and known issues for each release.
20. Never declare a gate passed without recording the exact check and its result.
