import SwiftUI
import SwiftData
import Charts
import MetabolicCore

// MARK: - CalorieRingWidget

/// Hero card: big ring showing calories remaining, plus Eaten / Burned / Target mini rows.
struct CalorieRingWidget: View {
    @Environment(AppState.self) private var appState
    @Query private var todayFood: [FoodEntry]
    @Query private var todayWorkouts: [WorkoutLog]

    init() {
        let (start, end) = Self.todayBounds()
        _todayFood = Query(filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end })
        _todayWorkouts = Query(filter: #Predicate<WorkoutLog> { $0.date >= start && $0.date < end })
    }

    private var eaten: Int { Int(todayFood.reduce(0) { $0 + $1.calories }) }
    private var burned: Int { todayWorkouts.reduce(0) { $0 + $1.calories } }
    private var target: Int { appState.targets.calories }
    private var remaining: Int { max(target - eaten, 0) }
    private var isOver: Bool { eaten > target }
    private var progress: Double { target > 0 ? Double(eaten) / Double(target) : 0 }

    var body: some View {
        MTCard {
            HStack(spacing: 24) {
                ZStack {
                    MTRing(progress: progress, lineWidth: 14, tint: isOver ? MTTheme.danger : MTTheme.volt)
                        .frame(width: 148, height: 148)
                    VStack(spacing: 2) {
                        Text("\(remaining)")
                            .font(MTTheme.numberFont(size: 34))
                            .foregroundStyle(MTTheme.textPrimary)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text("kcal left")
                            .font(.system(size: 13))
                            .foregroundStyle(MTTheme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    calorieRow(color: MTTheme.volt, label: "Eaten", value: eaten)
                    calorieRow(color: MTTheme.success, label: "Burned", value: burned)
                    calorieRow(color: MTTheme.textTertiary, label: "Target", value: target)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func calorieRow(color: Color, label: String, value: Int) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(MTTheme.textSecondary)
                Text("\(value)")
                    .font(MTTheme.numberFont(size: 17))
                    .foregroundStyle(MTTheme.textPrimary)
            }
        }
    }

    private static func todayBounds() -> (Date, Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }
}

// MARK: - MacrosWidget

/// Protein / Carbs / Fat columns, each with its own progress bar against today's targets.
struct MacrosWidget: View {
    @Environment(AppState.self) private var appState
    @Query private var todayFood: [FoodEntry]

    init() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        _todayFood = Query(filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end })
    }

    private var protein: Int { Int(todayFood.reduce(0) { $0 + $1.proteinG }) }
    private var carbs: Int { Int(todayFood.reduce(0) { $0 + $1.carbsG }) }
    private var fat: Int { Int(todayFood.reduce(0) { $0 + $1.fatG }) }

    var body: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("MACROS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)

                HStack(alignment: .top, spacing: 16) {
                    macroColumn(title: "Protein", value: protein, target: appState.targets.proteinG, tint: MTTheme.protein)
                    macroColumn(title: "Carbs", value: carbs, target: appState.targets.carbsG, tint: MTTheme.carbs)
                    macroColumn(title: "Fat", value: fat, target: appState.targets.fatG, tint: MTTheme.fat)
                }
            }
        }
    }

    private func macroColumn(title: String, value: Int, target: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(MTTheme.textSecondary)
            Text("\(value) / \(target) g")
                .font(MTTheme.numberFont(size: 17))
                .foregroundStyle(MTTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            MTProgressBar(progress: target > 0 ? Double(value) / Double(target) : 0, tint: tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - WaterWidget

/// Animated water tracker with a quick +250ml log button.
struct WaterWidget: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var todayWater: [WaterEntry]

    init() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        _todayWater = Query(filter: #Predicate<WaterEntry> { $0.date >= start && $0.date < end })
    }

    private var totalML: Int { todayWater.reduce(0) { $0 + $1.amountML } }
    private var targetML: Int { appState.targets.waterML }
    private var progress: Double { targetML > 0 ? Double(totalML) / Double(targetML) : 0 }

    private var litersText: String {
        "\(Units.waterAmountString(ml: totalML, system: appState.unitSystem)) / \(Units.waterGoalString(ml: targetML, system: appState.unitSystem))"
    }

    /// A ~one-glass quick add in the user's units.
    private var quickAdd: (label: String, ml: Int) {
        switch appState.unitSystem {
        case .metric: return ("250 ml", 250)
        case .imperial: return ("8 oz", 237)
        }
    }

    var body: some View {
        MTCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(MTTheme.water.opacity(0.15)).frame(width: 48, height: 48)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(MTTheme.water)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Water")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                    Text(litersText)
                        .font(MTTheme.numberFont(size: 17))
                        .foregroundStyle(MTTheme.textPrimary)
                    MTProgressBar(progress: progress, tint: MTTheme.water)
                }

                Spacer(minLength: 8)

                Button {
                    Haptics.success()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        modelContext.insert(WaterEntry(date: .now, amountML: quickAdd.ml))
                    }
                } label: {
                    Text("+\(quickAdd.label)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(MTTheme.volt)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - TodayWorkoutWidget

/// Today's generated plan, or a rest-day treatment when the split calls for recovery.
struct TodayWorkoutWidget: View {
    @Environment(AppState.self) private var appState

    private var plan: WorkoutPlan {
        WorkoutPlanGenerator.plan(for: appState.profile, date: .now, calendar: .current)
    }

    var body: some View {
        MTCard {
            if plan.focus == .rest {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(MTTheme.voltDim).frame(width: 56, height: 56)
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(MTTheme.volt)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest & Recover")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(MTTheme.textPrimary)
                        Text("Recovery is training too.")
                            .font(.system(size: 13))
                            .foregroundStyle(MTTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.focus.displayName.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(MTTheme.textTertiary)
                            Text(plan.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(MTTheme.textPrimary)
                        }
                        Spacer(minLength: 0)
                        Button {
                            Haptics.tap()
                            appState.selectedTab = .training
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.black)
                                .frame(width: 44, height: 44)
                                .background(MTTheme.volt)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 8) {
                        MTChip(text: "\(plan.items.count) exercises", systemImage: "list.bullet")
                        MTChip(text: "~\(plan.estimatedMinutes) min", systemImage: "clock")
                        MTChip(
                            text: "~\(plan.estimatedCalories(weightKg: appState.profile.weightKg)) kcal",
                            systemImage: "flame"
                        )
                    }
                }
            }
        }
    }
}

// MARK: - StreakWidget

/// Consecutive logging streak with a last-7-days dot row.
struct StreakWidget: View {
    @Query(sort: \FoodEntry.date) private var allFood: [FoodEntry]

    private var loggedDays: Set<Date> {
        let calendar = Calendar.current
        return Set(allFood.map { calendar.startOfDay(for: $0.date) })
    }

    private var streak: Int {
        StreakCalculator.currentStreak(
            loggedDays: loggedDays, today: Calendar.current.startOfDay(for: .now), calendar: .current
        )
    }

    private var last7Days: [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return false }
            return loggedDays.contains(day)
        }
    }

    var body: some View {
        MTCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(MTTheme.voltDim).frame(width: 56, height: 56)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("\(streak) day streak")
                        .font(MTTheme.numberFont(size: 22))
                        .foregroundStyle(MTTheme.textPrimary)

                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { index in
                            Circle()
                                .fill(last7Days[index] ? MTTheme.volt : MTTheme.surface2)
                                .frame(width: 10, height: 10)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - WeightTrendWidget

/// 14-entry weight sparkline with a gradient area fill and a trend delta chip.
struct WeightTrendWidget: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \WeightEntry.date, order: .forward) private var allWeights: [WeightEntry]

    private var recentWeights: [WeightEntry] { Array(allWeights.suffix(14)) }
    private var currentWeight: Double? { recentWeights.last?.weightKg }

    private var delta: Double? {
        guard recentWeights.count >= 2,
              let first = recentWeights.first?.weightKg,
              let last = recentWeights.last?.weightKg else { return nil }
        return last - first
    }

    var body: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("WEIGHT")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MTTheme.textTertiary)
                    Spacer()
                    if let delta {
                        deltaChip(delta)
                    }
                }

                Text(currentWeight.map { Units.weightString(kg: $0, system: appState.unitSystem) } ?? "—")
                    .font(MTTheme.numberFont(size: 24))
                    .foregroundStyle(MTTheme.textPrimary)

                if recentWeights.count >= 2 {
                    Chart(recentWeights) { entry in
                        AreaMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weightKg)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MTTheme.volt.opacity(0.35), MTTheme.volt.opacity(0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weightKg)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(MTTheme.volt)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 2)) { _ in
                            AxisValueLabel()
                                .font(.system(size: 10))
                                .foregroundStyle(MTTheme.textTertiary)
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: 80)
                } else {
                    Text("Log your weight to see trends.")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                        .frame(height: 80, alignment: .center)
                }
            }
        }
    }

    private func deltaChip(_ delta: Double) -> some View {
        let good = trendIsGood(delta: delta)
        let symbol = delta <= 0 ? "arrow.down" : "arrow.up"
        let color = good ? MTTheme.success : MTTheme.textSecondary
        return HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 10, weight: .bold))
            Text(Units.weightString(kg: abs(delta), system: appState.unitSystem)).font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func trendIsGood(delta: Double) -> Bool {
        switch appState.profile.goal {
        case .loseFat: return delta <= 0
        case .gainMuscle: return delta >= 0
        case .maintain, .improveEndurance, .improveMobility: return abs(delta) < 0.5
        }
    }
}

// MARK: - ScanShortcutWidget

/// Compact shortcut into the Scan tab.
struct ScanShortcutWidget: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        MTCard {
            Button {
                Haptics.tap()
                appState.selectedTab = .scan
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MTTheme.voltDim)
                            .frame(width: 48, height: 48)
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(MTTheme.volt)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan a product")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MTTheme.textPrimary)
                        Text("Health score in seconds")
                            .font(.system(size: 13))
                            .foregroundStyle(MTTheme.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MTTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Widgets") {
    ScrollView {
        VStack(spacing: 12) {
            CalorieRingWidget()
            MacrosWidget()
            WaterWidget()
            TodayWorkoutWidget()
            StreakWidget()
            WeightTrendWidget()
            ScanShortcutWidget()
        }
        .padding(20)
    }
    .background(MTTheme.bg)
    .environment(AppState())
    .modelContainer(
        for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
        inMemory: true
    )
}
