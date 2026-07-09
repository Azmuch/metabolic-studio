# Cross-bucket interface contract (HARD CONTRACT — addendum to SPEC.md)

Each type below is owned by exactly ONE bucket. Other buckets may reference it but must
NOT declare it. Signatures listed here are the minimal public surface other buckets rely
on; owners may add more members but never rename/remove these.

## Ownership map

| Bucket | Owns (top-level types) |
|---|---|
| A (MetabolicCore) | everything in SPEC §4 |
| B (Shell) | `MetabolicApp`, `RootTabView`, `TodayView`, `AppState`, `AppTab`, `DashboardWidgetKind`, `DashboardWidgetItem`, `FoodEntry`, `FoodEntrySource`, `WaterEntry`, `WorkoutLog`, `WeightEntry`, `ScanRecord`, `DemoDataSeeder`, `MTTheme`, `MTCard`, `MTRing`, `MTChip`, `MTPrimaryButton`, `MTSecondaryButton`, `MTProgressBar`, `MTEmptyState`, `MTSheetHeader`, `ScoreBadge`, `Haptics` |
| C (Nutrition) | `NutritionView`, `AddFoodSheet`, `ManualFoodEntryView`, `FoodSearchView`, `MealPhotoView`, `WaterDetailView`, `OpenFoodFactsClient`, `ClaudeVisionClient`, `MealVisionError`, `APIKeyStore`, `UsageMeter`, `DemoMealAnalysis` |
| D (Training) | `TrainingView`, `OnboardingFlowView`, `ProfileEditorView`, `ExerciseAnimationView`, `ExerciseDetailView`, `SessionPlayerView`, `PlanDetailView` |
| E (Commerce/Health) | `ScanTabView`, `YouView`, `SettingsView`, `BarcodeScannerView`, `ScanResultView`, `PaywallView`, `SubscriptionTier`, `SubscriptionManager`, `Feature`, `FeatureGate`, `HealthKitService`, `CSVExporter` |
| F (Devices) | `SmartScaleService`, `ScaleDevice`, `ScaleConnectionState`, `SmartScaleSheet` — CoreBluetooth food scale (Weight Scale GATT 0x181D + simulated device). `SmartScaleSheet(onUseWeight:)` hands settled grams back to logging flows; injected app-wide via `.environment(SmartScaleService())`. |

## Tab roots (RootTabView switches on `AppTab`)

- `.today` → `TodayView()` (B) · `.nutrition` → `NutritionView()` (C) · `.training` →
  `TrainingView()` (D) · `.scan` → `ScanTabView()` (E) · `.you` → `YouView()` (E)
- `MetabolicApp` shows `OnboardingFlowView()` (D) when `!appState.hasCompletedOnboarding`.

## B — environment & models (exact stored properties; others must match on use)

```swift
enum AppTab: String, CaseIterable { case today, nutrition, training, scan, you }

@Observable final class AppState {
    var profile: FitnessProfile            // persisted (UserDefaults "mt.profile", JSON)
    var targets: NutritionTargets          // recomputed whenever profile is set
    var hasCompletedOnboarding: Bool       // "mt.onboarded"
    var dashboardLayout: [DashboardWidgetItem]  // "mt.dashboard.layout"
    var demoMode: Bool                     // "mt.demo", default true
    var selectedTab: AppTab
    func completeOnboarding(with profile: FitnessProfile)
}

struct DashboardWidgetItem: Codable, Equatable, Identifiable {
    var kind: DashboardWidgetKind; var isVisible: Bool; var id: String { kind.rawValue }
}
enum DashboardWidgetKind: String, Codable, CaseIterable {
    case calorieRing, macros, water, todayWorkout, streak, weightTrend, scanShortcut
    var title: String { get }; var symbolName: String { get }
}

enum FoodEntrySource: String, Codable, CaseIterable { case manual, search, photo, barcode }

@Model final class FoodEntry {   // init labels: (date:mealType:name:brand:calories:proteinG:carbsG:fatG:grams:source:)
    var date: Date; var mealTypeRaw: String; var name: String; var brand: String?
    var calories: Double; var proteinG: Double; var carbsG: Double; var fatG: Double
    var grams: Double?; var sourceRaw: String
    var mealType: MealType { get set }     // bridges mealTypeRaw
    var source: FoodEntrySource { get set }
}
@Model final class WaterEntry { var date: Date; var amountML: Int }        // init(date:amountML:)
@Model final class WorkoutLog {                                            // init(date:title:focus:minutes:calories:completedExerciseIDs:)
    var date: Date; var title: String; var focusRaw: String; var minutes: Int
    var calories: Int; var completedExerciseIDs: [String]
    var focus: DayFocus { get set }
}
@Model final class WeightEntry { var date: Date; var weightKg: Double }    // init(date:weightKg:)
@Model final class ScanRecord {                                            // init(date:barcode:name:brand:scoreValue:rating:imageURLString:)
    var date: Date; var barcode: String; var name: String; var brand: String?
    var scoreValue: Int; var ratingRaw: String; var imageURLString: String?
    var rating: ScoreRating { get set }
}
```

`MetabolicApp` creates `AppState()`, `SubscriptionManager()`, `HealthKitService()` and
injects all three with `.environment(...)`; consume with
`@Environment(AppState.self) private var appState` etc.
ModelContainer registers all five @Model types; views use `@Environment(\.modelContext)`
and `@Query`.

