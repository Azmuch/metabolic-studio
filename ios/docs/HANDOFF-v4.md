# Metabolic v4 — handoff plan

For the executing agent (local Claude Code session with the Xcode MCP, or any future
session). Read `docs/SPEC.md` and `docs/INTERFACES.md` first — §4 of SPEC and the
INTERFACES ownership tables are hard contracts. After every task: build the Metabolic
scheme, run `python3 ios/tools/verify_swift.py --strict` from `ios/`, fix regressions,
commit with a clear message, push to `claude/ios-fitness-tracking-app-qanedu`.

Already done in the last remote commit (do not redo): the "MUSCLES ACTIVATED" card was
removed from `ExerciseDetailView` — the anatomy hero itself now communicates activation.
`MuscleMapView` intentionally remains in the codebase (still available for future use).

---

## Task 1 — Fix subscriptions not unlocking (highest priority, mostly diagnosis)

Symptom: tapping Get Plus/Pro on the paywall doesn't unlock gated features.

Root-cause checklist, in order:

1. **StoreKit configuration must actually be attached to the scheme.** If Xcode shows
   the warning "StoreKit Configuration file … can't be found", products never load,
   `subscriptionManager.products` stays empty, and `purchase(productID:)` silently
   `guard`-returns — exactly this symptom. Fix in Xcode UI: Product → Scheme →
   Edit Scheme… → Run → Options → StoreKit Configuration → select
   `Config/Products.storekit`. Commit the resulting change to
   `ios/Metabolic.xcodeproj/xcshareddata/xcschemes/Metabolic.xcscheme` so it sticks.
2. **Make failures loud.** In `Metabolic/Services/SubscriptionManager.swift`:
   `purchase(productID:)` currently does `guard let product = product(id:) else { return }`
   — change it to throw a descriptive error (e.g. `SubscriptionError.productsUnavailable`).
   In `Metabolic/Features/Paywall/PaywallView.swift`, catch purchase errors into an
   `@State` alert so the user (and you) can see what failed instead of a dead button.
