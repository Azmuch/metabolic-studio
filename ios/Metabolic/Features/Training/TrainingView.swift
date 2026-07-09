import SwiftUI
import SwiftData
import MetabolicCore

/// Training tab root: this week's split, today's (or the selected day's) plan, and a browsable
/// exercise library gated behind Plus.
struct TrainingView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @Query private var weekLogs: [WorkoutLog]

    @State private var selectedIndex: Int
    @State private var showSessionPlayer = false
    @State private var showPaywall = false

    private let calendar = Calendar.current
    private static let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    init() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today) // Gregorian: 1 = Sunday
        let daysSinceMonday = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -daysSinceMonday, to: today) ?? today
        let nextMonday = cal.date(byAdding: .day, value: 7, to: monday) ?? monday
        _selectedIndex = State(initialValue: daysSinceMonday)
        _weekLogs = Query(filter: #Predicate<WorkoutLog> { $0.date >= monday && $0.date < nextMonday })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    weekStrip

                    if plan.focus == .rest {
                        restCard
                    } else {
                        planCard
                    }

                    if isSelectedToday && !plan.items.isEmpty {
                        MTPrimaryButton(title: "Start Workout", systemImage: "play.fill") {
                            showSessionPlayer = true
                        }
                    }

                    weekSummaryStrip
                    librarySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(MTTheme.bg)
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showSessionPlayer) {
                SessionPlayerView(plan: plan)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Derived data

    private var weekFocuses: [DayFocus] {
        WorkoutPlanGenerator.weeklySplit(for: appState.profile)
    }

    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) ?? today
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: monday) ?? monday }
    }

    private var selectedDate: Date {
        weekDates[min(max(selectedIndex, 0), weekDates.count - 1)]
    }

    private var isSelectedToday: Bool {
        calendar.isDate(selectedDate, inSameDayAs: .now)
    }

    private var plan: WorkoutPlan {
        WorkoutPlanGenerator.plan(for: appState.profile, date: selectedDate, calendar: calendar)
    }

    private var splitSummary: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for focus in weekFocuses where focus != .rest {
            if !seen.contains(focus.displayName) {
                seen.insert(focus.displayName)
                result.append(focus.displayName)
            }
        }
        return result
    }

    private var libraryExercises: [Exercise] {
        ExerciseLibrary.all
    }

    private var isLibraryGated: Bool {
        !FeatureGate.allows(.fullExerciseLibrary, tier: subscriptionManager.tier)
    }

    private var visibleLibraryExercises: [Exercise] {
        isLibraryGated ? Array(libraryExercises.prefix(6)) : libraryExercises
    }

    private var lockedLibraryCount: Int {
        max(libraryExercises.count - 6, 0)
    }

    private var weekWorkoutCount: Int { weekLogs.count }
    private var weekMinutes: Int { weekLogs.reduce(0) { $0 + $1.minutes } }
    private var weekCalories: Int { weekLogs.reduce(0) { $0 + $1.calories } }

    // MARK: - Header & week strip

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Training")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(MTTheme.textPrimary)

            if !splitSummary.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(splitSummary, id: \.self) { name in
                            MTChip(text: name)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.top, 12)
    }

    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                dayChip(index: index)
            }
        }
    }

    private func dayChip(index: Int) -> some View {
        let date = weekDates[index]
        let focus = weekFocuses.indices.contains(index) ? weekFocuses[index] : .rest
        let isToday = calendar.isDate(date, inSameDayAs: .now)
        let isSelected = index == selectedIndex

        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                selectedIndex = index
            }
        } label: {
            VStack(spacing: 6) {
                Text(Self.weekdayLetters[index])
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? MTTheme.textPrimary : MTTheme.textSecondary)
                Circle()
                    .fill(focus == .rest ? MTTheme.textTertiary : MTTheme.volt)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? MTTheme.voltDim : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                    .stroke(isToday ? MTTheme.volt : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Plan card

    private var restCard: some View {
        MTCard {
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
                    Text("No workout scheduled — let your muscles rebuild.")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var planCard: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.focus.displayName.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MTTheme.textTertiary)
                    Text(plan.title)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(MTTheme.textPrimary)
                }

                HStack(spacing: 8) {
                    MTChip(text: "\(plan.items.count) exercises", systemImage: "list.bullet")
                    MTChip(text: "~\(plan.estimatedMinutes) min", systemImage: "clock")
                    MTChip(
                        text: "~\(plan.estimatedCalories(weightKg: appState.profile.weightKg)) kcal",
                        systemImage: "flame"
                    )
                }

                VStack(spacing: 12) {
                    ForEach(plan.items) { item in
                        NavigationLink {
                            ExerciseDetailView(exercise: item.exercise)
                        } label: {
                            exerciseRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func exerciseRow(_ item: WorkoutItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                    .fill(MTTheme.voltDim)
                ExerciseAnimationView(exercise: item.exercise)
                    .padding(6)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                Text("\(item.sets) × \(prescriptionText(item.kind)) · \(item.restSeconds)s rest")
                    .font(.system(size: 12))
                    .foregroundStyle(MTTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MTTheme.textTertiary)
        }
    }

    private func prescriptionText(_ kind: ExerciseKind) -> String {
        switch kind {
        case .reps(let n): return "\(n) reps"
        case .timed(let seconds): return "\(seconds)s"
        }
    }

    // MARK: - This-week summary

    private var weekSummaryStrip: some View {
        MTCard {
            HStack(spacing: 0) {
                summaryColumn(value: "\(weekWorkoutCount)", label: "Workouts")
                summaryColumn(value: "\(weekMinutes)", label: "Minutes")
                summaryColumn(value: "\(weekCalories)", label: "kcal")
            }
        }
    }

    private func summaryColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(MTTheme.numberFont(size: 22))
                .foregroundStyle(MTTheme.textPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(MTTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Exercise library

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXERCISE LIBRARY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textTertiary)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(visibleLibraryExercises) { exercise in
                        libraryCard(exercise)
                    }
                    if isLibraryGated && lockedLibraryCount > 0 {
                        lockedLibraryCard
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func libraryCard(_ exercise: Exercise) -> some View {
        NavigationLink {
            ExerciseDetailView(exercise: exercise)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                        .fill(MTTheme.voltDim)
                    ExerciseAnimationView(exercise: exercise)
                        .padding(8)
                }
                .frame(width: 128, height: 100)

                Text(exercise.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .lineLimit(1)

                if let primary = exercise.muscleGroups.first {
                    MTChip(text: primary.displayName)
                }
            }
            .padding(12)
            .frame(width: 152, alignment: .leading)
            .background(MTTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                    .stroke(MTTheme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var lockedLibraryCard: some View {
        Button {
            Haptics.tap()
            showPaywall = true
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(MTTheme.voltDim).frame(width: 48, height: 48)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                }
                Text("+\(lockedLibraryCount) more")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                MTChip(text: "Plus", systemImage: "lock.fill")
            }
            .padding(12)
            .frame(width: 152, height: 168)
            .background(MTTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                    .stroke(MTTheme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TrainingView()
        .environment(AppState())
        .environment(SubscriptionManager())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
            inMemory: true
        )
}
