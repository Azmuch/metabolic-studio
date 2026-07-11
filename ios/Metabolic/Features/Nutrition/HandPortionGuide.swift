import SwiftUI
import SwiftData
import MetabolicCore

/// Universal hand-method portion tool — no scale or database lookup needed. Estimates
/// scale with `appState.profile.sex` since hand size scales with body size. Presented as
/// a sheet from `AddFoodSheet`'s header toolbar (available on every tab).
struct HandPortionGuide: View {
    let mealType: MealType

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.dismiss) private var dismiss

    @State private var counts: [HandPortionKind: Int] = [:]

    init(mealType: MealType) {
        self.mealType = mealType
    }

    private var isFemale: Bool { appState.profile.sex == .female }

    private var totalPortions: Int { counts.values.reduce(0, +) }

    private var totalCalories: Double {
        HandPortionKind.allCases.reduce(0) { total, kind in
            total + Double(counts[kind] ?? 0) * kind.calories(isFemale: isFemale)
        }
    }
    private var totalProtein: Double {
        HandPortionKind.allCases.reduce(0) { total, kind in
            total + Double(counts[kind] ?? 0) * kind.proteinG(isFemale: isFemale)
        }
    }
    private var totalCarbs: Double {
        HandPortionKind.allCases.reduce(0) { total, kind in
            total + Double(counts[kind] ?? 0) * kind.carbsG(isFemale: isFemale)
        }
    }
    private var totalFat: Double {
        HandPortionKind.allCases.reduce(0) { total, kind in
            total + Double(counts[kind] ?? 0) * kind.fatG(isFemale: isFemale)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    explainer

                    ForEach(HandPortionKind.allCases) { kind in
                        portionRow(kind)
                    }

                    totalsCard

                    MTPrimaryButton(
                        title: "Log \(totalPortions) portion\(totalPortions == 1 ? "" : "s")",
                        systemImage: "checkmark"
                    ) {
                        logPortions()
                    }
                    .disabled(totalPortions == 0)
                    .opacity(totalPortions == 0 ? 0.4 : 1)
                }
                .padding(20)
            }
            .background(MTTheme.bg)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(MTTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Explainer

    private var explainer: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(MTTheme.voltDim).frame(width: 40, height: 40)
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(MTTheme.volt)
                    }
                    Text("Hand portions")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(MTTheme.textPrimary)
                }
                Text("Your hand scales with your body — palms for protein, fists for veggies, cupped hands for carbs, thumbs for fats.")
                    .font(.system(size: 13))
                    .foregroundStyle(MTTheme.textSecondary)
            }
        }
    }

    // MARK: - Portion rows

    private func portionRow(_ kind: HandPortionKind) -> some View {
        MTCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(MTTheme.voltDim).frame(width: 40, height: 40)
                        Image(systemName: kind.symbolName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MTTheme.volt)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kind.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(MTTheme.textPrimary)
                        Text(kind.measures)
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }

                HStack {
                    Text(kind.estimateText(isFemale: isFemale))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MTTheme.textTertiary)
                    Spacer()
                    Stepper(value: countBinding(kind), in: 0...4) {
                        Text("\(counts[kind] ?? 0)")
                            .font(MTTheme.numberFont(size: 18))
                            .foregroundStyle(MTTheme.textPrimary)
                            .frame(minWidth: 22)
                    }
                    .fixedSize()
                }
            }
        }
    }

    private func countBinding(_ kind: HandPortionKind) -> Binding<Int> {
        Binding(
            get: { counts[kind] ?? 0 },
            set: { newValue in
                Haptics.tap()
                counts[kind] = newValue
            }
        )
    }

    // MARK: - Totals

    private var totalsCard: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(totalCalories.rounded()))")
                        .font(MTTheme.numberFont(size: 30))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("kcal")
                        .font(.system(size: 14))
                        .foregroundStyle(MTTheme.textSecondary)
                    Spacer()
                    Text("\(totalPortions) portion\(totalPortions == 1 ? "" : "s")")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                MTProgressBar(
                    progress: appState.targets.calories > 0 ? totalCalories / Double(appState.targets.calories) : 0,
                    tint: MTTheme.volt
                )
                HStack(spacing: 20) {
                    macroStat("Protein", totalProtein, MTTheme.protein)
                    macroStat("Carbs", totalCarbs, MTTheme.carbs)
                    macroStat("Fat", totalFat, MTTheme.fat)
                }
            }
        }
    }

    private func macroStat(_ label: String, _ value: Double, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Circle().fill(tint).frame(width: 6, height: 6)
            Text("\(Int(value.rounded()))g")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(MTTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Logging

    private func logPortions() {
        let entry = FoodEntry(
            date: .now, mealType: mealType, name: "Hand-portion meal", brand: nil,
            calories: totalCalories, proteinG: totalProtein, carbsG: totalCarbs, fatG: totalFat,
            grams: nil, source: .manual
        )
        modelContext.insert(entry)
        Task { await healthKit.saveMeal(entry) }
        Haptics.success()
        dismiss()
    }
}

/// The four hand-method portions, with sex-scaled gram/cup + calorie estimates.
private enum HandPortionKind: CaseIterable, Identifiable, Hashable {
    case protein, vegetables, carbs, fats

    var id: Self { self }

    var title: String {
        switch self {
        case .protein: return "Palm of protein"
        case .vegetables: return "Fist of vegetables"
        case .carbs: return "Cupped hand of carbs"
        case .fats: return "Thumb of fats"
        }
    }

    var measures: String {
        switch self {
        case .protein: return "Chicken, fish, tofu, eggs — anything protein-dense."
        case .vegetables: return "Broccoli, spinach, peppers — fibrous vegetables."
        case .carbs: return "Rice, oats, potatoes — starches and grains."
        case .fats: return "Nut butter, olive oil, avocado — fats and oils."
        }
    }

    var symbolName: String {
        switch self {
        case .protein: return "hand.raised.fill"
        case .vegetables: return "hand.raised.fingers.spread.fill"
        case .carbs: return "hands.sparkles.fill"
        case .fats: return "hand.thumbsup.fill"
        }
    }

    func proteinG(isFemale: Bool) -> Double {
        switch self {
        case .protein: return isFemale ? 22 : 30
        default: return 0
        }
    }

    func carbsG(isFemale: Bool) -> Double {
        switch self {
        case .vegetables: return isFemale ? 5 : 7
        case .carbs: return isFemale ? 30 : 40
        default: return 0
        }
    }

    func fatG(isFemale: Bool) -> Double {
        switch self {
        case .fats: return isFemale ? 9 : 12
        default: return 0
        }
    }

    func calories(isFemale: Bool) -> Double {
        switch self {
        case .protein: return isFemale ? 125 : 170
        case .vegetables: return isFemale ? 25 : 35
        case .carbs: return isFemale ? 140 : 190
        case .fats: return isFemale ? 80 : 110
        }
    }

    func estimateText(isFemale: Bool) -> String {
        let kcal = Int(calories(isFemale: isFemale).rounded())
        switch self {
        case .protein:
            return "\(Int(proteinG(isFemale: isFemale)))g protein · \(kcal) kcal"
        case .vegetables:
            return "\(isFemale ? "1" : "1.5") cup · \(kcal) kcal"
        case .carbs:
            return "\(Int(carbsG(isFemale: isFemale)))g carbs · \(kcal) kcal"
        case .fats:
            return "\(Int(fatG(isFemale: isFemale)))g fat · \(kcal) kcal"
        }
    }
}

#Preview {
    HandPortionGuide(mealType: .lunch)
        .environment(AppState())
        .environment(HealthKitService())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
            inMemory: true
        )
}
