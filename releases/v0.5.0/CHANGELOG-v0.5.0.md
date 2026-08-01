# V0.5.0 Changelog

V0.5.0 upgrades the streamed world from four base terrain classes to a deterministic, data-driven ecological map.

## Generation

- Six independent FastNoiseLite domains: continentalness, elevation, erosion, temperature, moisture and detail.
- Generation format 3 with seven checked byte maps per 32×32 chunk.
- Altitude cooling and ocean moisture influence.
- Stable fixture `47c1e52c4fe80f9c` for seed `无尽边境`, chunk `(-1,-4)`.

## Biomes

- Deep ocean, ocean, coast, plains, forest, desert, snowfield, swamp and mountain.
- JSON-defined stable IDs, byte codes, names, colors, priorities, conditions and transition bands.
- Global-neighbour cleanup for terrain and land biomes.
- Configuration validation with actionable errors.

## Presentation and diagnostics

- Ecological terrain colors and patterns.
- `N` cycles terrain, biome, climate and elevation modes.
- HUD reports current biome, temperature, moisture, elevation and erosion.
- Headless exact-data biome map renderer for reproducible diagnostics.
- Expanded offline CJK font subset for every new runtime label.

## Verification

- Automated suite expanded from 58 to 99 passing tests.
- All nine biomes appear in a deterministic 4,225-sample broad scan.
- The 96×96 continuity fixture has 94.48% matching orthogonal edges and only two isolated cells.
- Cross-chunk biome seams, worker generation, renderer coverage and HUD containment pass.
- Windows and Linux exports include the external biome configuration and pass the release build gate.
