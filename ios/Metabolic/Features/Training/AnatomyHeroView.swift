import SwiftUI
import MetabolicCore

/// The exercise hero slot — one visual, layered by best available fidelity:
///
///   1. **Seedance video clip** (target look): a pre-rendered 4s seamless loop of the écorché
///      figure performing one rep with the prime movers glowing green on the exertion phase.
///      Resolved per-exercise by `ExerciseClipStore` (bundled → cached → remote); the green
///      highlight is baked into the pixels, so no runtime tinting here. Playback follows the
///      `isPlaying` flag so the Session Player's pause/phase state can drive it.
///   2. **Anatomy stills**: Higgsfield-generated écorché illustrations with the activated
///      muscles highlighted; two poses crossfade into a breathing loop, and the baked lime
///      highlight is hue-shifted live to match the user's accent theme.
///   3. **Vector skeleton** (always available): the original pose-keyframe Canvas figure.
///
/// The supplanted 3D/SceneKit hero path is not used at runtime (see the Seedance handoff).
struct AnatomyHeroView: View {
    let exercise: Exercise

    /// Drives clip playback; the still/vector fallbacks animate continuously and ignore it.
    /// Detail screens pass `true`; the Session Player pauses the clip in inactive phases.
    var isPlaying: Bool = true

    /// Inset between the figure and the card edge. 0 = edge-to-edge (the full-bleed detail hero).
    var contentInset: CGFloat = 10

    /// Corner radius of the hero card. 0 = square (used when the hero fills the screen as a
    /// background, e.g. the session player).
    var cornerRadius: CGFloat = MTTheme.cardRadius

    /// Exercise id → bundled anatomy imageset names (1 = static breathe, 2 = A/B loop).
    /// Populated by `ios/tools/fetch_anatomy_assets.sh`; missing assets fall back cleanly.
    static let assetManifest: [String: [String]] = [
        "squat": ["anatomy.squat.a", "anatomy.squat.b"],
        "pushUp": ["anatomy.pushUp.a", "anatomy.pushUp.b"],
        "lunge": ["anatomy.lunge.a", "anatomy.lunge.b"],
        "pullUp": ["anatomy.pullUp.a", "anatomy.pullUp.b"],
        "kbSwing": ["anatomy.kbSwing.a", "anatomy.kbSwing.b"],
        "gluteBridge": ["anatomy.gluteBridge.a", "anatomy.gluteBridge.b"],
        "dbShoulderPress": ["anatomy.dbShoulderPress.a", "anatomy.dbShoulderPress.b"],
        "plank": ["anatomy.plank.a"],
    ]

    var body: some View {
        if let clipURL = ExerciseClipStore.shared.clipURL(for: exercise.id) {
            ExerciseClipHero(url: clipURL, isPlaying: isPlaying,
                             playback: ExerciseClipStore.shared.playback(for: exercise.id),
                             contentInset: contentInset, cornerRadius: cornerRadius)
        } else if let names = Self.assetManifest[exercise.id],
                  let primary = UIImage(named: names[0]) {
            AnatomyImageHero(
                primary: primary,
                secondary: names.count > 1 ? UIImage(named: names[1]) : nil,
                contentInset: contentInset,
                cornerRadius: cornerRadius)
        } else {
            ExerciseAnimationView(exercise: exercise)
        }
    }
}

/// Crossfading two-pose loop over the generated anatomy stills. The card keeps a fixed
/// light canvas in both appearances (the illustrations have a baked light background —
/// treated like product photography), and the highlight color follows the accent theme
/// via hue rotation: the porcelain body is near-desaturated so only the lime glow shifts.
private struct AnatomyImageHero: View {
    let primary: UIImage
    let secondary: UIImage?
    var contentInset: CGFloat = 10
    var cornerRadius: CGFloat = MTTheme.cardRadius

    private let cycle: Double = 3.4

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = (t.truncatingRemainder(dividingBy: cycle)) / cycle
            // Smooth out-and-back blend: 0 → 1 → 0 across one cycle.
            let raw = phase < 0.5 ? phase * 2 : (1 - phase) * 2
            let blend = raw * raw * (3 - 2 * raw)
            let breathe = 1.0 + 0.015 * sin(t * 1.6)

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 0.965, green: 0.965, blue: 0.957))

                ZStack {
                    Image(uiImage: primary)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(secondary == nil ? 1 : 1 - blend)
                    if let secondary {
                        Image(uiImage: secondary)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(blend)
                    }
                }
                .padding(max(contentInset, 4))
                .scaleEffect(breathe)
                .hueRotation(.degrees(accentHueShift))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(MTTheme.stroke, lineWidth: cornerRadius > 0 ? 1 : 0))
    }

    /// Baked highlight is Volt lime (hue ≈ 72°); shift it toward the active accent.
    /// Grays are hue-neutral, so the porcelain body is unaffected.
    private var accentHueShift: Double {
        switch ThemeStore.shared.accent {
        case .volt: return 0
        case .tangerine: return -42
        case .earth: return -39
        case .jewel: return 104
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        if let squat = ExerciseLibrary.exercise(id: "squat") {
            AnatomyHeroView(exercise: squat)
                .frame(height: 280)
        }
        if let birdDog = ExerciseLibrary.exercise(id: "birdDog") {
            AnatomyHeroView(exercise: birdDog)   // no asset → vector fallback
                .frame(height: 200)
        }
    }
    .padding(20)
    .background(MTBackground())
}