3. **Verify tier refresh.** After a successful purchase, `refreshTier()` iterates
   `Transaction.currentEntitlements`. Confirm: (a) it runs on the main actor when it
   assigns `tier` (the class is @Observable; UI updates must land on main — wrap the
   assignment in `await MainActor.run` if the class isn't @MainActor); (b) the paywall's
   "Current plan" chip flips immediately after purchase; (c) gates re-evaluate (they read
   `subscriptionManager.tier` in body, so they update once `tier` changes).
4. **Test matrix in the simulator** (StoreKit config = local sandbox, no real money):
   buy Plus monthly → Today edit-mode unlocks, AI photo tab unlocks, exercise library
   shows all, scan limit lifts. Then Debug → StoreKit → Manage Transactions: refund it →
   tier returns to Free. Repeat for Pro (CSV export + Coaching Live unlock).

## Task 2 — Session player: explicit start, pause, and set prompts — DONE

Implemented in `Metabolic/Features/Training/SessionPlayerView.swift` (do not redo — pull
latest before touching this file). Delivered: a `.ready` Start screen (plan title, exercise
count, est. minutes, first exercise hero, big "Start Workout" button; the elapsed clock only
starts on tap via `sessionStart = .now`); a `.setReady` "Begin Set" prompt before every work
phase, including after rests; a circular pause/resume button (pause.fill ↔ play.fill) on the
timed-work and rest countdowns with Date-anchored re-anchoring (`phasePausedTotal`/`pausedAt`)
and a session-clock freeze (`sessionPausedTotal`, frozen at `sessionEnd` on finish); Start =
`.success()` haptic, begin-set/pause/resume = `.tap()`. `SessionPlayerView(plan:)` signature
and the WorkoutLog + HealthKit save flow are unchanged. Original spec kept below for reference:

1. **Ready state (new, before anything runs):** plan title, exercise count, est. minutes,
   the first exercise's hero, and one big `MTPrimaryButton("Start Workout", systemImage:
   "play.fill")`. Elapsed-time clock starts only when tapped (set `sessionStart = .now`
   at that moment, not at view init).
2. **Begin-set prompt:** entering any work phase shows "SET k OF n — READY?" with a
   `Begin Set` button (play.fill). Reps counting/timed countdown only starts after it's
   tapped. After rest phases, land in this prompt again rather than auto-starting work.
   (Rest countdowns may still auto-run — they end with the prompt for the next set.)
3. **Pause/resume:** a circular pause button (pause.fill ↔ play.fill) visible during
   work-timed and rest countdowns. Implementation note: countdowns are Date-anchored —
   on pause, store `remainingAtPause`; on resume, re-anchor
   (`phaseEnd = .now + remainingAtPause`). Also freeze the elapsed-session clock by
   accumulating into a `pausedAccumulator` and excluding it from elapsed math.
4. Haptics: `.success()` on Start, `.tap()` on pause/resume/begin-set. Keep every
   existing signature (`SessionPlayerView(plan:)`) and the WorkoutLog save flow intact.

## Task 3 — Dynamic 3D exercise model (the big feature) — SUPERSEDED

Superseded by the Seedance video hero (see `HANDOFF-Claude-Code-Seedance.md`). The real-time
3D/SceneKit path was never built and is not used at runtime; the app integration for video
clips is done. Original 3D spec kept below for reference only. Task 5 (Blender) is likewise
superseded for the hero.

### What to build in code (can be done now, before the asset exists)

New file `Metabolic/Features/Training/Anatomy3DHero.swift`:

- `UIViewRepresentable` wrapping `SCNView`: transparent background
  (`scnView.backgroundColor = .clear`), default camera orbiting rig
  (`allowsCameraControl = true` for user rotation — a selling point over 2D),
  three-point studio lighting (key + fill + rim SCNLight nodes), antialiasing 4x.
- Loader: `SCNScene(named: "BodyRig.usdz")` from an `Anatomy3D` bundle folder; find the
  model root node. Expose `static func isAvailable(for exerciseID: String) -> Bool`
  (checks the scene + a clip named after the id).
- Animation: retrieve the skeletal clip whose name == the exercise id and attach an
  `SCNAnimationPlayer` (looping, speed 1); expose `isPaused` binding so the session
  player's pause also freezes the model.
- Sex adaptation: if the mesh has a morph target named `female`, set
  `SCNMorpher.weights` from `appState.profile.sex`.
- Accent tinting: for each material whose name matches a `MuscleGroup` rawValue in
  `exercise.muscleGroups`, set `material.emission.contents` to the accent UIColor at
  ~60% intensity (read `ThemeStore.shared.accent` — the representable should observe it
  via `updateUIView`).
- Integration: in `AnatomyHeroView.body`, branch FIRST on
  `Anatomy3DHero.isAvailable(for: exercise.id)` → `Anatomy3DHero(exercise:)`; the
  existing stills/vector fallbacks stay untouched below it.

### The asset I need from you (commission or license — this is the only blocker)

- **Format: USDZ** (SceneKit-native; artists can build in Blender and export via
  Apple's Reality Converter). glTF/GLB also acceptable if converted to USDZ before
  delivery. Generative 3D tools produce static, unrigged meshes — not usable here.
- **Mesh:** one androgynous écorché-style human, 15–25k triangles, style-matched to the
  bundled 2D anatomy stills (porcelain-gray musculature).
- **Rig:** standard humanoid skeleton (Mixamo-compatible naming is fine).
- **Morph target:** one blend shape named `female` (0 = male silhouette, 1 = female).
- **Materials:** separate material slots named exactly after the `MuscleGroup` raw
  values — `chest, back, shoulders, arms, core, quads, hamstrings, glutes, calves` —
  plus one `body` base material. PBR, with the emission channel free for runtime tinting.
- **Animation clips:** one seamless loop per exercise, **named exactly by exercise id**
  (the 37 ids and their cycle durations are in
  `ios/MetabolicCore/Sources/MetabolicCore/ExerciseLibrary.swift` — `id` and
  `secondsPerCycle`). Ship in priority order; the app falls back per-exercise, so even
  5 clips is a shippable first delivery (suggested: squat, pushUp, plank, lunge, kbSwing).
- Delivery location: `ios/Metabolic/Anatomy3D/BodyRig.usdz` (folder-synchronized —
  dropping the file in is enough; no project surgery).

## Task 4 — Small follow-ups

- Delete the now-unused `import MuscleMapView` references if the compiler flags any
  (MuscleMapView itself stays).
- Run the full regression pass from Task 1's test matrix after everything lands.

## Conventions reminder for the executing agent

- Design tokens only via `MTTheme`/DS components; screen backgrounds via `MTBackground()`.
- Never rename contract types (SPEC §4, INTERFACES tables, v2/v3 addenda).
- `python3 ios/tools/verify_swift.py --strict` must print OK before every commit.

---

## Task 5 — Build the rigged model via Blender MCP (hybrid path, local Mac only)

Prereqs on the Mac: Blender installed; BlenderMCP addon (github.com/ahujasid/blender-mcp)
installed and connected; `claude mcp add blender -- uvx blender-mcp` registered.

Approach — do NOT model a human from scratch. Hybrid pipeline:

1. **Base mesh:** import a permissively-licensed rigged humanoid — first choice:
   Blender Studio "Human Base Meshes" bundle (CC0). Reduce to ~20k tris (Decimate).
   Record the license/source in `ios/docs/ASSET-CREDITS.md`.
2. **Materials:** create material slots named exactly `body, chest, back, shoulders,
   arms, core, quads, hamstrings, glutes, calves` (MuscleGroup raw values) and assign
   faces per region (approximate regions are fine for v1 — the emission tint reads as
   a glow, not a medical diagram). Base: porcelain-gray PBR, roughness ~0.6.
3. **Female morph:** add a shape key named `female` (scale hips/chest/shoulder widths —
   subtle is better than caricature).
4. **Animation clips:** one Blender Action per exercise, **named by exercise id**.
   Seed the poses from the app's own keyframe data — every exercise's 13-joint
   normalized keyframes live in `ios/MetabolicCore/Sources/MetabolicCore/ExercisePoses.swift`
   and `MobilityPoses.swift` (joints: head, neck, L/R shoulder/elbow/wrist, hip,
   L/R knee/ankle; x,y in [0,1], y down). Map to rig bones via IK targets on wrists/
   ankles + hip/head positioning, keyframe A/B(/C) poses, loop with cycle duration =
   `secondsPerCycle`. Start with 5 clips: squat, pushUp, plank, lunge, kbSwing.
5. **Export:** glTF (.glb) with animations → convert to USDZ with Apple Reality
   Converter (drag-and-drop) → verify clip names survived (Xcode can inspect USDZ) →
   drop at `ios/Metabolic/Anatomy3D/BodyRig.usdz`, commit, and implement Task 3's
   `Anatomy3DHero` against it.
6. **Iterate visually:** BlenderMCP can screenshot the viewport — check each pose against
   the bundled 2D anatomy stills for silhouette agreement before exporting.

Quality note: this yields a solid v1 (clean, stylized, correctly animated). If the
end goal is the premium écorché look of the 2D stills, commission the mesh per Task 3's
spec and keep the Blender-scripted animation clips — clips transfer to any humanoid rig.
