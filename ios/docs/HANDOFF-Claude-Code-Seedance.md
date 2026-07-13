# Handoff → Claude Code: Seedance exercise-clip integration

> **App-integration status (section 3): DONE.** Implemented `ExerciseClipStore`,
> `ExerciseVideoLoopView` (+ `LoopPlayer`, `ExerciseClipHero`), wired the clip branch into
> `AnatomyHeroView`, and hooked playback into `SessionPlayerView`'s pause/phase state. The
> feature is inert (falls back to the still/vector hero) until clips are generated and dropped
> into `ios/Metabolic/ExerciseClips/` (+ a filled `exercise-clips.json` for remote clips).
> Remaining work is the **content-team** clip generation per `SEEDANCE-PROMPT-KIT.md`.
>
> One deliberate deviation from §3b below: the loop view uses `videoGravity = .resizeAspect`
> (fit), not `.resizeAspectFill`. The hero containers are square/landscape, not 9:16, so a fill
> would crop head/feet — the exact §4 failure. On the white studio card the fit shows no visible
> letterbox. Switch to fill in one line if the hero is ever made 9:16.

**Goal:** wire pre-rendered **Seedance 4-second looping video clips** in as the exercise hero
for each exercise, replacing the real-time anatomy hero. One clip per exercise, played on a
gapless loop, muted, filling the 9:16 hero area, with playback tied to the Session Player's
pause/resume.

This is the outcome of an extended look-dev + approach comparison (3D real-time vs. Seedance
video). **Decision: Seedance video wins** for this product — androgynous single character,
non-interactive, trainer-QC'd, and the visual quality/consistency proved out. The 3D pipeline
(`Metabolic/Anatomy3D/*`) is superseded for the hero; leave it archived or delete — not used
at runtime.

---

## 1. Asset spec (every clip)

- **Format:** H.265/HEVC `.mp4`, **no audio track**, **9:16**, **720×1280**, **~4.0s**,
  seamless loop (first frame ≈ last frame).
- **Content:** the @écorché figure performing ONE rep of the exercise with the worked muscles
  glowing neon green on the exertion phase. White studio bg, soft contact shadow.
- **Size:** ~1–2.5 MB per clip after the encode below.
- **Naming:** `{exerciseId}.mp4`, where `exerciseId` matches
  `MetabolicCore/Sources/MetabolicCore/ExerciseLibrary.swift` ids (e.g. `squat.mp4`,
  `pushUp.mp4`, `lunge.mp4`, `kbSwing.mp4`).

Generation is a **content-team task**, not Claude Code's — see `SEEDANCE-PROMPT-KIT.md`
(prompt template, expert CrossFit form library, @écorché reference, pacing = "exactly one slow
rep", `generate_audio:false`) and the 4-point acceptance test (character / form / highlight /
loop, loop verified by first-vs-last frame diff < ~10/255).

### Encode (Seedance 4K master → app clip)

```bash
ffmpeg -y -i MASTER.mp4 \
  -vf "scale=720:1280:flags=lanczos" \
  -an \                         # strip audio
  -c:v libx265 -crf 28 -tag:v hvc1 -preset slow \
  -movflags +faststart \
  {exerciseId}.mp4
```

(`-tag:v hvc1` so AVFoundation/QuickTime plays the HEVC. Use libx264 + `yuv420p` if you want
maximum device compatibility at a slightly larger size.)

---

## 2. Delivery

- **Bundle** a starter set (the first ~10–15 exercises) in the app for instant/offline use:
  `Metabolic/ExerciseClips/{exerciseId}.mp4` (add folder reference to the target).
- **Stream/download** the rest from a CDN (recommend **Cloudflare R2** — zero egress). A JSON
  manifest maps id → remote URL + version/hash. Cache downloaded clips in
  `Caches/ExerciseClips/`. Offer a "Download all for offline" toggle.
- **Resolution order at play time:** bundled file → cached file → remote URL (kick off download,
  show the static `AnatomyHeroView` fallback until ready).

