import SwiftUI
import MetabolicCore

/// Tabs of the root `TabView`.
enum AppTab: String, CaseIterable {
    case today, nutrition, training, scan, you
}

/// A single dashboard widget's position + visibility in the user's customized layout.
struct DashboardWidgetItem: Codable, Equatable, Identifiable {
    var kind: DashboardWidgetKind
    var isVisible: Bool
    var id: String { kind.rawValue }
}

enum DashboardWidgetKind: String, Codable, CaseIterable {
    case calorieRing, macros, water, todayWorkout, streak, weightTrend, scanShortcut, goalsTracker

    var title: String {
        switch self {
        case .calorieRing: return "Calories"
        case .macros: return "Macros"
        case .water: return "Water"
        case .todayWorkout: return "Today's Workout"
        case .streak: return "Streak"
        case .weightTrend: return "Weight Trend"
        case .scanShortcut: return "Scan"
        case .goalsTracker: return "Goals"
        }
    }

    var symbolName: String {
        switch self {
        case .calorieRing: return "flame.fill"
        case .macros: return "chart.pie.fill"
        case .water: return "drop.fill"
        case .todayWorkout: return "figure.strengthtraining.traditional"
        case .streak: return "flame"
        case .weightTrend: return "chart.line.uptrend.xyaxis"
        case .scanShortcut: return "barcode.viewfinder"
        case .goalsTracker: return "target"
        }
    }
}

/// Measurement system for body metrics (weight/height display only — storage stays metric).
enum UnitSystem: String, Codable, CaseIterable {
    case metric, imperial

    var displayName: String {
        switch self {
        case .metric: return "Metric (kg, cm)"
        case .imperial: return "US (lb, ft/in)"
        }
    }
}

/// Selectable accent palette; `MTTheme` resolves these to concrete colors.
enum AccentTheme: String, Codable, CaseIterable {
    case volt, tangerine, earth, jewel

    var displayName: String {
        switch self {
        case .volt: return "Volt Lime"
        case .tangerine: return "Tangerine"
        case .earth: return "Earth Tone"
        case .jewel: return "Jewel Teal"
        }
    }
}

/// Visual style ("skin pack") for the exercise demo clips. The clip resolver looks for
/// `{clipId}.{token}.mp4` first, falling back to the unstyled `{clipId}.mp4` (the shipped
/// anatomy clips), so a pack only needs to supply the exercises it restyles.
enum ClipStyle: String, Codable, CaseIterable {
    case ecorche      // anatomical muscle figure — the shipped default
    case realistic    // realistic human
    case avatar       // stylized 3D-avatar look

    var displayName: String {
        switch self {
        case .ecorche: return "Anatomy"
        case .realistic: return "Realistic"
        case .avatar: return "Avatar"
        }
    }

    var symbolName: String {
        switch self {
        case .ecorche: return "figure.strengthtraining.functional"
        case .realistic: return "figure.stand"
        case .avatar: return "person.crop.circle.fill"
        }
    }

    /// Filename token appended before `.mp4`. `.ecorche` is the unstyled shipped clip, so it has
    /// no token — `{id}.mp4` *is* the anatomy pack and every other pack falls back to it.
    var filenameToken: String? {
        switch self {
        case .ecorche: return nil
        case .realistic: return "realistic"
        case .avatar: return "avatar"
        }
    }
}

/// How the app's canvas is painted behind the cards.
enum BackgroundStyle: String, Codable, CaseIterable {
    case classic     // neutral, as shipped
    case tinted      // neutrals gently mixed toward the accent
    case glass       // liquid-glass: translucent cards over an accent-washed backdrop
    case photo       // user wallpaper behind translucent cards

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .tinted: return "Tinted"
        case .glass: return "Liquid Glass"
        case .photo: return "Photo"
        }
    }

    var symbolName: String {
        switch self {
        case .classic: return "circle.lefthalf.filled"
        case .tinted: return "drop.halffull"
        case .glass: return "sparkles.rectangle.stack"
        case .photo: return "photo.fill"
        }
    }
}

/// Light/dark override for the whole UI — `.system` follows the device setting.
enum AppearanceMode: String, Codable, CaseIterable {
    case system, light, dark

    var displayName: String {
        switch self {
        case .system: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// `nil` = no override, for `preferredColorScheme`.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// App-wide observable state: fitness profile, computed nutrition targets, onboarding flag,
/// dashboard layout, and demo-mode flag. All persisted as JSON in `UserDefaults`.
@Observable
final class AppState {
    var profile: FitnessProfile {
        didSet {
            targets = NutritionEngine.targets(for: profile)
            Self.save(profile, key: Keys.profile)
        }
    }

    var targets: NutritionTargets

    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboarded) }
    }

    var dashboardLayout: [DashboardWidgetItem] {
        didSet { Self.save(dashboardLayout, key: Keys.dashboardLayout) }
    }

    var demoMode: Bool {
        didSet { UserDefaults.standard.set(demoMode, forKey: Keys.demo) }
    }

    var unitSystem: UnitSystem {
        didSet { UserDefaults.standard.set(unitSystem.rawValue, forKey: Keys.units) }
    }

    var accentTheme: AccentTheme {
        didSet {
            UserDefaults.standard.set(accentTheme.rawValue, forKey: Keys.accent)
            ThemeStore.shared.accent = accentTheme
        }
    }

