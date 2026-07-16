# Shopping spec — rigged anatomy model for the exercise engine

Use this before buying/downloading. The goal: **one character, rigged once, that every
exercise animation and both sexes can reuse, with per-muscle highlighting.** Send me any
candidate `.glb`/`.fbx` and I'll verify all of this in ~1 minute before you spend money.

## Must-have (deal-breakers if missing)

1. **Rigged with a standard humanoid skeleton.**
   - Real skin weights (skeletal deformation), not a static/posed sculpt.
   - Bone naming compatible with **Mixamo / Unreal mannequin / Rigify** so mocap retargets
     cleanly. ~30–70 bones. Must include: hips/spine/chest, neck, head, clavicles,
     upper+lower arms, hands, upper+lower legs, feet. Symmetric L/R.
   - **Rest pose = T-pose or A-pose** (required for clean retargeting).
   - Max **4 bone influences per vertex** (glTF/USDZ limit) — most game-ready rigs comply.
   - ✗ The Sketchfab "Ecorche - anatomy study" we tested has **0 skeleton** — that's the
     exact failure mode to avoid.

2. **Commercial license.** Royalty-free / "use in a mobile app / real-time / game engine."
   - OK: Royalty-Free, CC0, CC-BY (credit the author).
   - ✗ Avoid: CC-BY-**NC** (non-commercial), "Editorial use only," "no redistribution in
     apps." (The tested model was CC-BY — usable but needs attribution.)

3. **Format: FBX or GLB.**
   - **FBX** preferred for a rigged character (reliably carries skeleton + skin + blendshapes;
     it's what mocap tools export/import).
   - **GLB** also fine (single self-contained file).
   - ✗ Never OBJ (no rig). ✗ Don't work from USDZ-only (that's the iOS *output*, not source).

## Strongly wanted

4. **Per-muscle separation for highlighting.** Either:
   - separate submeshes per muscle group, **or**
   - a material / texture-ID per group.
   Named to (or mappable to) our 9 groups: `chest, back, shoulders, arms, core, quads,
   hamstrings, glutes, calves`.
   - Reality check: rigged **and** per-muscle-separated is rare. If it's one skinned mesh
     with a single material, that's fine — I re-split it into the 9 regions by anatomical
     position (approximate but reads correctly as a glow). So this is "nice to have," not a
     deal-breaker.

5. **Male + female.** Best: two bodies **on the same skeleton**, or one body with a **sex
   blendshape/morph**. Same skeleton = every clip drives both sexes for free. If you can only
   get one, get male + a morph, or we author the female as a morph (what I already prototyped).

6. **PBR textures incl. a normal map.** The normal map carries écorché muscle-striation
   detail at low poly — this is how you get the "flayed muscle" look without millions of tris.

## Poly count — stop worrying about it

- **30k–150k triangles is the sweet spot** for one hero character on iOS Metal
  (SceneKit/RealityKit) at 60fps. Up to ~500k is still fine on modern iPhones.
- Don't pay to decimate; don't reject a model for being "high poly." Only avoid multi-million
  (wasteful, not fatal). The tested écorché was 419k — that would render fine; its problem
  was the missing rig, not the polys.

## Where to look + search terms

- **TurboSquid, CGTrader, Fab (Unreal), Sketchfab** (filter: Downloadable + **Rigged** +
  Animated). Adobe Substance/Mixamo for standard rigged humans (not écorché but riggable).
- Search: `écorché rigged`, `anatomy muscle rigged character`, `muscular male rigged animated`,
  `myology rigged`, `skeletal muscle figure rigged`.
- Gold standard for true per-muscle anatomy: **Zygote, BioDigital, 3D4Medical** — accurate and
  separable, but licensed/pricey. Worth it only if exact medical muscle separation is core.

## 8-point checklist (apply before buying — or send me the file)

- [ ] Rigged (skeleton + skin weights), not a static sculpt
- [ ] Standard/Mixamo-style bone naming, T- or A-pose
- [ ] ≤ 4 influences per vertex
- [ ] Commercial license (app/real-time allowed)
- [ ] FBX or GLB available
- [ ] Muscle separation (submesh or material-ID) — or accept region re-split
- [ ] Male + female, or a sex morph
- [ ] 30k–500k tris, PBR + normal map

**Fastest path:** pick a candidate, drop the `.glb`/`.fbx` in `ios/Auxilliaery/`, and I'll run
the same inspection I ran on the écorché (rig / bones / materials / polys / license) and give
you a straight yes/no before you commit.