### Design-system API (B)

```swift
enum MTTheme {
    static let bg, surface, surface2, stroke: Color
    static let textPrimary, textSecondary, textTertiary: Color
    static let volt, voltDim, danger, warning, success, water, protein, carbs, fat: Color
    static func numberFont(size: CGFloat) -> Font
    static let cardRadius: CGFloat   // 24
    static let controlRadius: CGFloat // 14
}
struct MTCard<Content: View>: View       // MTCard { content } — surface, radius 24, stroke, padding 20
struct MTRing: View                       // MTRing(progress: Double, lineWidth: CGFloat = 12, tint: Color = MTTheme.volt)
struct MTChip: View                       // MTChip(text: String, systemImage: String? = nil, isActive: Bool = false)
struct MTPrimaryButton: View              // MTPrimaryButton(title: String, systemImage: String? = nil, action: () -> Void)
struct MTSecondaryButton: View            // same signature
struct MTProgressBar: View                // MTProgressBar(progress: Double, tint: Color = MTTheme.volt)
struct MTEmptyState: View                 // MTEmptyState(symbol: String, title: String, message: String)
struct MTSheetHeader: View                // MTSheetHeader(title: String) — grabber-style sheet title row
struct ScoreBadge: View                   // ScoreBadge(score: Int, rating: ScoreRating) — colored pill
enum Haptics { static func tap(); static func success(); static func warning() }
```

Rating colors used app-wide: excellent = MTTheme.success, good = Color(hex 0xA3D65C) (define
inside ScoreBadge), poor = MTTheme.warning, bad = MTTheme.danger.

## C — cross-referenced API

```swift
enum UsageMeter {   // UserDefaults counters, auto-reset by day/month
    static func scansToday() -> Int;            static func recordScan()
    static func aiAnalysesThisMonth() -> Int;   static func recordAIAnalysis()
}
struct AddFoodSheet: View { init(mealType: MealType) }   // segmented: Search / Manual / Photo
final class OpenFoodFactsClient {
    init()
    func product(barcode: String) async throws -> ScannedProduct?
    func searchFoods(query: String) async throws -> [FoodItem]
    func alternatives(categories: [String], excludingBarcode: String) async throws -> [(ScannedProduct, ProductScore)]
}
enum MealVisionError: Error { case noAPIKey, badResponse, decodingFailed }
final class ClaudeVisionClient {
    init()
    func analyzeMeal(imageData: Data) async throws -> MealPhotoAnalysis
}
enum APIKeyStore {  // Keychain-backed
    static func load() -> String?; static func save(_ key: String); static func clear()
}
enum DemoMealAnalysis { static let sample: MealPhotoAnalysis }
```

## E — cross-referenced API

```swift
enum SubscriptionTier: Int, Codable, Comparable, CaseIterable {
    case free = 0, plus = 1, pro = 2
    var displayName: String { get }
}
enum Feature: String, CaseIterable {
    case aiPhotoAnalysis, unlimitedScans, dashboardCustomize, fullExerciseLibrary,
         adaptivePlans, dataExport
}
enum FeatureGate {
    static func minTier(for feature: Feature) -> SubscriptionTier
    static func allows(_ feature: Feature, tier: SubscriptionTier) -> Bool
}
@Observable final class SubscriptionManager {
    var tier: SubscriptionTier              // .free until entitlement found
    func configure() async                  // load products + start transaction listener
    func purchase(productID: String) async throws
    func restore() async
}
@Observable final class HealthKitService {
    var isAuthorized: Bool
    func requestAuthorization() async
    func saveMeal(_ entry: FoodEntry) async
    func saveWater(ml: Int, date: Date) async
    func saveWorkout(_ log: WorkoutLog) async
    func readLatestWeight() async -> Double?
    func readTodaySteps() async -> Int?
}
struct PaywallView: View { init() }         // presented in .sheet from any bucket
struct ScanResultView: View { init(product: ScannedProduct, score: ProductScore) }
```

Gate UX convention (all buckets): when a gated action is blocked, show the lock chip
`MTChip(text:"Plus", systemImage:"lock.fill")` and present `PaywallView()` in a sheet.

## D — cross-referenced API

```swift
struct OnboardingFlowView: View { init() }        // calls appState.completeOnboarding(with:)
struct ProfileEditorView: View { init() }          // edits appState.profile in place
struct ExerciseAnimationView: View { init(exercise: Exercise, tint: Color = MTTheme.volt) }
struct ExerciseDetailView: View { init(exercise: Exercise) }
struct SessionPlayerView: View { init(plan: WorkoutPlan) }  // fullScreenCover; saves WorkoutLog + HealthKit on finish
```

## Conventions

- Every Swift file in the app target starts with `import SwiftUI` (plus what it needs) and
  `import MetabolicCore` when using core types.
- Dates: compare days with `Calendar.current.isDate(_:inSameDayAs:)`; "today" queries use
  `#Predicate` on a start/end-of-day range.
- No third-party dependencies. No storyboards. No UIKit except inside
  UIViewControllerRepresentable (scanner) and Haptics.
- Previews: every view gets `#Preview` with in-memory model container where needed.
