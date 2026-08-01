# V0.8.0 Visual Evidence

`inventory-and-hotbar.png` is a 1280×720 exact-data/layout reconstruction of the V0.8 runtime UI. It shows:

- the 6×4, 24-slot backpack grid;
- five canonical item colors, names and quantities;
- selected-slot category and stack-limit details;
- split, discard and sort controls;
- the always-visible eight-slot hotbar with slot 1 selected;
- the gameplay health/resource HUD context.

The image was inspected at original resolution: all 24 slots and eight hotbar cells are present, Chinese labels render, controls do not overlap, and the bottom hotbar remains inside the 1280×720 viewport. A direct X11 capture is unavailable because the build sandbox blocks local display sockets; runtime scene smoke and UI node/count tests cover the executable layout path.
