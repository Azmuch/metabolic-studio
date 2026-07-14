# Asset credits

## 3D anatomy hero (`Metabolic/Anatomy3D/BodyRig.usdz`)

**Base mesh:** Human Base Meshes bundle v1.4.1 — Blender Studio.
- Source object: `GEO-body_male_realistic` (realistic anatomical male, ~21k triangles).
- License: **CC0 1.0 (public domain)**. No attribution required; recorded here for provenance.
- Origin: https://www.blender.org/download/demo-files/ (Characters → Human Base Meshes),
  authored by the Blender Studio team and community.

**Derivative work performed in this repo (Blender hybrid pipeline, Task 5):**
- Isolated the realistic male body; centered, applied transforms, feet at z=0.
- Assigned 10 material slots named exactly after `MuscleGroup` raw values plus a `body`
  base (`body, chest, back, shoulders, arms, core, quads, hamstrings, glutes, calves`),
  porcelain-gray PBR (roughness 0.6), emission channel left free for runtime accent tint.
- Added a single `female` shape key (subtle: wider hips, narrower shoulders, slight bust).
- Added a humanoid armature and skeletal animation clips (see below).

**Animation clips** are original, generated from the app's own `ExercisePoses` keyframe data
(`ios/docs/pose-keyframes.json`) and are not part of the CC0 source.
