import SwiftUI
import MetabolicCore

/// The exercise hero slot — one visual, layered by best available fidelity:
///
///   1. **3D rigged model** (future): a posable USDZ body with male/female morph targets,
///      one skeletal clip per exercise id, and accent-tintable muscle materials, rendered
///      via SceneKit. When that asset lands, add a `Anatomy3DHero` branch at the top of
///      `body` — nothing else in the app needs to change.
///   2. **Anatomy stills** (this build): Higgsfield-generated écorché illustrations with
///      the activated muscles highlighted; two poses crossfade into a breathing loop,
///      and the baked lime highlight is hue-shifted live to match the user's accent theme.
///   3. **Vector skeleton** (always available): the original pose-keyframe Canvas figure.
struct AnatomyHeroView: View {
    let exercise: Exercise

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
        if let names = Self.assetManifest[exercise.id],
           let primary = UIImage(named: names[0]) {
            AnatomyImageHero(
                primary: primary,
                secondary: names.count > 1 ? UIImage(named: names[1]) : nil)
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
                RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
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
                .padding(10)
                .scaleEffect(breathe)
                .hueRotation(.degrees(accentHueShift))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                .stroke(MTTheme.stroke, lineWidth: 1))
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
