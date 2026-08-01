# V0.4.0 Changelog

V0.4.0 turns deterministic chunk generation into a continuously streamed world. Nearby chunks activate, forward chunks receive queue priority, old renderers unload, and data remains in a bounded cache before eviction.

## Streaming

- Active radius 2, preload radius 3 and cache radius 4.
- Distance and movement-direction generation priority.
- Four concurrent WorkerThreadPool pure-data jobs.
- Mandatory task joins on collection and shutdown.
- Main-thread-only TileMapLayer creation and removal.

## Rendering and diagnostics

- One local-coordinate renderer per active chunk with a shared pixel atlas.
- Unbounded camera and unrestricted player travel.
- Streaming HUD for active, preload, sleeping, cache, queue, workers and peak counts.
- `N` terrain/noise switch and `B` visible chunk-boundary switch.
- Runtime memory peak monitoring.

## Verification

- Automated suite expanded from 47 to 58 passing tests.
- 1,800-step/30-minute-equivalent traversal policy simulation stays within 81 cached chunks.
- Adjacent border coordinates and both sides of the global noise field verified.
- Evicted chunk regeneration returns the original checksum.
- Worker task ID proves data generation ran in WorkerThreadPool.
- Actual frame shows 25 active, 24 preloaded, 49 cached, zero queued and zero running jobs.
