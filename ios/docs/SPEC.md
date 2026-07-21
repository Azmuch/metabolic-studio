# Metabolic — iOS Fitness & Nutrition App — Product & Engineering Spec

**Version 1.0 — the single source of truth for all execution buckets.**
Every type name, enum case, and signature in §4 is a hard contract. Do not rename, do not add
cases, do not change signatures. If something seems missing, implement exactly what is written
here and leave a `// SPEC-GAP:` comment rather than inventing new shared API.

---

## 1. Product

**Metabolic** is a minimalist, dark-first iOS fitness tracker that competes with MyFitnessPal:

1. **Today dashboard** — customizable widget stack (calorie ring, macros, water, today's
   workout, streak, weight trend, scanner shortcut). User can reorder & hide widgets.
2. **Nutrition** — food diary by meal (breakfast/lunch/dinner/snack), manual entry, food
   search (seed database + OpenFoodFacts), **AI meal-photo analysis** (Claude vision API
   estimates portions & calories), water tracking with animated fill.
3. **Training** — daily workout plan generated from the user's fitness profile (age, sex,
   body metrics, goal, experience, injuries, equipment, schedule). Every exercise has an
   **animated illustration** (pose-keyframe skeleton rendered in SwiftUI Canvas), a session
   player with set/rep/rest timers, and calories-burned estimates (MET-based).
4. **Scan (Yuka-style)** — barcode scan → 0–100 health score (60% nutrition via
   Nutri-Score points, 30% additives risk, 10% organic), color rating, factor breakdown,
   and healthier alternatives in the same category.
5. **Profile & onboarding** — collects the fitness profile, computes calorie/macro/water
   targets (Mifflin-St Jeor BMR → TDEE → goal adjustment).
6. **Subscriptions** — Free / Plus / Pro via StoreKit 2 (§7).
7. **Apple Health** — writes meals, water, workouts; reads weight/steps/active energy.

Non-goals for v1: social features, Android, server backend (AI calls go direct-to-API with
user key or demo mode).

## 2. Platform & architecture

- iOS 17.0+, Swift 5.10, SwiftUI, SwiftData, Observation (`@Observable`), StoreKit 2,
  HealthKit, VisionKit (barcode), PhotosUI.
- Xcode 16 project (`Metabolic.xcodeproj`) using **fileSystemSynchronizedGroups** — any file
  added under `Metabolic/` is automatically in the app target. Never edit the pbxproj.
- Local Swift package **MetabolicCore** — ALL platform-independent domain logic. Foundation
  only (no SwiftUI/UIKit/CoreGraphics imports) so it compiles & tests on Linux.

```
ios/
  Metabolic.xcodeproj/
  Metabolic/                     # app target (synchronized folder)
    App/                         # entry, root tabs, AppState, DI
    DesignSystem/                # MTTheme tokens + shared components
    Features/
      Dashboard/  Nutrition/  Training/  Scanner/  Paywall/  Onboarding/  Settings/
    Services/                    # HealthKit, StoreKit, persistence, network clients
    Models/                      # SwiftData @Model classes
    Support/                     # Info.plist lives at Metabolic/ root, assets, storekit cfg
  MetabolicCore/
    Package.swift
    Sources/MetabolicCore/
    Tests/MetabolicCoreTests/
  docs/SPEC.md   tools/verify_swift.py   README.md
```

## 3. Design system — `MTTheme` (award-level minimalist)

Aesthetic: near-monochrome surfaces, ONE signature accent ("Volt" lime), oversized rounded
numerals, 24pt-radius cards, generous whitespace, spring animations, SF Symbols only.
Dark-first but fully adaptive via semantic tokens.

```swift
enum MTTheme {
    // Colors (Color extensions defined in DesignSystem/MTTheme.swift, adaptive light/dark)
    // bg        dark #0B0B0C / light #F6F6F4
    // surface   dark #151517 / light #FFFFFF
    // surface2  dark #1E1E21 / light #EFEFEC
    // stroke    dark white 8% / light black 8%
    // textPrimary / textSecondary (60%) / textTertiary (35%)
    // volt      #C8F542  (accent — rings, CTAs, highlights)
    // voltDim   volt at 18% (fills behind accent content)
    // danger #FF5D4D, warning #FFB84D, success #4DDB82, water #4DA8FF, protein #B98CFF,
    // carbs #FFC24D, fat #FF8A5C
}
```

