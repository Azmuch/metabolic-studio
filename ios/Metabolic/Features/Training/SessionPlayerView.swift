import SwiftUI
import SwiftData
import MetabolicCore

/// Immersive full-screen set/rep/rest player. Walks through every item in the plan one set at a
/// time, then saves a `WorkoutLog` (+ HealthKit) on finish.
struct SessionPlayerView: View {
    let plan: WorkoutPlan

    @Environment(AppState.self) private var appState
    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var itemIndex = 0
    @State private var currentSet = 1
    @State private var phase: SessionPhase = .ready
    @State private var completedExerciseIDs: [String] = []

    /// Optional per-set load, remembered per-exercise for the life of this session, plus the
    /// running Σ reps × loadKg for hypertrophy tracking (equipment-based, non-mobility, reps-kind
    /// work only — timed holds don't have a rep count to multiply against).
    @State private var loadTextByExercise: [String: String] = [:]
    @State private var volumeKg: Double = 0

    @State private var sessionStart = Date()               // re-anchored when Start Workout is tapped
    @State private var phaseEnd = Date()                    // Date-anchor for timed work / rest countdowns
    @State private var pausedAt: Date?                      // non-nil while paused
    @State private var pausedAccumulator: TimeInterval = 0  // total paused time, excluded from elapsed math
    @State private var remainingAtPause: TimeInterval = 0   // countdown remainder captured on pause

    @State private var showEndConfirm = false
    @State private var isSaving = false

    init(plan: WorkoutPlan) {
        self.plan = plan
    }

