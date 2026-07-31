# V0.3.0 Changelog

V0.3.0 replaces the hand-authored movement sandbox terrain with the first deterministic procedural world unit: a signed-coordinate 32×32 chunk generated from a stable 64-bit seed and rendered through `TileMapLayer`.

## Generation

- Stable text/numeric world seeds and independently derived domain/chunk seeds.
- Multi-scale FastNoiseLite continental, elevation and detail fields.
- Deep water, shallow water, beach and land terrain bytes.
- Global-neighbour cleanup without request-order dependence.
- Generation format version 2 and per-chunk SHA-256 checksum.

## Coordinates and rendering

- Signed world-tile, chunk, local-tile and pixel conversions.
- Correct floor division and positive modulo at negative boundaries.
- Scene-independent `ChunkData` and main-thread `TileMapLayer` renderer.
- Deterministic `R` regeneration and `N` noise debug view.
- Seed, chunk, checksum, mode and world-tile HUD values.

## Verification

- Automated suite expanded from 24 to 47 passing tests.
- Stable seed fixture, restart equality, exact tile-byte equality and generation-order tests.
- Negative-coordinate round trips and four-terrain coverage checks.
- Zero isolated single-tile coast noise check.
- Actual terrain and noise frames visually reviewed at 1280×720.