- Spacing: 4pt grid — use 4/8/12/16/20/24/32. Screen H-padding 20. Card padding 20.
- Radius: card 24, control 14, chip 999 (capsule).
- Type: system font. Numerals use `.rounded` design, heavy weights
  (`MTTheme.numberFont(size:)` → `.system(size:, weight: .heavy, design: .rounded)`).
  Section headers: 13pt semibold uppercase tracking 1.2, textSecondary.
- Shared components (DesignSystem/): `MTCard` (surface + radius 24 + 1px stroke),
  `MTRing` (animated circular progress, 12pt line, rounded caps), `MTChip`,
  `MTPrimaryButton` (volt bg, black text, capsule, haptic on tap), `MTSecondaryButton`,
  `MTProgressBar`, `MTEmptyState`, `MTSheetHeader`, `ScoreBadge` (color-coded 0-100 pill).
- Haptics helper: `Haptics.tap()`, `.success()`, `.warning()` wrapping UIKit generators.
- Motion: `.spring(response: 0.45, dampingFraction: 0.8)` standard; rings animate on appear.

## 4. MetabolicCore — public contracts (HARD CONTRACT)

Everything below is `public`, Foundation-only, `Sendable` where shown.

### 4.1 Profile

```swift
public enum BiologicalSex: String, Codable, CaseIterable, Sendable { case male, female }
public enum FitnessGoal: String, Codable, CaseIterable, Sendable {
    case loseFat, maintain, gainMuscle, improveEndurance
    public var displayName: String
}
public enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary, light, moderate, active, veryActive
    public var displayName: String;  public var multiplier: Double // 1.2/1.375/1.55/1.725/1.9
}
public enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case beginner, intermediate, advanced;  public var displayName: String
}
public enum Equipment: String, Codable, CaseIterable, Sendable {
    case none, dumbbells, resistanceBands, kettlebell, barbell, pullUpBar, bench, fullGym
    public var displayName: String;  public var symbolName: String // SF Symbol
}
public enum InjuryFlag: String, Codable, CaseIterable, Sendable {
    case knee, lowerBack, shoulder, wrist, ankle, hip, neck, limitedMobility
    public var displayName: String
}
public struct FitnessProfile: Codable, Equatable, Sendable {
    public var age: Int; public var sex: BiologicalSex
    public var heightCm: Double; public var weightKg: Double
    public var goal: FitnessGoal; public var activityLevel: ActivityLevel
    public var experience: ExperienceLevel
    public var equipment: Set<Equipment>; public var injuries: Set<InjuryFlag>
    public var workoutDaysPerWeek: Int   // 2...6
    public var sessionMinutes: Int       // 15...90
    public init(age: Int = 30, sex: BiologicalSex = .male, heightCm: Double = 175,
                weightKg: Double = 75, goal: FitnessGoal = .maintain,
                activityLevel: ActivityLevel = .moderate,
                experience: ExperienceLevel = .beginner,
                equipment: Set<Equipment> = [.none], injuries: Set<InjuryFlag> = [],
                workoutDaysPerWeek: Int = 3, sessionMinutes: Int = 30)
    public static let `default` = FitnessProfile()
}
```

### 4.2 Nutrition engine

