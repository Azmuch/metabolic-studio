import SwiftUI

/// The app's canvas layer. Screens use `.background(MTBackground().ignoresSafeArea())`
/// instead of a flat color, and the user's `BackgroundStyle` decides what renders:
/// classic/tinted → themed surface color, glass → accent-washed backdrop with soft
/// luminous blobs, photo → the user's wallpaper under a legibility scrim.
struct MTBackground: View {
    var body: some View {
        let store = ThemeStore.shared
        switch store.backgroundStyle {
        case .classic, .tinted:
            MTTheme.bg
        case .glass:
            GlassBackdrop()
        case .photo:
            PhotoBackdrop()
        }
    }
}

/// Accent-washed backdrop for the liquid-glass style: the tinted base with big,
/// soft, slowly-drifting accent blobs that translucent cards can pick up.
private struct GlassBackdrop: View {
    var body: some View {
        let accent = MTTheme.volt
        ZStack {
            MTTheme.bg

            TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                GeometryReader { geo in
                    let size = geo.size
                    ZStack {
                        blob(accent.opacity(0.32), diameter: size.width * 1.1)
                            .position(x: size.width * (0.20 + 0.06 * sin(t * 0.11)),
                                      y: size.height * (0.12 + 0.04 * cos(t * 0.09)))
                        blob(accent.opacity(0.22), diameter: size.width * 0.9)
                            .position(x: size.width * (0.90 - 0.05 * cos(t * 0.07)),
                                      y: size.height * (0.45 + 0.05 * sin(t * 0.08)))
                        blob(accent.opacity(0.26), diameter: size.width * 1.0)
                            .position(x: size.width * (0.35 + 0.05 * sin(t * 0.06)),
                                      y: size.height * (0.95 - 0.04 * cos(t * 0.1)))
                    }
                }
            }
            .blur(radius: 60)
        }
    }

    private func blob(_ color: Color, diameter: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
    }
}

/// Wallpaper (bundled preset or the user's own photo) under a scrim that keeps cards and
/// text legible in both appearances. With parallax on, the image drifts opposite device
/// tilt — Apple's classic home-screen wallpaper effect.
private struct PhotoBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let store = ThemeStore.shared
        ZStack {
            MTTheme.bg

            if let image = store.activeWallpaperImage {
                GeometryReader { geo in
                    Group {
                        if store.wallpaperParallax {
                            ParallaxImage(image: image, strength: 22)
                        } else {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    // Overscan under parallax so the drift never reveals an edge.
                    .scaleEffect(store.wallpaperParallax ? 1.12 : 1)
                    .clipped()
                }
                .id("\(store.wallpaperVersion)-\(store.wallpaperPreset ?? "custom")")

                Rectangle()
                    .fill(colorScheme == .dark
                          ? Color.black.opacity(0.45)
                          : Color.white.opacity(0.35))

                Rectangle().fill(.ultraThinMaterial.opacity(0.5))
            }
        }
    }
}

/// Apple's gyroscope wallpaper parallax: `UIInterpolatingMotionEffect` drifts the layer
/// opposite device tilt, exactly like the home screen. The system disables motion effects
/// automatically when the user has Reduce Motion on, so no accessibility branch is needed.
private struct ParallaxImage: UIViewRepresentable {
    let image: UIImage
    /// Maximum drift in points on each axis.
    let strength: CGFloat

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        let x = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        x.minimumRelativeValue = -strength
        x.maximumRelativeValue = strength
        let y = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        y.minimumRelativeValue = -strength
        y.maximumRelativeValue = strength
        let group = UIMotionEffectGroup()
        group.motionEffects = [x, y]
        view.addMotionEffect(group)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        if view.image !== image { view.image = image }
    }
}

#Preview {
    MTBackground().ignoresSafeArea()
}
