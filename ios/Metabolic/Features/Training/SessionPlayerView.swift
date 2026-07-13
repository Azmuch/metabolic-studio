import SwiftUI
import SwiftData
import MetabolicCore

/// Immersive full-screen set/rep/rest player. Opens on a Ready screen; the user taps Start, then
/// confirms each set with Begin Set, works (reps or a Date-anchored timed countdown), rests, and
/// finally saves a `WorkoutLog` (+ HealthKit). Work-timed and rest countdowns are pausable, and the
/// elapsed-session clock excludes paused time.
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

    /// `sessionStart` is set the moment Start is tapped, not at view init, so time spent on the
    /// Ready screen isn't counted. `sessionPausedTotal` accumulates paused time across the whole
    /// session (excluded from elapsed math); `phasePausedTotal` + `pausedAt` drive the countdown
    /// re-anchoring within the current phase only.
    @State private var sessionStart = Date()
    @State private var sessionEnd: Date?
    @State private var phaseStart = Date()
    @State private var pausedAt: Date?
    @State private var phasePausedTotal: TimeInterval = 0
    @State private var sessionPausedTotal: TimeInterval = 0

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

                    switch phase {
                    case .ready:
                        readyContent
                    case .finished:
                        Spacer(minLength: 0)
                        finishedContent
                        Spacer(minLength: 0)
                    case .setReady, .working, .resting:
                        Spacer(minLength: 0)
                        centerSection
                        Spacer(minLength: 0)
                        activePhaseContent
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

    @ViewBuilder
    private var activePhaseContent: some View {
        switch phase {
        case .setReady: beginSetContent
        case .working: workContent
        case .resting: restContent
        default: EmptyView()
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

    private var isPaused: Bool { pausedAt != nil }

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

                if phase != .ready {
                    TimelineView(.periodic(from: sessionStart, by: 1)) { timeline in
                        Text(elapsedString(now: timeline.date))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(MTTheme.textSecondary)
                    }
                }
            }

            if phase != .ready && phase != .finished {
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
        let total = max(Int(sessionElapsed(now: now)), 0)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// Wall-clock time since Start, minus every paused interval (including one in progress). Once
    /// the session finishes, the clock freezes at `sessionEnd`.
    private func sessionElapsed(now: Date) -> TimeInterval {
        let reference = sessionEnd ?? now
        let live = pausedAt.map { reference.timeIntervalSince($0) } ?? 0
        return max(reference.timeIntervalSince(sessionStart) - sessionPausedTotal - live, 0)
    }

    // MARK: - Ready screen

    private var readyContent: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            AnatomyHeroView(exercise: currentItem.exercise, isPlaying: true)
                .frame(width: 280, height: 280)

            VStack(spacing: 8) {
                Text(plan.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(readySubtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(MTTheme.textSecondary)
            }

            Spacer(minLength: 0)

            MTPrimaryButton(title: "Start Workout", systemImage: "play.fill") {
                startWorkout()
            }
        }
    }

    private var readySubtitle: String {
        let count = plan.items.count
        let noun = count == 1 ? "exercise" : "exercises"
        return "\(count) \(noun) · ~\(plan.estimatedMinutes) min"
    }

    // MARK: - Center section

    /// The clip loops while the user is previewing (set-ready) or performing (working) the
    /// exercise, and freezes during rest or when paused — the "non-active phase" pause rule.
    private var heroIsPlaying: Bool {
        !isPaused && (phase == .setReady || phase == .working)
    }

    private var centerSection: some View {
        VStack(spacing: 16) {
            AnatomyHeroView(exercise: currentItem.exercise, isPlaying: heroIsPlaying)
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

    // MARK: - Begin-set prompt

    private var beginSetContent: some View {
        VStack(spacing: 20) {
            Text(setTargetPreview)
                .font(MTTheme.numberFont(size: 34))
                .foregroundStyle(MTTheme.textPrimary)
            MTPrimaryButton(title: "Begin Set", systemImage: "play.fill") {
                beginSet()
            }
        }
    }

    private var setTargetPreview: String {
        switch currentItem.kind {
        case .reps(let n): return "\(n) reps"
        case .timed(let seconds): return "\(seconds)s hold"
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
                if showsLoadField {
                    loadField
                }
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

    private func workRemaining(now: Date) -> Double {
        guard case .timed(let seconds) = currentItem.kind else { return 0 }
        let elapsed = now.timeIntervalSince(phaseStart) - pausedSoFar(now: now)
        return max(Double(seconds) - elapsed, 0)
    }

    private func workProgress(remaining: Double) -> Double {
        guard case .timed(let seconds) = currentItem.kind, seconds > 0 else { return 0 }
        return min(max(1 - remaining / Double(seconds), 0), 1)
    }

    /// Paused time within the current phase, including an in-progress pause.
    private func pausedSoFar(now: Date) -> TimeInterval {
        phasePausedTotal + (pausedAt.map { now.timeIntervalSince($0) } ?? 0)
    }

    // MARK: - Pause control

    private var pauseButton: some View {
        Button {
            togglePause()
        } label: {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(width: 56, height: 56)
                .background(MTTheme.volt, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPaused ? "Resume" : "Pause")
    }

    private func togglePause() {
        Haptics.tap()
        if let pausedAt {
            let delta = Date().timeIntervalSince(pausedAt)
            phasePausedTotal += delta
            sessionPausedTotal += delta
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

                pauseButton

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
        let elapsed = now.timeIntervalSince(phaseStart) - pausedSoFar(now: now)
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

            statsGrid(minutes: elapsedMinutes(now: Date()))

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
        max(Int(sessionElapsed(now: now) / 60), 0)
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

    /// Commits any in-progress pause to the session total, then resets the phase clock.
    private func resetPhaseAnchor() {
        if let pausedAt {
            sessionPausedTotal += Date().timeIntervalSince(pausedAt)
        }
        phaseStart = Date()
        phasePausedTotal = 0
        pausedAt = nil
    }

    private func startWorkout() {
        Haptics.success()
        sessionStart = Date()
        sessionEnd = nil
        sessionPausedTotal = 0
        itemIndex = 0
        currentSet = 1
        phase = .setReady
        resetPhaseAnchor()
    }

    private func beginSet() {
        Haptics.tap()
        phase = .working
        resetPhaseAnchor()
    }

    private func completeSet() {
        Haptics.success()
        if case .reps(let n) = currentItem.kind, showsLoadField {
            volumeKg += Double(n) * currentLoadKg
        }
        if currentSet == currentItem.sets, !completedExerciseIDs.contains(currentItem.id) {
            completedExerciseIDs.append(currentItem.id)
        }
        if isLastSetOfLastItem {
            sessionEnd = Date()
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
        phase = .setReady
        resetPhaseAnchor()
    }

    private func runPhaseWatcher() async {
        guard !plan.items.isEmpty else { return }
        switch phase {
        case .ready, .setReady, .finished:
            return
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
        }
    }

    // MARK: - Save

    private func saveAndFinish() async {
        isSaving = true
        let minutes = elapsedMinutes(now: Date())
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

/// Where the player currently is: the pre-start Ready screen, waiting to begin a set, doing the
/// work, resting between sets, or done.
fileprivate enum SessionPhase {
    case ready, setReady, working, resting, finished
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
