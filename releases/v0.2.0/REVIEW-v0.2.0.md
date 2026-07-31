# V0.2.0 Self Review

Status: **PASS after fixes**

## Findings and resolutions

| Finding | Resolution |
|---|---|
| A drawing helper named `draw_ellipse` collided with a native Godot 4.7 method | Rename it to `_draw_ellipse_shape` and rerun import, tests and both scene smokes |
| Initial HUD bar sizing combined anchors and explicit width, producing layout warnings | Use full-rect fills and represent the current value with horizontal scale |
| A scene could exit successfully even after a script error appeared in the log | Capture each Godot command output and fail on `SCRIPT ERROR` or engine `ERROR:` lines |
| Main-menu smoke coverage did not prove the gameplay scene could instantiate | Add a dedicated `game.tscn` smoke run to the release gate |

## Review conclusion

- Player movement uses the physics body and does not bypass obstacle collision.
- Diagonal input is normalized before applying walk or run speed.
- Roll, stamina and health values are clamped and exposed through typed signals.
- Camera smoothing is independent of player velocity and camera limits match the sandbox.
- HUD reads player state but does not mutate it.
- New Chinese glyphs are bundled offline under the existing font license.
- No deterministic generation or chunk streaming is falsely claimed in this version.

No release-blocking issue remains.
