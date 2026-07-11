import SwiftUI
import UIKit

/// Metabolic design tokens — near-monochrome surfaces, one signature "Volt" accent,
/// oversized rounded numerals. Dark-first, fully adaptive to light mode.
enum MTTheme {
    // MARK: - Adaptive surfaces

    static let bg = adaptive(dark: 0x0B0B0C, light: 0xF6F6F4)
    static let surface = adaptive(dark: 0x151517, light: 0xFFFFFF)
    static let surface2 = adaptive(dark: 0x1E1E21, light: 0xEFEFEC)
    static let stroke = adaptive(dark: 0xFFFFFF, light: 0x000000, darkAlpha: 0.08, lightAlpha: 0.08)

    // MARK: - Adaptive text

    static let textPrimary = adaptive(dark: 0xFFFFFF, light: 0x0B0B0C)
    static let textSecondary = adaptive(dark: 0xFFFFFF, light: 0x0B0B0C, darkAlpha: 0.6, lightAlpha: 0.6)
    static let textTertiary = adaptive(dark: 0xFFFFFF, light: 0x0B0B0C, darkAlpha: 0.35, lightAlpha: 0.35)

    // MARK: - Accent & semantic colors (same in both appearances)

    /// Resolves from the user's selected `AccentTheme` (persisted in UserDefaults "mt.accent").
    /// Every screen keeps using `MTTheme.volt` / `voltDim` — only the underlying color changes.
    static var volt: Color { accent(for: currentAccent) }
    static var voltDim: Color { accent(for: currentAccent).opacity(0.18) }

    private static var currentAccent: AccentTheme {
        UserDefaults.standard.string(forKey: "mt.accent").flatMap(AccentTheme.init(rawValue:)) ?? .volt
    }

    private static func accent(for theme: AccentTheme) -> Color {
        switch theme {
        case .volt: return Color(hex: 0xC8F542)
        case .tangerine: return Color(hex: 0xFF9F45)
        case .earth: return Color(hex: 0xC9A57B)
        case .jewel: return Color(hex: 0x45D6C6)
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

    private static func adaptive(dark: UInt32, light: UInt32, darkAlpha: Double = 1, lightAlpha: Double = 1) -> Color {
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