    var backgroundStyle: BackgroundStyle {
        didSet {
            UserDefaults.standard.set(backgroundStyle.rawValue, forKey: Keys.background)
            ThemeStore.shared.backgroundStyle = backgroundStyle
        }
    }

    var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: Keys.appearance) }
    }

    /// Selected bundled wallpaper preset (`WallpaperCatalog` id), or nil for the user's own
    /// photo / no wallpaper. Mirrored into `ThemeStore` for live re-render.
    var wallpaperPresetID: String? {
        didSet {
            UserDefaults.standard.set(wallpaperPresetID, forKey: Keys.wallpaperPreset)
            ThemeStore.shared.wallpaperPreset = wallpaperPresetID
        }
    }

    var wallpaperParallax: Bool {
        didSet {
            UserDefaults.standard.set(wallpaperParallax, forKey: Keys.wallpaperParallax)
            ThemeStore.shared.wallpaperParallax = wallpaperParallax
        }
    }

    var clipStyle: ClipStyle {
        didSet {
            UserDefaults.standard.set(clipStyle.rawValue, forKey: Keys.clipStyle)
            ExerciseClipStore.shared.style = clipStyle
        }
    }

    /// Exercise ids the user has saved/favorited.
    var favoriteExerciseIDs: Set<String> {
        didSet { Self.save(Array(favoriteExerciseIDs), key: Keys.favorites) }
    }

    func toggleFavorite(_ id: String) {
        if favoriteExerciseIDs.contains(id) {
            favoriteExerciseIDs.remove(id)
        } else {
            favoriteExerciseIDs.insert(id)
        }
    }

    func isFavorite(_ id: String) -> Bool {
        favoriteExerciseIDs.contains(id)
    }

    var selectedTab: AppTab = .today

    /// Saves the user's wallpaper photo (JPEG data) and notifies themed views. Uploading a
    /// photo takes over from any selected preset.
    func setWallpaper(_ data: Data) {
        try? data.write(to: ThemeStore.wallpaperURL, options: .atomic)
        wallpaperPresetID = nil
        ThemeStore.shared.wallpaperVersion += 1
    }

    func clearWallpaper() {
        try? FileManager.default.removeItem(at: ThemeStore.wallpaperURL)
        wallpaperPresetID = nil
        ThemeStore.shared.wallpaperVersion += 1
    }

    init() {
        let defaults = UserDefaults.standard
        let loadedProfile = Self.load(FitnessProfile.self, key: Keys.profile) ?? .default
        profile = loadedProfile
        targets = NutritionEngine.targets(for: loadedProfile)
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarded)
        var layout = Self.load([DashboardWidgetItem].self, key: Keys.dashboardLayout)
            ?? DashboardWidgetKind.allCases.map { DashboardWidgetItem(kind: $0, isVisible: true) }
        // Widgets added in updates appear (visible) at the end of previously saved layouts.
        let missingKinds = DashboardWidgetKind.allCases.filter { kind in
            !layout.contains { $0.kind == kind }
        }
        layout.append(contentsOf: missingKinds.map { DashboardWidgetItem(kind: $0, isVisible: true) })
        dashboardLayout = layout
        demoMode = defaults.object(forKey: Keys.demo) != nil ? defaults.bool(forKey: Keys.demo) : true
        unitSystem = defaults.string(forKey: Keys.units).flatMap(UnitSystem.init(rawValue:)) ?? .metric
        accentTheme = defaults.string(forKey: Keys.accent).flatMap(AccentTheme.init(rawValue:)) ?? .volt
        backgroundStyle = defaults.string(forKey: Keys.background)
            .flatMap(BackgroundStyle.init(rawValue:)) ?? .classic
        appearanceMode = defaults.string(forKey: Keys.appearance)
            .flatMap(AppearanceMode.init(rawValue:)) ?? .system
        // ThemeStore reads the same keys in its own init, so no re-mirroring is needed here.
        wallpaperPresetID = defaults.string(forKey: Keys.wallpaperPreset)
        wallpaperParallax = defaults.bool(forKey: Keys.wallpaperParallax)
        clipStyle = defaults.string(forKey: Keys.clipStyle).flatMap(ClipStyle.init(rawValue:)) ?? .ecorche
        favoriteExerciseIDs = Set(Self.load([String].self, key: Keys.favorites) ?? [])
        // Property observers don't fire during init — apply the loaded pack to the shared store.
        ExerciseClipStore.shared.style = clipStyle
    }

    func completeOnboarding(with profile: FitnessProfile) {
        self.profile = profile
        hasCompletedOnboarding = true
    }

    private enum Keys {
        static let profile = "mt.profile"
        static let onboarded = "mt.onboarded"
        static let dashboardLayout = "mt.dashboard.layout"
        static let demo = "mt.demo"
        static let units = "mt.units"
        static let accent = "mt.accent"
        static let background = "mt.background"
        static let appearance = "mt.appearance"
        static let wallpaperPreset = "mt.wallpaper.preset"
        static let wallpaperParallax = "mt.wallpaper.parallax"
        static let clipStyle = "mt.clipStyle"
        static let favorites = "mt.favorites"
    }

    private static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