    var body: some View {
        ZStack {
            MTTheme.bg.ignoresSafeArea()

            if plan.items.isEmpty {
                emptyPlanContent
            } else {
                VStack(spacing: 24) {
                    topBar

                    if phase == .finished {
                        Spacer(minLength: 0)
                        finishedContent
                        Spacer(minLength: 0)
                    } else if phase == .ready {
                        Spacer(minLength: 0)
                        readyContent
                        Spacer(minLength: 0)
                    } else {
                        Spacer(minLength: 0)
                        centerSection
                        Spacer(minLength: 0)
                        Group {
                            switch phase {
                            case .prompting:
                                promptContent
                            case .working:
                                workContent
                            default:
                                restContent
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding(20)
            }
        }
        .task(id: taskKey) { await runPhaseWatcher() }
        .confirmationDialog("End workout?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End Workout", role: .destructive) { dismiss() }
            Button("Keep Going", role: .cancel) {}
        }
    }

    // MARK: - Derived state

    private var currentItem: WorkoutItem {
        let safeIndex = min(max(itemIndex, 0), plan.items.count - 1)
        return plan.items[safeIndex]
    }

    private var isLastSetOfLastItem: Bool {
        itemIndex == plan.items.count - 1 && currentSet == currentItem.sets
    }

    private var nextPreviewItem: WorkoutItem? {
        if currentSet < currentItem.sets { return currentItem }
        let nextIndex = itemIndex + 1
        return plan.items.indices.contains(nextIndex) ? plan.items[nextIndex] : nil
    }

    private var taskKey: String { "\(phase)-\(itemIndex)-\(currentSet)" }

    private var isMobility: Bool { currentItem.exercise.category == .mobility }

    /// Equipment-based, non-mobility work is where a load is worth tracking.
    private var showsLoadField: Bool {
        !isMobility && !currentItem.exercise.equipment.contains(.none)
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    Haptics.tap()
                    if phase == .ready {
                        dismiss()
                    } else {
                        showEndConfirm = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(MTTheme.surface2)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                TimelineView(.periodic(from: sessionStart, by: 1)) { timeline in
                    Text(elapsedString(now: timeline.date))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MTTheme.textSecondary)
                }
            }

            if phase != .finished && phase != .ready {
                progressSegments
            }
        }
    }

    private var progressSegments: some View {
        HStack(spacing: 4) {
            ForEach(Array(plan.items.enumerated()), id: \.offset) { index, _ in
                Capsule()
                    .fill(segmentColor(for: index))
                    .frame(height: 4)
            }
        }
    }

    private func segmentColor(for index: Int) -> Color {
        if index < itemIndex { return MTTheme.volt }
        if index == itemIndex { return MTTheme.volt.opacity(0.35) }
        return MTTheme.surface2
    }

    private func elapsedString(now: Date) -> String {
        let total = max(Int(activeElapsed(now: now)), 0)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// Wall time since Start Workout was tapped, excluding paused stretches.
    /// Zero until the workout has actually started.
    private func activeElapsed(now: Date) -> TimeInterval {
        guard phase != .ready else { return 0 }
        let pausedSoFar = pausedAccumulator + (pausedAt.map { now.timeIntervalSince($0) } ?? 0)
        return now.timeIntervalSince(sessionStart) - pausedSoFar
    }

    // MARK: - Center section

    private var centerSection: some View {
        VStack(spacing: 16) {
            AnatomyHeroView(exercise: currentItem.exercise)
                .frame(width: 300, height: 300)
            VStack(spacing: 6) {
                Text("SET \(currentSet) OF \(currentItem.sets)")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                Text(currentItem.exercise.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .multilineTextAlignment(.center)
                if isMobility {
                    MTChip(text: "Mobility", systemImage: "leaf.fill")
                }
            }
        }
    }

    // MARK: - Ready state & begin-set prompt

    /// Pre-start overview: nothing runs until "Start Workout" is tapped.
    private var readyContent: some View {
        VStack(spacing: 24) {
            AnatomyHeroView(exercise: currentItem.exercise)
                .frame(width: 300, height: 300)
            VStack(spacing: 8) {
                Text(plan.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("\(plan.items.count) exercises · ~\(plan.estimatedMinutes) min")
                    .font(.system(size: 15))
                    .foregroundStyle(MTTheme.textSecondary)
            }
            MTPrimaryButton(title: "Start Workout", systemImage: "play.fill") {
                startWorkout()
            }
        }
    }

    /// Shown before every work phase — reps counting / timed countdowns only start
    /// once "Begin Set" is tapped.
    private var promptContent: some View {
        VStack(spacing: 20) {
            Text("SET \(currentSet) OF \(currentItem.sets) — READY?")
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textSecondary)
            MTPrimaryButton(title: "Begin Set", systemImage: "play.fill") {
                beginSet()
            }
        }
    }

    /// Circular pause/resume toggle shown during timed work and rest countdowns.
    private var pauseButton: some View {
        Button {
            togglePause()
        } label: {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
                .frame(width: 52, height: 52)
                .background(MTTheme.surface2)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Work phase

    @ViewBuilder
    private var workContent: some View {
        switch currentItem.kind {
        case .reps(let n):
            VStack(spacing: 20) {
                Text("\(n) reps")
                    .font(MTTheme.numberFont(size: 40))
                    .foregroundStyle(MTTheme.textPrimary)
                if showsLoadField {
                    loadField
                }
                MTPrimaryButton(title: "Complete Set", systemImage: "checkmark") {
                    completeSet()
                }
            }
        case .timed:
            TimelineView(.animation) { timeline in
                let remaining = phaseRemaining(now: timeline.date)
                VStack(spacing: 16) {
                    ZStack {
                        MTRing(progress: workProgress(remaining: remaining), lineWidth: 12)
                            .frame(width: 160, height: 160)
                        Text("\(Int(remaining.rounded()))")
                            .font(MTTheme.numberFont(size: 44))
                            .foregroundStyle(MTTheme.textPrimary)
                    }
                    pauseButton
                }
            }
        }
    }

    private var loadField: some View {
        HStack(spacing: 10) {
            Text("Load")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MTTheme.textSecondary)
            TextField("0", text: loadTextBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(MTTheme.textPrimary)
                .frame(width: 72)
                .padding(.vertical, 8)
                .background(MTTheme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
            Text(unitLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MTTheme.textTertiary)
        }
    }

    private var loadTextBinding: Binding<String> {
        Binding(
            get: { loadTextByExercise[currentItem.exercise.id] ?? "" },
            set: { loadTextByExercise[currentItem.exercise.id] = $0 }
        )
    }

    private var unitLabel: String {
        appState.unitSystem == .imperial ? "lb" : "kg"
    }

    /// Current load field's value converted to kg, or 0 if empty/unparsable.
    private var currentLoadKg: Double {
        guard let text = loadTextByExercise[currentItem.exercise.id], let value = Double(text), value > 0 else {
            return 0
        }
        return appState.unitSystem == .imperial ? Units.kg(fromPounds: value) : value
    }

    /// Seconds left on the current countdown (timed work or rest). Anchored on `phaseEnd`;
    /// while paused it holds steady at `remainingAtPause`.
    private func phaseRemaining(now: Date) -> Double {
        if pausedAt != nil { return remainingAtPause }
        return max(phaseEnd.timeIntervalSince(now), 0)
    }

    private func workProgress(remaining: Double) -> Double {
        guard case .timed(let seconds) = currentItem.kind, seconds > 0 else { return 0 }
        return min(max(1 - remaining / Double(seconds), 0), 1)
    }

    private var isPaused: Bool { pausedAt != nil }

    /// Pause: capture the countdown remainder. Resume: fold the paused stretch into the
    /// session accumulator and re-anchor the countdown (`phaseEnd = .now + remainingAtPause`).
    private func togglePause() {
        Haptics.tap()
        if let pausedAt {
            pausedAccumulator += Date().timeIntervalSince(pausedAt)
            self.pausedAt = nil
            phaseEnd = Date().addingTimeInterval(remainingAtPause)
        } else {
            remainingAtPause = max(phaseEnd.timeIntervalSince(Date()), 0)
            pausedAt = Date()
        }
    }

    // MARK: - Rest phase

    private var restContent: some View {
        TimelineView(.animation) { timeline in
            let remaining = phaseRemaining(now: timeline.date)
            VStack(spacing: 20) {
                Text("REST")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)

                ZStack {
                    MTRing(progress: restProgress(remaining: remaining), lineWidth: 12)
                        .frame(width: 160, height: 160)
                    Text("\(Int(remaining.rounded()))")
                        .font(MTTheme.numberFont(size: 44))
                        .foregroundStyle(MTTheme.textPrimary)
                }

                HStack(spacing: 12) {
                    pauseButton
                    MTSecondaryButton(title: "Skip", systemImage: "forward.fill") {
                        Haptics.tap()
                        advanceAfterRest()
                    }
                }

                if let nextItem = nextPreviewItem {
                    nextUpPreview(nextItem)
                }
            }
        }
    }

    private func restProgress(remaining: Double) -> Double {
        let total = Double(currentItem.restSeconds)
        guard total > 0 else { return 1 }
        return min(max(1 - remaining / total, 0), 1)
    }

    private func nextUpPreview(_ item: WorkoutItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                    .fill(MTTheme.voltDim)
                ExerciseAnimationView(exercise: item.exercise)
                    .padding(8)
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT UP")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                Text(item.exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(MTTheme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
    }

    // MARK: - Finished

    private var finishedContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(MTTheme.volt)

            Text("Workout complete")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(MTTheme.textPrimary)

            TimelineView(.periodic(from: sessionStart, by: 1)) { timeline in
                statsGrid(minutes: elapsedMinutes(now: timeline.date))
            }

            if volumeKg > 0 {
                MTChip(text: volumeSummaryText, systemImage: "scalemass.fill")
            }

            MTPrimaryButton(title: "Save & Finish", systemImage: "checkmark") {
                Task { await saveAndFinish() }
            }
            .disabled(isSaving)
        }
    }

    private func elapsedMinutes(now: Date) -> Int {
        max(Int(activeElapsed(now: now) / 60), 0)
    }

    private func statsGrid(minutes: Int) -> some View {
        MTCard {
            HStack(spacing: 0) {
                statColumn(value: "\(minutes)", label: "Minutes")
                statColumn(value: "\(estimatedFinishCalories(minutes: minutes))", label: "kcal")
                statColumn(value: "\(completedExerciseIDs.count)", label: "Exercises")
            }
        }
    }

    private func statColumn(value: String, label: String) -> some View {
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

    /// "Σ 2,340 kg lifted" — converted to the user's preferred unit system.
    private var volumeSummaryText: String {
        let value = appState.unitSystem == .imperial ? Units.pounds(fromKg: volumeKg) : volumeKg
        let unit = appState.unitSystem == .imperial ? "lb" : "kg"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let numberString = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "Σ \(numberString) \(unit) lifted"
    }

    private func averageMET() -> Double {
        let completedItems = plan.items.filter { completedExerciseIDs.contains($0.id) }
        guard !completedItems.isEmpty else { return 0 }
        return completedItems.reduce(0.0) { $0 + $1.exercise.met } / Double(completedItems.count)
    }

    private func estimatedFinishCalories(minutes: Int) -> Int {
        let met = averageMET()
        guard met > 0 else { return 0 }
        let activeMinutes = Double(minutes) * 0.6
        return Int(
            CalorieBurnCalculator.kilocalories(
                met: met, weightKg: appState.profile.weightKg, minutes: activeMinutes
            ).rounded()
        )
    }

    // MARK: - Empty plan fallback

    private var emptyPlanContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(MTTheme.volt)
            Text("Nothing to play")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(MTTheme.textPrimary)
            MTSecondaryButton(title: "Close") { dismiss() }
                .padding(.horizontal, 40)
        }
        .padding(20)
    }

    // MARK: - State machine

    /// Folds any in-flight pause into the session accumulator and clears countdown pause
    /// state. Call before every phase transition so pauses never leak across phases.
    private func endPauseIfNeeded() {
        if let pausedAt {
            pausedAccumulator += Date().timeIntervalSince(pausedAt)
            self.pausedAt = nil
        }
        remainingAtPause = 0
    }

    /// "Start Workout" tapped on the ready screen — this is the moment timing begins.
    private func startWorkout() {
        Haptics.success()
        sessionStart = Date()
        pausedAccumulator = 0
        pausedAt = nil
        phase = .prompting
    }

    /// "Begin Set" tapped on the set prompt — only now does the work phase (and any
    /// timed countdown) actually start.
    private func beginSet() {
        Haptics.tap()
        endPauseIfNeeded()
        if case .timed(let seconds) = currentItem.kind {
            phaseEnd = Date().addingTimeInterval(Double(seconds))
        }
        phase = .working
    }

    private func completeSet() {
        Haptics.success()
        endPauseIfNeeded()
        if case .reps(let n) = currentItem.kind, showsLoadField {
            volumeKg += Double(n) * currentLoadKg
        }
        if currentSet == currentItem.sets, !completedExerciseIDs.contains(currentItem.id) {
            completedExerciseIDs.append(currentItem.id)
        }
        if isLastSetOfLastItem {
            phase = .finished
        } else {
            phase = .resting
            phaseEnd = Date().addingTimeInterval(Double(currentItem.restSeconds))
        }
    }

    /// Rest over (or skipped): advance set/exercise counters and land on the next
    /// begin-set prompt — work never auto-starts.
    private func advanceAfterRest() {
        endPauseIfNeeded()
        if currentSet < currentItem.sets {
            currentSet += 1
        } else {
            itemIndex += 1
            currentSet = 1
        }
        phase = .prompting
    }

    private func runPhaseWatcher() async {
        guard !plan.items.isEmpty else { return }
        switch phase {
        case .ready, .prompting, .finished:
            return
        case .working:
            guard case .timed = currentItem.kind else { return }
            while !Task.isCancelled {
                if !isPaused, phaseRemaining(now: Date()) <= 0 {
                    completeSet()
                    return
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        case .resting:
            while !Task.isCancelled {
                if !isPaused, phaseRemaining(now: Date()) <= 0 {
                    advanceAfterRest()
                    return
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    // MARK: - Save

    private func saveAndFinish() async {
        isSaving = true
        let minutes = max(Int(activeElapsed(now: Date()) / 60), 0)
        let calories = estimatedFinishCalories(minutes: minutes)
        let log = WorkoutLog(
            date: sessionStart,
            title: plan.title,
            focus: plan.focus,
            minutes: minutes,
            calories: calories,
            completedExerciseIDs: completedExerciseIDs,
            totalVolumeKg: volumeKg
        )
        modelContext.insert(log)
        await healthKit.saveWorkout(log)
        Haptics.success()
        dismiss()
    }
}

/// Where the player currently is: pre-start overview, awaiting a "Begin Set" tap,
/// doing the work, resting between sets, or done.
fileprivate enum SessionPhase {
    case ready, prompting, working, resting, finished
}

#Preview {
    Group {
        if let exercise = ExerciseLibrary.all.first {
            let item = WorkoutItem(id: exercise.id, exercise: exercise, sets: 3, kind: exercise.kind, restSeconds: 30)
            let plan = WorkoutPlan(date: .now, focus: .fullBody, title: "Full Body", items: [item], estimatedMinutes: 20)
            SessionPlayerView(plan: plan)
                .environment(AppState())
                .environment(HealthKitService())
                .modelContainer(
                    for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
                    inMemory: true
                )
        } else {
            Text("No exercises")
        }
    }
}
