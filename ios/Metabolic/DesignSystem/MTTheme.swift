import SwiftUI
import UIKit

/// Live theme state. `@Observable` is the key mechanism: any view whose body touches
/// `MTTheme.volt` / `.bg` / etc. transitively reads these tracked properties, so changing
/// the accent or background style re-renders every themed view in place — no identity
/// resets, navigation stacks stay intact.
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    var accent: AccentTheme
    var backgroundStyle: BackgroundStyle
    /// Bumped whenever the wallpaper image file changes so photo backgrounds reload.
    var wallpaperVersion = 0
    /// Bundled preset wallpaper asset name (see `WallpaperCatalog`), or `nil` when the user's
    /// own uploaded photo (or nothing) is in use. A set preset wins over the uploaded file.
    var wallpaperPreset: String?
    /// Apple's gyroscope wallpaper parallax on the photo backdrop.
    var wallpaperParallax: Bool

    private init() {
        accent = UserDefaults.standard.string(forKey: "mt.accent")
            .flatMap(AccentTheme.init(rawValue:)) ?? .volt
        backgroundStyle = UserDefaults.standard.string(forKey: "mt.background")
            .flatMap(BackgroundStyle.init(rawValue:)) ?? .classic
        wallpaperPreset = UserDefaults.standard.string(forKey: "mt.wallpaper.preset")
        wallpaperParallax = UserDefaults.standard.bool(forKey: "mt.wallpaper.parallax")
    }

    /// On-disk location of the user's wallpaper photo (present only when one is set).
    static var wallpaperURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("wallpaper.jpg")
    }

    var hasWallpaper: Bool {
        _ = wallpaperVersion   // register observation so setters refresh readers
        return FileManager.default.fileExists(atPath: Self.wallpaperURL.path)
    }

    /// The image the photo backdrop should draw: the selected preset first, else the
    /// uploaded photo, else `nil` (backdrop falls back to the themed base).
    var activeWallpaperImage: UIImage? {
        _ = wallpaperVersion
        if let wallpaperPreset, let preset = UIImage(named: wallpaperPreset) { return preset }
        return UIImage(contentsOfFile: Self.wallpaperURL.path)
    }
}

/// Bundled wallpaper presets, resolved by naming convention: add images to the asset catalog
/// named `wallpaper.1` … `wallpaper.6`. Missing ones simply don't appear in Settings, so the
/// gallery lights up as assets land (same pattern as the anatomy stills).
enum WallpaperCatalog {
    static let presetIDs: [String] = (1...6).map { "wallpaper.\($0)" }

    static var available: [String] {
        presetIDs.filter { UIImage(named: $0) != nil }
    }
}

/// Metabolic design tokens — near-monochrome surfaces, one signature accent,
/// oversized rounded numerals. Dark-first, fully adaptive to light mode.
/// All dynamic tokens resolve through `ThemeStore.shared`, so theme changes
/// propagate live to every view that uses them.
enum MTTheme {
    // MARK: - Adaptive surfaces (accent-tinted when the background style calls for it)

    static var bg: Color {
        surfaceColor(dark: 0x0B0B0C, light: 0xF6F6F4, tint: 0.12, lightTint: 0.10)
    }
    static var surface: Color {
        surfaceColor(dark: 0x151517, light: 0xFFFFFF, tint: 0.07, lightTint: 0.04)
    }
    static var surface2: Color {
        surfaceColor(dark: 0x1E1E21, light: 0xEFEFEC, tint: 0.12, lightTint: 0.10)
    }
    static let stroke = adaptive(dark: 0xFFFFFF, light: 0x000000, darkAlpha: 0.08, lightAlpha: 0.08)

    // MARK: - Adaptive text

    static let textPrimary = adaptive(dark: 0xFFFFFF, light: 0x0B0B0C)
    static let textSecondary = adaptive(dark: 0xFFFFFF, light: 0x0B0B0C, darkAlpha: 0.6, lightAlpha: 0.6)
    static let textTertiary = adaptive(dark: 0xFFFFFF, light: 0x0B0B0C, darkAlpha: 0.35, lightAlpha: 0.35)

    // MARK: - Accent & semantic colors

