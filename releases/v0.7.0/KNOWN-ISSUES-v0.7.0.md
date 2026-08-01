# V0.7.0 Known Issues

- Continue loads the most recently played valid world. A full world browser, rename and delete UI are later menu work.
- Save format 1 is explicitly rejected; migration begins when a real older persistent format exists.
- V0.7 difference documents use readable JSON rather than compressed binary because each file contains only sparse keys. Compression can be introduced with a later save-version migration.
- A hard process kill can lose progress since the last 30-second autosave. Normal menu return and window close flush the current snapshot.
- Backups are created by manual/exit saves, not every 30-second autosave, to limit write amplification.
- The current item dictionary is a bridge for V0.6 pickup counts. V0.8 introduces slot/stack inventory persistence.
- The release visual is a headless exact-data difference map because the build sandbox blocks local X11 sockets; world-creation layout and both scenes still pass automated runtime checks.
- The Windows executable is cross-built and PE-validated on Linux. Native Windows runtime verification remains a downstream release task.
