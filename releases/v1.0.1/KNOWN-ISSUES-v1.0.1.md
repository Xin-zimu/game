# V1.0.1 known issues

- Fractional display scales can produce uneven physical pixel sizes even though nearest filtering keeps texture edges sharp. This is required to fill resolutions such as 1920×1080 from the 1280×720 logical base.
- One native Godot access violation appeared during an initial resource-generation test and did not reproduce during immediate or complete reruns. It is retained here for future regression monitoring and is not a confirmed project defect.
- Platform verification in this patch is Windows x86_64; the existing Linux export preset was not packaged in this Windows-focused iteration.