```swift
public struct NutritionTargets: Codable, Equatable, Sendable {
    public var calories: Int; public var proteinG: Int; public var carbsG: Int
    public var fatG: Int; public var waterML: Int
}
public enum NutritionEngine {
    /// Mifflin-St Jeor: 10w + 6.25h − 5a + (male ? +5 : −161)
    public static func bmr(for p: FitnessProfile) -> Double
    /// bmr × activity multiplier
    public static func tdee(for p: FitnessProfile) -> Double
    /// Goal adjustment: loseFat −20%, maintain 0, gainMuscle +12%, improveEndurance +5%.
    /// Protein g/kg: loseFat 2.0, maintain 1.6, gainMuscle 2.0, endurance 1.6.
    /// Fat = 27% of calories (9 kcal/g); carbs = remainder (4 kcal/g); protein 4 kcal/g.
    /// Water: 35 ml/kg clamped to 1500...4000, rounded to nearest 50.
    /// Calories floor: never below 1200 (female) / 1500 (male).
    public static func targets(for p: FitnessProfile) -> NutritionTargets
}
public enum CalorieBurnCalculator {
    /// kcal = MET × 3.5 × kg / 200 × minutes
    public static func kilocalories(met: Double, weightKg: Double, minutes: Double) -> Double
}
```

### 4.3 Exercises & pose animation data

Pose data is pure math (no CoreGraphics — use `PosePoint`).

```swift
public struct PosePoint: Codable, Equatable, Sendable { public var x: Double; public var y: Double
    public init(_ x: Double, _ y: Double) }
public enum Joint: String, Codable, CaseIterable, Sendable {
    case head, neck, leftShoulder, rightShoulder, leftElbow, rightElbow,
         leftWrist, rightWrist, hip, leftKnee, rightKnee, leftAnkle, rightAnkle
}
/// One keyframe: every joint MUST be present. Normalized space: x,y ∈ [0,1], y grows downward,
/// figure roughly centered at x=0.5. Bones: head–neck, neck–hip,
/// neck–{left,right}Shoulder, shoulder–elbow–wrist ×2, hip–knee–ankle ×2.
public struct Pose: Codable, Equatable, Sendable {
    public var joints: [Joint: PosePoint]
    public init(_ joints: [Joint: PosePoint])
    public static func interpolate(from: Pose, to: Pose, t: Double) -> Pose // smoothstep t
}
public enum ExerciseKind: Codable, Equatable, Sendable { case reps(Int); case timed(seconds: Int) }
public enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest, back, shoulders, arms, core, quads, hamstrings, glutes, calves, fullBody, cardio
    public var displayName: String
}
public struct Exercise: Identifiable, Codable, Equatable, Sendable {
    public var id: String            // stable slug, e.g. "squat"
    public var name: String
    public var muscleGroups: [MuscleGroup]
    public var equipment: Set<Equipment>       // [.none] == bodyweight
    public var contraindications: Set<InjuryFlag>
    public var met: Double
    public var kind: ExerciseKind              // default prescription
    public var instructions: [String]          // 3–4 short cues
    public var keyframes: [Pose]               // ≥2; animation loops through them
    public var secondsPerCycle: Double         // one full rep-cycle duration
}
public enum ExerciseLibrary {
    public static let all: [Exercise]          // ≥ 22 exercises, see bucket A order
    public static func exercise(id: String) -> Exercise?
    public static func available(equipment: Set<Equipment>, injuries: Set<InjuryFlag>) -> [Exercise]
}
```

### 4.4 Workout plan generator

```swift
public enum DayFocus: String, Codable, CaseIterable, Sendable {
    case fullBody, upperBody, lowerBody, push, pull, core, cardio, rest
    public var displayName: String
}
public struct WorkoutItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String              // exercise id
    public var exercise: Exercise
    public var sets: Int
    public var kind: ExerciseKind      // resolved reps/seconds for THIS plan
    public var restSeconds: Int
}
public struct WorkoutPlan: Codable, Equatable, Sendable {
    public var date: Date; public var focus: DayFocus; public var title: String
    public var items: [WorkoutItem]
    public var estimatedMinutes: Int
    public func estimatedCalories(weightKg: Double) -> Int
}
public struct SeededRandom {                 // deterministic xorshift64*
    public init(seed: UInt64); public mutating func next() -> UInt64
    public mutating func int(in range: ClosedRange<Int>) -> Int
    public mutating func pick<T>(_ array: [T]) -> T?
}
public enum WorkoutPlanGenerator {
    /// Deterministic for (profile, date-day). Rest days per workoutDaysPerWeek spread
    /// across Mon-Sun; plan(for:) on a rest day returns focus == .rest with empty items.
    public static func weeklySplit(for p: FitnessProfile) -> [DayFocus]      // 7 entries Mon..Sun
    public static func plan(for p: FitnessProfile, date: Date, calendar: Calendar) -> WorkoutPlan
}
```

