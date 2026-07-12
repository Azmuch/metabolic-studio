# Anatomy3D — rigged animated hero model

Built via the Blender hybrid pipeline (Task 5) from the CC0 Blender Studio Human Base
Meshes realistic male body. See `../../docs/ASSET-CREDITS.md` for licensing.

## Files

- **`BodyRig.glb`** — source of truth. One skinned mesh (~21k tris) + humanoid armature
  (13 bones) + **5 named animation clips** (`squat`, `pushUp`, `plank`, `lunge`, `kbSwing`)
  + one morph target (`female`). glTF stores the clips as independent named animations.
- **`BodyRig.usdz`** — Apple-native build. Same rig/mesh/clips, but the 5 clips are baked
  onto a single timeline (USD has no multi-clip concept). Address each clip by frame range
  from `clips.json`.
- **`clips.json`** — fps + per-clip frame ranges + `secondsPerCycle`.

## Materials (for runtime accent tinting — Task 3)

10 slots named exactly after `MuscleGroup` raw values plus a `body` base:
`body, chest, back, shoulders, arms, core, quads, hamstrings, glutes, calves`.
All are porcelain-gray PBR (roughness 0.6) with the emission channel left free. At runtime
set `material.emission.contents` on the slots matching `exercise.muscleGroups` to the accent
color — that reproduces the green muscle-highlight in the 2D anatomy stills (e.g. `quads`
during a squat).

## Morph

Single blend shape `female` (0 = male, 1 = female): subtly wider hips, narrower shoulders,
slight bust. Drive from `appState.profile.sex`.

## Loader notes for Task 3

- `SCNScene(named:)` on the USDZ gives one baked animation; play a clip by clamping the
  animation's `timeRange` to the frame range (÷ fps) in `clips.json`.
- Alternatively load `BodyRig.glb` (GLTFKit2 / ModelIO) to get the 5 clips by name directly
  — the cleaner path for `SCNAnimationPlayer(named:)`-style lookup.

## Known limitation vs. the 2D écorché stills

The base carries realistic muscular *form* but not the fine flayed-muscle *striations* of the
2D stills — that detail lived in the source mesh's multires level (1.35M tris, dropped to hit
the app poly budget). To recover it without the poly cost, bake a normal map from the multires
surface onto the 21k base UVs (the mesh already has a `UVMap`), or commission the écorché mesh
per Task 3's spec. The green highlight + muscular anatomy are already in place.