Manifest shape (the app reads `Metabolic/ExerciseClips/exercise-clips.json`):

```json
{ "version": 3, "baseUrl": "https://cdn.example.com/clips/v3/",
  "clips": { "squat": {"file":"squat.mp4","bytes":1480000},
             "pushUp": {"file":"pushUp.mp4","bytes":1520000} } }
```

---

## 3. App integration (Claude Code's work)

### 3a. `ExerciseClipStore` (new)
A small resolver: `func clipURL(for exerciseId: String) -> URL?` implementing the
bundled → cached → remote order above, plus `download(_:)` and `hasClip(for:)`.
Loads the manifest once at launch. Publishes `downloadedIDs` (observed) so heroes re-resolve
when a download lands.

### 3b. `ExerciseVideoLoopView` (new, SwiftUI)
Gapless 4s loop, muted, no controls. Uses `AVPlayerLooper` + `AVQueuePlayer`
(NOT `.numberOfLoops` / notification seeking — those stutter at the seam).

```swift
import SwiftUI
import AVFoundation

@MainActor
final class LoopPlayer: ObservableObject {
    let queue = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    init(url: URL) {
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queue, templateItem: item)
        queue.isMuted = true
        queue.actionAtItemEnd = .advance
    }
    func play() { queue.play() }
    func pause() { queue.pause() }
}

struct ExerciseVideoLoopView: UIViewRepresentable {
    let player: AVQueuePlayer
    func makeUIView(context: Context) -> PlayerContainer { PlayerContainer(player: player) }
    func updateUIView(_ v: PlayerContainer, context: Context) {}
    final class PlayerContainer: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        init(player: AVQueuePlayer) {
            super.init(frame: .zero)
            (layer as! AVPlayerLayer).player = player
            (layer as! AVPlayerLayer).videoGravity = .resizeAspectFill
        }
        required init?(coder: NSCoder) { fatalError() }
    }
}
```

### 3c. Hook into the hero + Session Player
- In `Metabolic/Features/Training/AnatomyHeroView.swift` (or wherever the exercise hero
  renders): **branch first** on `ExerciseClipStore.shared.clipURL(for: exercise.id)` →
  `ExerciseVideoLoopView`; keep the existing 2D/vector hero as the fallback below it (same
  pattern the old handoff used for the 3D hero).
- In `SessionPlayerView.swift` (the Task-2 player): the existing **pause/resume** and the
  `.ready`/`.working`/`.resting` phases must drive the loop — call `player.pause()` when the
  session pauses or is in a non-active phase, `player.play()` when active. One `LoopPlayer`
  per visible exercise; recreate on exercise change.

### 3d. Highlight is baked — do NOT tint at runtime
The green muscle highlight is in the video pixels. The `MuscleGroup` material/tint system from
the old 3D plan is **not used for the hero**. Keep `exercise.muscleGroups` for the text/labels
and the exercise-detail muscle chips only.

---

## 4. Acceptance / QA

- Clip plays muted, loops with no visible seam or audio.
- Fills the hero frame (9:16) without letterboxing; head/feet not cropped.
- Pausing the session pauses the clip; resuming resumes it.
- Missing/not-yet-downloaded clip falls back to the static hero, then swaps in when ready.
- Bundle size sane: starter clips only in-app; rest via manifest.
- `python3 ios/tools/verify_swift.py --strict` prints OK; build the Metabolic scheme.

---

## 5. Files

- `ios/docs/SEEDANCE-PROMPT-KIT.md` — clip generation recipe (content team).
- `ios/Metabolic/ExerciseClips/` — bundled starter clips (`{exerciseId}.mp4`) +
  `exercise-clips.json` manifest.
- New: `ExerciseClipStore.swift`, `ExerciseVideoLoopView.swift` (+ `LoopPlayer`,
  `ExerciseClipHero`).
- Touch: `AnatomyHeroView.swift`, `SessionPlayerView.swift`.
- Superseded (archive/remove): `ios/Metabolic/Anatomy3D/*` (3D hero — never built; not used at
  runtime).