Rules: filter `ExerciseLibrary.available(equipment:injuries:)`; goal sets rep ranges & rest
(loseFat 12–15 reps/45 s, maintain 10–12/60 s, gainMuscle 8–12/90 s, endurance 15–20/40 s);
exercise count ≈ `max(3, min(8, sessionMinutes / 8))`; order compound → isolation → core/cardio
finisher; estimatedMinutes from sets × (work + rest) + 5 min warm-up. Beginners get −1
exercise and timed cores; advanced +1.

### 4.5 Food & meal-photo models

```swift
public enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast, lunch, dinner, snack
    public var displayName: String;  public var symbolName: String
}
public struct FoodItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String; public var name: String; public var brand: String?
    public var servingDescription: String   // "1 cup (240 ml)"
    public var calories: Double; public var proteinG: Double
    public var carbsG: Double; public var fatG: Double
}
public enum FoodDatabase {
    public static let common: [FoodItem]                 // ≥ 60 realistic seed foods
    public static func search(_ query: String) -> [FoodItem]
}
public struct AnalyzedFoodItem: Codable, Equatable, Sendable, Identifiable {
    public var id: String { name }
    public var name: String; public var portionDescription: String
    public var estimatedGrams: Double; public var calories: Double
    public var proteinG: Double; public var carbsG: Double; public var fatG: Double
    public var confidence: Double            // 0...1
}
public struct MealPhotoAnalysis: Codable, Equatable, Sendable {
    public var items: [AnalyzedFoodItem]; public var notes: String?
    public var totalCalories: Double { get } // computed sum
}
```

### 4.6 Product scoring (Yuka-style)

```swift
public enum AdditiveRisk: Int, Codable, Comparable, Sendable {
    case none = 0, limited = 1, moderate = 2, high = 3
    public var displayName: String
}
public enum AdditiveTable {
    /// ≥ 40 common E-codes → risk (e.g. e102 .high, e330 .none, e621 .moderate, e250 .high,
    /// e300 .none, e407 .moderate, e951 .high …). Lookup is case-insensitive, accepts "E330"/"en:e330".
    public static func risk(for eCode: String) -> AdditiveRisk
    public static func name(for eCode: String) -> String   // human name if known, else code
}
public struct ScannedProduct: Codable, Equatable, Sendable {
    public var barcode: String; public var name: String; public var brand: String?
    public var imageURLString: String?
    public var isBeverage: Bool; public var isOrganic: Bool
    // per 100 g/ml:
    public var energyKcal: Double?; public var sugarsG: Double?; public var satFatG: Double?
    public var sodiumMg: Double?; public var fiberG: Double?; public var proteinG: Double?
    public var fruitVegPercent: Double?
    public var additives: [String]            // raw E-codes
    public var categories: [String]           // OFF category tags
}
public enum ScoreRating: String, Codable, Sendable {
    case excellent, good, poor, bad          // 75–100 / 50–74 / 25–49 / 0–24
    public var displayName: String
}
public struct ScoreFactor: Identifiable, Codable, Equatable, Sendable {
    public var id: String { title }
    public var title: String; public var detail: String
    public var isPositive: Bool; public var symbolName: String
}
public struct ProductScore: Codable, Equatable, Sendable {
    public var value: Int                    // 0...100
    public var rating: ScoreRating
    public var positives: [ScoreFactor]; public var negatives: [ScoreFactor]
}
public enum ProductScoringEngine {
    /// 60% nutrition + 30% additives + 10% organic.
    /// Nutrition: Nutri-Score points/100g (energy, sugars, satFat, sodium negative;
    /// fiber, protein, fruitVeg positive; beverage thresholds when isBeverage).
    /// Map final Nutri-Score −15…40 → 100…0 linearly.
    /// Additives subscore: none present→100; worst=limited→70; moderate→35; high→0.
    /// Organic: 100 or 0. Caps: any HIGH-risk additive caps total at 49;
    /// worst=MODERATE caps at 74. Missing nutriment values are treated as 0 points
    /// (documented "incomplete data" negative factor when energyKcal == nil).
    public static func score(_ product: ScannedProduct) -> ProductScore
}
```

