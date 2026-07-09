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
    @State private var phase: SessionPhase = .working
    @State private var completedExerciseIDs: [String] = []

    @State private var sessionStart = Date()
    @State private var phaseStart = Date()
    @State private var pausedAt: Date?
    @State private var pausedTotal: TimeInterval = 0

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
                    } else {
                        Spacer(minLength: 0)
                        centerSection
                        Spacer(minLength: 0)
                        Group {
                            if phase == .working {
                                workContent
                            } else {
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

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    Haptics.tap()
                    showEndConfirm = true
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

            if phase != .finished {
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
        let total = max(Int(now.timeIntervalSince(sessionStart)), 0)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: - Center section

    private var centerSection: some View {
        VStack(spacing: 16) {
            ExerciseAnimationView(exercise: currentItem.exercise)
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
            }
        }
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
                MTPrimaryButton(title: "Complete Set", systemImage: "checkmark") {
                    completeSet()
                }
            }
        case .timed:
            TimelineView(.animation) { timeline in
                let remaining = workRemaining(now: timeline.date)
                VStack(spacing: 16) {
                    ZStack {
                        MTRing(progress: workProgress(remaining: remaining), lineWidth: 12)
                            .frame(width: 160, height: 160)
                        Text("\(Int(remaining.rounded()))")
                            .font(MTTheme.numberFont(size: 44))
                            .foregroundStyle(MTTheme.textPrimary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { togglePause() }
                    Text(isPaused ? "Paused — tap to resume" : "Tap to pause")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                }
            }
        }
    }

    private func workRemaining(now: Date) -> Double {
        guard case .timed(let seconds) = currentItem.kind else { return 0 }
        let pausedSoFar = pausedTotal + (pausedAt.map { now.timeIntervalSince($0) } ?? 0)
        let elapsed = now.timeIntervalSince(phaseStart) - pausedSoFar
        return max(Double(seconds) - elapsed, 0)
    }

    private func workProgress(remaining: Double) -> Double {
        guard case .timed(let seconds) = currentItem.kind, seconds > 0 else { return 0 }
        return min(max(1 - remaining / Double(seconds), 0), 1)
    }

    private var isPaused: Bool { pausedAt != nil }

    private func togglePause() {
        if let pausedAt {
            pausedTotal += Date().timeIntervalSince(pausedAt)
            self.pausedAt = nil
        } else {
            pausedAt = Date()
        }
    }

    // MARK: - Rest phase

    private var restContent: some View {
        TimelineView(.animation) { timeline in
            let remaining = restRemaining(now: timeline.date)
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

                MTSecondaryButton(title: "Skip", systemImage: "forward.fill") {
                    Haptics.tap()
                    advanceAfterRest()
                }

                if let nextItem = nextPreviewItem {
                    nextUpPreview(nextItem)
                }
            }
        }
    }

    private func restRemaining(now: Date) -> Double {
        let elapsed = now.timeIntervalSince(phaseStart)
        return max(Double(currentItem.restSeconds) - elapsed, 0)
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

            MTPrimaryButton(title: "Save & Finish", systemImage: "checkmark") {
                Task { await saveAndFinish() }
            }
            .disabled(isSaving)
        }
    }

    private func elapsedMinutes(now: Date) -> Int {
        max(Int(now.timeIntervalSince(sessionStart) / 60), 0)
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

    private func resetPhaseAnchor() {
        phaseStart = Date()
        pausedTotal = 0
        pausedAt = nil
    }

    private func completeSet() {
        Haptics.success()
        if currentSet == currentItem.sets, !completedExerciseIDs.contains(currentItem.id) {
            completedExerciseIDs.append(currentItem.id)
        }
        if isLastSetOfLastItem {
            phase = .finished
        } else {
            phase = .resting
            resetPhaseAnchor()
        }
    }

    private func advanceAfterRest() {
        if currentSet < currentItem.sets {
            currentSet += 1
        } else {
            itemIndex += 1
            currentSet = 1
        }
        phase = .working
        resetPhaseAnchor()
    }

    private func runPhaseWatcher() async {
        guard !plan.items.isEmpty else { return }
        switch phase {
        case .working:
            guard case .timed = currentItem.kind else { return }
            while !Task.isCancelled {
                if workRemaining(now: Date()) <= 0 {
                    completeSet()
                    return
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        case .resting:
            while !Task.isCancelled {
                if restRemaining(now: Date()) <= 0 {
                    advanceAfterRest()
                    return
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        case .finished:
            return
        }
    }

    // MARK: - Save

    private func saveAndFinish() async {
        isSaving = true
        let minutes = max(Int(Date().timeIntervalSince(sessionStart) / 60), 0)
        let calories = estimatedFinishCalories(minutes: minutes)
        let log = WorkoutLog(
            date: sessionStart,
            title: plan.title,
            focus: plan.focus,
            minutes: minutes,
            calories: calories,
            completedExerciseIDs: completedExerciseIDs
        )
        modelContext.insert(log)
        await healthKit.saveWorkout(log)
        Haptics.success()
        dismiss()
    }
}

/// Where the player currently is within a set: doing the work, resting between sets, or done.
fileprivate enum SessionPhase {
    case working, resting, finished
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
