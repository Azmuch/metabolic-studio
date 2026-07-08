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
    case calorieRing, macros, water, todayWorkout, streak, weightTrend, scanShortcut

    var title: String {
        switch self {
        case .calorieRing: return "Calories"
        case .macros: return "Macros"
        case .water: return "Water"
        case .todayWorkout: return "Today's Workout"
        case .streak: return "Streak"
        case .weightTrend: return "Weight Trend"
        case .scanShortcut: return "Scan"
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

    var selectedTab: AppTab = .today

    init() {
        let defaults = UserDefaults.standard
        let loadedProfile = Self.load(FitnessProfile.self, key: Keys.profile) ?? .default
        profile = loadedProfile
        targets = NutritionEngine.targets(for: loadedProfile)
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarded)
        dashboardLayout = Self.load([DashboardWidgetItem].self, key: Keys.dashboardLayout)
            ?? DashboardWidgetKind.allCases.map { DashboardWidgetItem(kind: $0, isVisible: true) }
        demoMode = defaults.object(forKey: Keys.demo) != nil ? defaults.bool(forKey: Keys.demo) : true
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
