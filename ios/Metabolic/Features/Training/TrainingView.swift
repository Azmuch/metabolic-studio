import SwiftUI
import SwiftData
import MetabolicCore

/// Training tab root: this week's split, today's (or the selected day's) plan, and a browsable
/// exercise library gated behind Plus.
struct TrainingView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.modelContext) private var modelContext

    @Query private var weekLogs: [WorkoutLog]
    @Query private var lastWeekLogs: [WorkoutLog]
    @Query(sort: \CustomWorkout.createdAt, order: .reverse) private var customWorkouts: [CustomWorkout]

    @State private var selectedIndex: Int
    @State private var showSessionPlayer = false
    @State private var showPaywall = false
    @State private var showBuilder = false
    @State private var editingWorkout: CustomWorkout?
    @State private var runningCustom: RunnablePlan?

    private let calendar = Calendar.current
    private static let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    init() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today) // Gregorian: 1 = Sunday
        let daysSinceMonday = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -daysSinceMonday, to: today) ?? today
        let nextMonday = cal.date(byAdding: .day, value: 7, to: monday) ?? monday
        let lastMonday = cal.date(byAdding: .day, value: -7, to: monday) ?? monday
        _selectedIndex = State(initialValue: daysSinceMonday)
        _weekLogs = Query(filter: #Predicate<WorkoutLog> { $0.date >= monday && $0.date < nextMonday })
        _lastWeekLogs = Query(filter: #Predicate<WorkoutLog> { $0.date >= lastMonday && $0.date < monday })
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

                    weekSummaryStrip
                    hypertrophyCard
                    myWorkoutsSection
                    coachingSection
                    librarySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(MTBackground())
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showSessionPlayer) {
                SessionPlayerView(plan: plan)
            }
            .fullScreenCover(item: $runningCustom) { runnable in
                SessionPlayerView(plan: runnable.plan)
            }
            .sheet(isPresented: $showBuilder) {
                WorkoutBuilderView()
            }
            .sheet(item: $editingWorkout) { workout in
                WorkoutBuilderView(editing: workout)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - My workouts

    private var myWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MY WORKOUTS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textTertiary)

            if customWorkouts.isEmpty {
                Text("Build your own session from any exercises in the library.")
                    .font(.system(size: 13))
                    .foregroundStyle(MTTheme.textSecondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(customWorkouts) { workout in
                        customWorkoutCard(workout)
                    }
                }
            }

            Button {
                Haptics.tap()
                showBuilder = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Workout")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(MTTheme.volt, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func customWorkoutCard(_ workout: CustomWorkout) -> some View {
        MTCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("\(workout.items.count) exercises · ~\(workout.estimatedMinutes) min")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Spacer(minLength: 0)
                Button {
                    Haptics.tap()
                    editingWorkout = workout
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MTTheme.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(MTTheme.surface2, in: Circle())
                }
                .buttonStyle(.plain)
                Button {
                    Haptics.tap()
                    runningCustom = RunnablePlan(plan: workout.plan())
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .frame(width: 44, height: 44)
                        .background(MTTheme.volt, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(workout.items.isEmpty)
            }
            .contextMenu {
                Button(role: .destructive) {
                    modelContext.delete(workout)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
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

                VStack(spacing: 6) {
                    MTPrimaryButton(title: "Start Workout", systemImage: "play.fill",
                                    isEnabled: isSelectedToday && !plan.items.isEmpty) {
                        showSessionPlayer = true
                    }
                    if !isSelectedToday {
                        Text("Only today's workout can be started right now.")
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textTertiary)
                    }
                }

                VStack(spacing: 16) {
                    if hasMobilityBlocks {
                        if !mobilitySplit.warmup.isEmpty {
                            exerciseSubSection(title: "WARM-UP", icon: "leaf.fill", items: mobilitySplit.warmup)
                        }
                        if !mobilitySplit.main.isEmpty {
                            exerciseSubSection(title: "WORKOUT", icon: "list.bullet", items: mobilitySplit.main)
                        }
                        if !mobilitySplit.cooldown.isEmpty {
                            exerciseSubSection(title: "COOLDOWN", icon: "leaf.fill", items: mobilitySplit.cooldown)
                        }
                    } else {
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
        }
    }

    /// Plans may bookend strength work with mobility items (`category == .mobility`, `sets == 1`)
    /// — split those out into leading "warm-up" / trailing "cooldown" blocks around the main list.
    private var mobilitySplit: (warmup: [WorkoutItem], main: [WorkoutItem], cooldown: [WorkoutItem]) {
        let items = plan.items
        let leadingCount = items.prefix { $0.exercise.category == .mobility }.count
        let trailingCount = min(
            items.reversed().prefix { $0.exercise.category == .mobility }.count,
            items.count - leadingCount
        )
        let warmup = Array(items.prefix(leadingCount))
        let cooldown = trailingCount > 0 ? Array(items.suffix(trailingCount)) : []
        let mainRange = leadingCount..<(items.count - trailingCount)
        let main = mainRange.isEmpty ? [] : Array(items[mainRange])
        return (warmup, main, cooldown)
    }

    private var hasMobilityBlocks: Bool {
        !mobilitySplit.warmup.isEmpty || !mobilitySplit.cooldown.isEmpty
    }

    private func exerciseSubSection(title: String, icon: String, items: [WorkoutItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MTTheme.textTertiary)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
            }
            VStack(spacing: 12) {
                ForEach(items) { item in
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

    // MARK: - Hypertrophy

    private var weekVolumeKg: Double { weekLogs.reduce(0) { $0 + $1.totalVolumeKg } }
    private var lastWeekVolumeKg: Double { lastWeekLogs.reduce(0) { $0 + $1.totalVolumeKg } }

    private var volumeDeltaPercent: Double? {
        guard lastWeekVolumeKg > 0 else { return nil }
        return (weekVolumeKg - lastWeekVolumeKg) / lastWeekVolumeKg * 100
    }

    /// Sets-per-muscle-group breakdown for this week, top 5. We don't store per-exercise set
    /// counts on `WorkoutLog`, so this approximates 3 sets per completed exercise id — honest
    /// labeling ("≈ sets" / "estimated") reflects that it's a rough read, not a precise log.
    private var muscleGroupSetCounts: [(group: MuscleGroup, sets: Int)] {
        var counts: [MuscleGroup: Int] = [:]
        for log in weekLogs {
            for exerciseID in log.completedExerciseIDs {
                guard let exercise = ExerciseLibrary.exercise(id: exerciseID) else { continue }
                for group in exercise.muscleGroups {
                    counts[group, default: 0] += 3
                }
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (group: $0.key, sets: $0.value) }
    }

    private func volumeDisplay(kg: Double) -> String {
        let value = appState.unitSystem == .imperial ? Units.pounds(fromKg: kg) : kg
        let unit = appState.unitSystem == .imperial ? "lb" : "kg"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let numberString = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "Σ \(numberString) \(unit)"
    }

    private func deltaChipText(_ percent: Double) -> String {
        let sign = percent >= 0 ? "+" : ""
        return "\(sign)\(Int(percent.rounded()))% vs last week"
    }

    private var hypertrophyCard: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("HYPERTROPHY")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MTTheme.textTertiary)
                    Spacer()
                    if let delta = volumeDeltaPercent {
                        MTChip(
                            text: deltaChipText(delta),
                            systemImage: delta >= 0 ? "arrow.up.right" : "arrow.down.right"
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(volumeDisplay(kg: weekVolumeKg))
                        .font(MTTheme.numberFont(size: 24))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("Total volume lifted this week")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                }

                if muscleGroupSetCounts.isEmpty {
                    Text("Log a load during your next equipment set to see your estimated volume breakdown.")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ESTIMATED SETS PER MUSCLE GROUP")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.0)
                            .foregroundStyle(MTTheme.textTertiary)
                        VStack(spacing: 10) {
                            ForEach(muscleGroupSetCounts, id: \.group) { entry in
                                muscleGroupRow(entry)
                            }
                        }
                    }
                }
            }
        }
    }

    private func muscleGroupRow(_ entry: (group: MuscleGroup, sets: Int)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.group.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                Spacer()
                Text("≈ \(entry.sets) sets")
                    .font(.system(size: 12))
                    .foregroundStyle(MTTheme.textSecondary)
            }
            MTProgressBar(progress: min(Double(entry.sets) / 10, 1), tint: MTTheme.volt)
        }
    }

    // MARK: - Coaching

    private var coachingSection: some View {
        NavigationLink {
            CoachingView()
        } label: {
            MTCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(MTTheme.voltDim).frame(width: 48, height: 48)
                        Image(systemName: "video.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(MTTheme.volt)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Coaching")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(MTTheme.textPrimary)
                        Text("Sessions with real trainers")
                            .font(.system(size: 13))
                            .foregroundStyle(MTTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MTTheme.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise library

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EXERCISE LIBRARY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                Spacer()
                NavigationLink {
                    ExerciseLibraryView()
                } label: {
                    Text("See all")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                }
                .buttonStyle(.plain)
            }

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
