# V0.4.0 Known Issues

- Streaming currently covers base terrain only; biome, decoration and resource lifecycles begin in V0.5.0 and V0.6.0.
- Completed outdated jobs are joined and discarded rather than cancelled because WorkerThreadPool tasks are intentionally short.
- Cached chunks contain generated base data only; persistent player modifications arrive with the V0.7.0 save system.
- The camera uses a very large practical limit because engine coordinates are finite floating-point values.
- The Windows executable is cross-built and PE-validated on Linux. Native Windows runtime verification remains a downstream release task.