### 4.7 Tracking math

```swift
public enum StreakCalculator {
    /// Consecutive-day streak counting back from `today`; a day counts if it appears in
    /// `loggedDays` (startOfDay dates). Today missing is allowed (streak continues from yesterday).
    public static func currentStreak(loggedDays: Set<Date>, today: Date, calendar: Calendar) -> Int
}
```

## 5. App-side models (SwiftData, in `Metabolic/Models/`)

```swift
@Model final class FoodEntry     // date, mealTypeRaw, name, brand?, calories, proteinG, carbsG, fatG, grams?, source(raw: manual|search|photo|barcode)
@Model final class WaterEntry    // date, amountML
@Model final class WorkoutLog    // date, title, focusRaw, minutes, calories, completedExerciseIDs: [String]
@Model final class WeightEntry   // date, weightKg
@Model final class ScanRecord    // date, barcode, name, brand?, scoreValue, ratingRaw, imageURLString?
```

`AppState` (`@Observable`, in App/): holds `FitnessProfile` (persisted as JSON in
UserDefaults key `"mt.profile"`), `NutritionTargets` (recomputed on profile change),
onboarding-complete flag, dashboard layout, demo-mode flag. Injected via `.environment(...)`.

Dashboard customization: `enum DashboardWidgetKind: String, Codable, CaseIterable` —
`calorieRing, macros, water, todayWorkout, streak, weightTrend, scanShortcut`. `AppState`
stores ordered visible list (UserDefaults JSON key `"mt.dashboard.layout"`); Dashboard edit
mode = List with `.onMove` + toggles, gated by Plus tier (`FeatureGate`).

## 6. Services (`Metabolic/Services/`)

- `HealthKitService` (@Observable): `requestAuthorization()`, `saveMeal(FoodEntry)`,
  `saveWater(ml:date:)`, `saveWorkout(WorkoutLog)`, `readLatestWeight()`,
  `readTodaySteps()`. Guard `HKHealthStore.isHealthDataAvailable()`. Types: dietaryEnergyConsumed,
  dietaryProtein, dietaryCarbohydrates, dietaryFatTotal, dietaryWater, bodyMass, stepCount,
  workouts (HKWorkoutBuilder, .traditionalStrengthTraining / .running for cardio focus).
- `OpenFoodFactsClient`: `product(barcode:) async throws -> ScannedProduct?` (GET
  `https://world.openfoodfacts.org/api/v2/product/{code}.json` with fields param),
  `searchFoods(query:) async -> [FoodItem]`, `alternatives(categories:excluding:) async -> [(ScannedProduct, ProductScore)]`
  (category search, score locally, return top-scoring better products). Map `nova_group`,
  `additives_tags`, `labels_tags` contains "en:organic", beverage from categories.
