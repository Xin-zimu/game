# World Generation Contract

## Version

- Game version: `0.3.0`
- Generation version: `2`
- Chunk size: `32×32` world tiles
- Tile size: `32×32` display pixels

## Seed contract

Text is trimmed and encoded as UTF-8. The first eight bytes of SHA-256 are read in big-endian order with the sign bit cleared, producing a stable signed 63-bit value. Numeric text is preserved as a signed integer. The permanent fixture is:

```text
"无尽边境" -> 6266252184503203218
```

System seeds are derived from the world seed, domain name and generation version. Coordinate-local seeds additionally include world layer, signed chunk X/Y and generation type. No generated system consumes a shared global random stream.

## Coordinate contract

World tiles are integer coordinates. Chunk coordinates use mathematical floor division, and local coordinates use positive modulo:

```text
tile (-1, -1)   -> chunk (-1, -1), local (31, 31)
tile (-33, 64)  -> chunk (-2, 2),  local (31, 0)
```

A surface chunk key is formatted as `surface_<x>_<y>` with signs preserved.

## Elevation pipeline

The generator combines three independently seeded FastNoiseLite fields:

| Field | Frequency | Octaves | Weight |
|---|---:|---:|---:|
| Continentalness | 0.010 | 3 | 0.54 |
| Elevation | 0.028 | 4 | 0.36 |
| Detail | 0.085 | 2 | 0.10 |

Normalized elevation is classified as deep water below `0.28`, shallow water below `0.36`, beach below `0.42`, and land otherwise. An order-independent 3×3 global-neighbour pass replaces isolated outlier categories when at least six neighbours agree.

## Data/render boundary

`TerrainGenerator.generate_chunk` returns `ChunkData` containing exactly 1024 terrain bytes, 1024 quantized elevation bytes and a SHA-256 checksum. `ChunkRenderer` consumes that data on the main thread and writes 1024 cells to a `TileMapLayer`. Generation code never accesses the player, UI or scene tree.

## V0.4 streaming contract

| State/range | Radius | Maximum square |
|---|---:|---:|
| Active renderers | 2 | 25 chunks |
| Preload targets | 3 | 49 chunks |
| Retained data cache | 4 | 81 chunks |

The manager prioritizes shorter Euclidean distance and applies a small bias in the player's movement direction. At most four jobs run concurrently. Workers build private generators and return `ChunkData`; only the main thread creates `ChunkRenderer` nodes. Each renderer stores 32×32 local cells and uses its node transform for world placement.
