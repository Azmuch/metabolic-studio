import SwiftUI
import SwiftData
import MetabolicCore

/// Simplified daily + weekly goals tracker: today's calorie/water/protein progress at a glance,
/// plus a Mon–Sun workout strip and weekly calorie-logging consistency for the current week.
struct GoalsProgressWidget: View {
    @Environment(AppState.self) private var appState
    @Query private var weekFood: [FoodEntry]
    @Query private var weekWater: [WaterEntry]
    @Query private var weekWorkouts: [WorkoutLog]

    private let weekStart: Date
    private let todayStart: Date
    private let todayEnd: Date

    init() {
        let (start, end) = Self.weekBounds()
        weekStart = start
        let calendar = Calendar.current
        let tStart = calendar.startOfDay(for: .now)
        todayStart = tStart
        todayEnd = calendar.date(byAdding: .day, value: 1, to: tStart) ?? tStart
        _weekFood = Query(filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end })
        _weekWater = Query(filter: #Predicate<WaterEntry> { $0.date >= start && $0.date < end })
        _weekWorkouts = Query(filter: #Predicate<WorkoutLog> { $0.date >= start && $0.date < end })
    }

    // MARK: - Today (filtered in-memory from the week query)

    private var todayFood: [FoodEntry] {
        weekFood.filter { $0.date >= todayStart && $0.date < todayEnd }
    }
    private var todayWater: [WaterEntry] {
        weekWater.filter { $0.date >= todayStart && $0.date < todayEnd }
    }

    private var eatenCalories: Double { todayFood.reduce(0) { $0 + $1.calories } }
    private var eatenProteinG: Double { todayFood.reduce(0) { $0 + $1.proteinG } }
    private var drankML: Double { Double(todayWater.reduce(0) { $0 + $1.amountML }) }

    // MARK: - Week

    private var dayBounds: [(Date, Date)] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            let start = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return (start, end)
        }
    }

    private var workoutDoneByDay: [Bool] {
        dayBounds.map { start, end in weekWorkouts.contains { $0.date >= start && $0.date < end } }
    }

    private var loggedDaysCount: Int {
        dayBounds.filter { start, end in weekFood.contains { $0.date >= start && $0.date < end } }.count
    }

    private var todayIndex: Int {
        let raw = Calendar.current.dateComponents([.day], from: weekStart, to: todayStart).day ?? 0
        return min(max(raw, 0), 6)
    }

    private var workoutsDoneCount: Int { workoutDoneByDay.filter { $0 }.count }

    var body: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("TODAY")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MTTheme.textTertiary)

                    HStack(spacing: 12) {
                        goalPill(
                            label: "Calories",
                            current: eatenCalories,
                            target: Double(appState.targets.calories),
                            tint: MTTheme.volt,
                            valueText: "\(Int(eatenCalories))/\(appState.targets.calories)"
                        )
                        goalPill(
                            label: "Water",
                            current: drankML,
                            target: Double(appState.targets.waterML),
                            tint: MTTheme.water,
                            valueText: "\(Units.waterAmountString(ml: Int(drankML), system: appState.unitSystem)) / \(Units.waterGoalString(ml: appState.targets.waterML, system: appState.unitSystem))"
                        )
                        goalPill(
                            label: "Protein",
                            current: eatenProteinG,
                            target: Double(appState.targets.proteinG),
                            tint: MTTheme.protein,
                            valueText: "\(Int(eatenProteinG))/\(appState.targets.proteinG)g"
                        )
                    }
                }

                Divider().overlay(MTTheme.stroke)

                VStack(alignment: .leading, spacing: 10) {
                    Text("THIS WEEK")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MTTheme.textTertiary)

                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            dayDot(index: index)
                        }
                    }

                    Text("\(workoutsDoneCount) of \(appState.profile.workoutDaysPerWeek) workouts")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("\(loggedDaysCount)/7 days logged")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                }
            }
        }
    }

    /// Small ring + label; swaps to a filled checkmark once the goal is met. No haptic feedback —
    /// this is a passive status readout, not a control.
    private func goalPill(label: String, current: Double, target: Double, tint: Color, valueText: String) -> some View {
        let progress = target > 0 ? current / target : 0
        let met = progress >= 1
        return VStack(spacing: 6) {
            Group {
                if met {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                } else {
                    MTRing(progress: progress, lineWidth: 3, tint: tint)
                }
            }
            .frame(width: 20, height: 20)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MTTheme.textSecondary)
            Text(valueText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func dayDot(index: Int) -> some View {
        let done = workoutDoneByDay[index]
        let isToday = index == todayIndex
        return VStack(spacing: 4) {
            Circle()
                .fill(done ? MTTheme.volt : MTTheme.surface2)
                .overlay(Circle().stroke(MTTheme.volt, lineWidth: isToday ? 2 : 0))
                .frame(width: 18, height: 18)
            Text(Self.weekdayLetters[index])
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isToday ? MTTheme.textPrimary : MTTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private static let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    /// Monday-start bounds `[start, end)` for the week containing today.
    private static func weekBounds() -> (Date, Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today) // Sun=1...Sat=7
        let daysFromMonday = (weekday + 5) % 7
        let start = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        return (start, end)
    }
}

#Preview("Goals Tracker") {
    ScrollView {
        GoalsProgressWidget()
            .padding(20)
    }
    .background(MTTheme.bg)
    .environment(AppState())
    .modelContainer(
        for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
        inMemory: true
    )
}