- `ClaudeVisionClient`: `analyzeMeal(imageData: Data) async throws -> MealPhotoAnalysis`.
  POST `https://api.anthropic.com/v1/messages`, model `"claude-sonnet-5"`, headers
  `x-api-key` (from Keychain via `APIKeyStore`), `anthropic-version: 2023-06-01`; content:
  base64 image block + prompt demanding STRICT JSON matching `MealPhotoAnalysis`;
  parse first ```json block or raw JSON. If no API key → throw `MealVisionError.noAPIKey`;
  UI falls back to `DemoMealAnalysis.sample` when demo mode on.
- `SubscriptionManager` (@Observable): StoreKit 2. Product ids:
  `com.metabolicstudio.metabolic.plus.monthly|plus.yearly|pro.monthly|pro.yearly`.
  `tier: SubscriptionTier` (`enum SubscriptionTier: Int, Comparable { case free, plus, pro }`),
  `purchase(Product)`, `restore()`, transaction listener, `Products.storekit` local config.
- `FeatureGate`: `enum Feature { aiPhotoAnalysis, unlimitedScans, dashboardCustomize, fullExerciseLibrary, adaptivePlans, dataExport }`
  → `minTier`. Free limits: 3 scans/day, 0 AI analyses (Plus: 30/mo, Pro: unlimited) —
  counters in UserDefaults (`UsageMeter`).
- `BarcodeScannerView`: UIViewControllerRepresentable over VisionKit
  `DataScannerViewController` (barcode symbologies: ean13, ean8, upce, code128).

## 7. Subscription tiers

| | Free | Plus $4.99/mo ($39.99/yr) | Pro $9.99/mo ($79.99/yr) |
|---|---|---|---|
| Manual logging, water, streaks | ✓ | ✓ | ✓ |
| Daily workout plan | 1 preset/day | full library | adaptive (uses recent logs) |
| Barcode scans | 3/day | unlimited | unlimited |
| AI photo analysis | — | 30/mo | unlimited |
| Dashboard customization | — | ✓ | ✓ |
| Apple Health sync | ✓ | ✓ | ✓ |
| Data export (CSV) | — | — | ✓ |

Paywall: hero, tier cards with feature list, monthly/yearly toggle (yearly badge "save 33%"),
StoreKit purchase, restore, legal footnote. Soft-sell at onboarding end (skippable) and at
gate hits.

## 8. Screens (5 tabs + flows)

Tabs: **Today** (dashboard) · **Nutrition** · **Training** · **Scan** · **You** (profile/settings).
Key flows: Onboarding (9 steps, springy, progress bar) → main. Food add sheet (search/manual/
photo/barcode segmented). Session player (full-screen, one exercise at a time, animated
figure, set counter, rest countdown ring, haptics, finish → save WorkoutLog + HealthKit).
Scan result sheet (score hero + factors + alternatives). Exercise detail (big animation,
cues, muscles, equipment). Settings: profile edit, HealthKit toggles, API key, demo mode,
subscription management, export (Pro).

## 9. Verifier criteria

1. `MetabolicCore`: `swift build && swift test` pass (Linux-compatible: Foundation only).
   Tests cover: BMR/TDEE/targets exact values, plan generator determinism + injury/equipment
   filtering + rest days, scoring engine known products (incl. caps), additive table,
   pose interpolation endpoints, streaks, seeded RNG stability, food search.
2. `tools/verify_swift.py` passes over `ios/`: balanced delimiters, no duplicate top-level
   type declarations, no merge markers, every SPEC contract symbol declared exactly once,
   no `SPEC-GAP`/`TODO` left at final.
3. Oracle review: cross-file references resolve; SwiftUI files only reference types that
   exist; Info.plist has camera/photo/health usage strings; entitlements include HealthKit.

## 10. Bucket work orders

- **A — MetabolicCore** (Sources + Tests): §4 in full, exercise library ≥22 with authored
  keyframes, seed food DB ≥60, additive table ≥40, all engines + XCTest suite.
- **B — Shell**: MTTheme + DS components, MetabolicApp entry, RootTabView, AppState,
  SwiftData models + container, Dashboard (all 7 widgets + edit mode), placeholder-free.
- **C — Nutrition**: diary, add-food flows (search/manual/photo), water, OpenFoodFactsClient,
  ClaudeVisionClient, APIKeyStore, UsageMeter.
- **D — Training + Onboarding**: ExerciseAnimationView (Canvas skeleton renderer),
  today plan, plan browser, exercise detail, session player, onboarding flow, profile editor.
- **E — Scanner + Paywall + Health + Settings**: BarcodeScannerView, scan result + history +
  alternatives, SubscriptionManager + Paywall + Products.storekit, FeatureGate, HealthKitService,
  Settings, CSV export.