    static var volt: Color { Color(uiColor: accentUIColor(for: ThemeStore.shared.accent)) }
    static var voltDim: Color { volt.opacity(0.18) }

    /// Deep, near-black scrim subtly biased toward the accent hue — for hero/photo overlays. Far
    /// darker and more desaturated than `volt`, so white text stays legible and the wash reads
    /// clean rather than a muddy bright-accent band. Tracks the accent, so overlays coordinate
    /// with the chosen UI theme.
    static var heroScrim: Color {
        Color(uiColor: UIColor.black.mixed(with: accentUIColor(for: ThemeStore.shared.accent),
                                           fraction: 0.16))
    }

    /// Light counterpart of `heroScrim`: near-white with a subtle wash of the accent — for the
    /// light, fresh hero overlays (dark ink text stays legible). Tracks the accent theme.
    static var heroScrimLight: Color {
        Color(uiColor: UIColor.white.mixed(with: accentUIColor(for: ThemeStore.shared.accent),
                                           fraction: 0.15))
    }

    static func accentColor(for theme: AccentTheme) -> Color {
        Color(uiColor: accentUIColor(for: theme))
    }

    private static func accentUIColor(for theme: AccentTheme) -> UIColor {
        switch theme {
        case .volt: return UIColor(hex: 0xC8F542)
        case .tangerine: return UIColor(hex: 0xFF9F45)
        case .earth: return UIColor(hex: 0xC9A57B)
        case .jewel: return UIColor(hex: 0x45D6C6)
        }
    }

    static let danger = Color(hex: 0xFF5D4D)
    static let warning = Color(hex: 0xFFB84D)
    static let success = Color(hex: 0x4DDB82)
    static let water = Color(hex: 0x4DA8FF)
    static let protein = Color(hex: 0xB98CFF)
    static let carbs = Color(hex: 0xFFC24D)
    static let fat = Color(hex: 0xFF8A5C)

    // MARK: - Metrics

    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 14

    // MARK: - Type

    /// Oversized rounded numerals — used for every metric on the dashboard.
    static func numberFont(size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    // MARK: - Helpers

    /// Neutral base, or the base gently mixed toward the accent for the tinted /
    /// glass / photo background styles.
    private static func surfaceColor(dark: UInt32, light: UInt32,
                                     tint: CGFloat, lightTint: CGFloat) -> Color {
        let style = ThemeStore.shared.backgroundStyle
        let accent = accentUIColor(for: ThemeStore.shared.accent)
        let tinted = style != .classic
        return Color(uiColor: UIColor { traits in
            let base = traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
            guard tinted else { return base }
            let fraction = traits.userInterfaceStyle == .dark ? tint : lightTint
            return base.mixed(with: accent, fraction: fraction)
        })
    }

    private static func adaptive(dark: UInt32, light: UInt32,
                                 darkAlpha: Double = 1, lightAlpha: Double = 1) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        })
    }
}

extension Color {
    fileprivate init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

fileprivate extension UIColor {
    convenience init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }

    /// Per-channel blend toward `other` — keeps the neutral's lightness while
    /// borrowing the accent's hue at low fractions.
    func mixed(with other: UIColor, fraction: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = max(0, min(1, fraction))
        return UIColor(red: r1 + (r2 - r1) * t,
                       green: g1 + (g2 - g1) * t,
                       blue: b1 + (b2 - b1) * t,
                       alpha: a1)
    }
}

#Preview("Tokens") {
    ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(swatches.enumerated()), id: \.offset) { _, swatch in
                HStack {
                    RoundedRectangle(cornerRadius: 8).fill(swatch.1).frame(width: 40, height: 40)
                    Text(swatch.0).foregroundStyle(MTTheme.textPrimary)
                }
            }
        }
        .padding(20)
    }
    .background(MTTheme.bg)
}

private let swatches: [(String, Color)] = [
    ("bg", MTTheme.bg), ("surface", MTTheme.surface), ("surface2", MTTheme.surface2),
    ("volt", MTTheme.volt), ("voltDim", MTTheme.voltDim), ("danger", MTTheme.danger),
    ("warning", MTTheme.warning), ("success", MTTheme.success), ("water", MTTheme.water),
    ("protein", MTTheme.protein), ("carbs", MTTheme.carbs), ("fat", MTTheme.fat),
]
