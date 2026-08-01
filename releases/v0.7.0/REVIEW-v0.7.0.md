# V0.7.0 Self Review

Status: **PASS after fixes**

## Findings and resolutions

| Finding | Resolution |
|---|---|
| Saving full deterministic chunks would scale with exploration rather than changes | Group only permanent resource-removal keys and skip empty groups entirely |
| File I/O on the gameplay thread could create visible pauses | Deep-copy a small snapshot and run transaction writes/backups in `WorkerThreadPool` |
| A process failure during replacement could destroy the only valid document | Commit through `.tmp` and `.previous`, restoring the prior file if rename fails |
| New/load actions could race a prior world's pending exit save | Flush the outstanding task before replacing current-world state |
| `PackedStringArray.pop_front` does not exist | Copy backup directory names into typed `Array[String]` before pruning |
| Variant inference and arbitrary `String` construction fail under warnings-as-errors | Use explicit `Variant` annotations and schema-aware `str` checks |
| A damaged save might otherwise look like “no world” | Preserve the error and show filename, parser line and reason on Continue |
| Local X11 sockets remain blocked | Use exact-data difference visual plus UI geometry and scene smoke tests |

## Review conclusion

- Player/gameplay systems expose data but never write files.
- Save workers own no nodes and never mutate the scene tree.
- World seed and original seed text both survive round trips.
- Save and generation compatibility are checked independently.
- Unmodified chunks never create difference documents.
- Removed resources restore through the same runtime state that prevents repeat drops.
- Automatic save dispatch is bounded and measured; exit paths join pending tasks.
- Manual saves create backups before overwrite and retention is capped at five.
- Corrupt content cannot be silently overwritten by Continue.
- Settings remain separate in `settings.cfg`.

No release-blocking issue remains.
