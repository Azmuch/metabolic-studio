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
    @State private var phase: SessionPhase = .setReady
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
    @State private var celebrate = false
    @State private var showConfetti = true
    @State private var newPRExercises: [String] = []

    /// Fill for the screen region below the top-pinned 9:16 clip card — sampled from the current
    /// clip's bottom-edge pixels so the studio floor continues without a seam. Falls back to the
    /// hero canvas color until sampling lands (or when the exercise has no clip).
    @State private var canvasContinuation = Color(red: 0.965, green: 0.965, blue: 0.957)

    init(plan: WorkoutPlan) {
        self.plan = plan
    }

    var body: some View {
        ZStack {
            MTTheme.bg.ignoresSafeArea()

            if plan.items.isEmpty {
                emptyPlanContent
            } else if phase == .finished {
                finishedContent
                    .padding(20)
            } else {
                playerLayout
            }
        }
        .task(id: taskKey) { await runPhaseWatcher() }
        .task(id: currentItem.exercise.id) { await sampleCanvasContinuation() }
        .confirmationDialog("End workout?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End Workout", role: .destructive) { dismiss() }
            Button("Keep Going", role: .cancel) {}
        }
    }

    /// Edge-to-edge for the whole session: the clip is a full-screen backdrop in every phase, and
    /// the top bar, set label, and phase controls all float over it on the scrim — the video never
    /// shrinks into a boxed pane when a set begins.
    private var playerLayout: some View {
        ZStack {
            heroBackdrop

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Spacer(minLength: 0)
                VStack(spacing: 16) {
                    heroLabel
                    controlPane
                        .padding(.horizontal, 20)
                }
                .padding(.top, 140)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(MTHeroScrim().ignoresSafeArea(edges: .bottom))
            }
        }
    }

    /// The clip keeps the detail card's exact geometry — a full-width 9:16 fit pinned to the very
    /// top of the screen, so the figure sits in the same position on both screens and never crops.
    /// The remainder below continues the clip's sampled bottom-edge color, so the studio floor
    /// runs seamlessly to the bottom of the screen underneath the scrim.
    private var heroBackdrop: some View {
        VStack(spacing: 0) {
            AnatomyHeroView(exercise: currentItem.exercise, isPlaying: heroIsPlaying,
                            contentInset: 0, cornerRadius: 0)
                .aspectRatio(9.0 / 16.0, contentMode: .fit)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(canvasContinuation)
        .ignoresSafeArea()
    }

    private func sampleCanvasContinuation() async {
        guard let url = ExerciseClipStore.shared.clipURL(for: currentItem.exercise.id),
              let edge = await ClipEdgeColor.sample(url: url) else { return }
        canvasContinuation = Color(uiColor: edge)
    }

    /// Fixed dark ink for content floating over the light scrim — the clip canvas and scrim are
    /// light in both appearances, so themed text colors (light in dark mode) would disappear.
    private var ink: Color { Color(white: 0.12) }
    private var inkSoft: Color { Color(white: 0.3) }

    private var heroLabel: some View {
        VStack(spacing: 6) {
            Text("SET \(currentSet) OF \(currentItem.sets)")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(inkSoft)
            Text(currentItem.exercise.name)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)
            if isMobility {
                inkPill(text: "Mobility", systemImage: "leaf.fill")
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }

    /// Translucent white pill with dark ink — the over-hero counterpart of `MTChip`, which is
    /// themed and would go light-on-light in dark mode.
    private func inkPill(text: String, systemImage: String? = nil) -> some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(Color(white: 0.22))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.75), in: Capsule())
    }

    @ViewBuilder
    private var controlPane: some View {
        switch phase {
        case .setReady:
            beginSetContent
        case .working:
            workContent
        case .resting:
            restContent
        default:
            EmptyView()
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.32), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                }
                .buttonStyle(.plain)

                Spacer()

                TimelineView(.periodic(from: sessionStart, by: 1)) { timeline in
                    Text(elapsedString(now: timeline.date))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.32), in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.35), lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                }
            }

            // Item progress only when there's more than one exercise — a single full-width
            // segment reads as a stray line.
            if plan.items.count > 1 {
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
        if index == itemIndex { return MTTheme.volt.opacity(0.5) }
        return Color.white.opacity(0.3)
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

    // MARK: - Center section

    /// The clip plays while previewing (set-ready) or performing (working) and freezes during rest
    /// or when paused. A hold clip freezes itself on top of this: its manifest `type: hold` makes
    /// the player run the entry once (non-looping) and stop on the held frame, so the écorché
    /// settles into the isometric position for the full countdown instead of cycling through it.
    private var heroIsPlaying: Bool {
        !isPaused && (phase == .setReady || phase == .working)
    }

    // MARK: - Begin-set prompt

    private var beginSetContent: some View {
        VStack(spacing: 20) {
            Text(setTargetPreview)
                .font(MTTheme.numberFont(size: 34))
                .foregroundStyle(ink)
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
                    .foregroundStyle(ink)
                if showsLoadField {
                    loadField
                }
                MTPrimaryButton(title: isLastSetOfLastItem ? "Finish" : "Rest",
                                systemImage: isLastSetOfLastItem ? "flag.checkered" : "checkmark") {
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
                            .foregroundStyle(ink)
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
                .foregroundStyle(inkSoft)
            TextField("0", text: loadTextBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(ink)
                .frame(width: 72)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
            Text(unitLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(inkSoft)
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
                    .foregroundStyle(inkSoft)

                ZStack {
                    MTRing(progress: restProgress(remaining: remaining), lineWidth: 12)
                        .frame(width: 160, height: 160)
                    Text("\(Int(remaining.rounded()))")
                        .font(MTTheme.numberFont(size: 44))
                        .foregroundStyle(ink)
                }

                pauseButton

                skipButton

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

    /// Over-hero counterpart of `MTSecondaryButton` — white translucent capsule with dark ink,
    /// legible on the light scrim in both appearances.
    private var skipButton: some View {
        Button {
            Haptics.tap()
            advanceAfterRest()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Skip")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(ink)
            .background(Color.white.opacity(0.75))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func nextUpPreview(_ item: WorkoutItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                    .fill(Color.white.opacity(0.6))
                ExerciseAnimationView(exercise: item.exercise)
                    .padding(8)
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT UP")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(inkSoft)
                Text(item.exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ink)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
    }

    // MARK: - Finished

    private var finishedContent: some View {
        ZStack {
            if showConfetti {
                CelebrationConfetti(colors: [MTTheme.volt, MTTheme.water, MTTheme.protein,
                                             MTTheme.carbs, MTTheme.success])
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }

            VStack(spacing: 22) {
                trophyBadge

                VStack(spacing: 6) {
                    Text("Workout Complete!")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text(motivationalLine)
                        .font(.system(size: 15))
                        .foregroundStyle(MTTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                statsGrid(minutes: elapsedMinutes(now: Date()))

                if volumeKg > 0 {
                    MTChip(text: volumeSummaryText, systemImage: "scalemass.fill")
                }

                if !newPRExercises.isEmpty {
                    Label("New personal best · \(newPRExercises.joined(separator: ", "))",
                          systemImage: "trophy.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                        .multilineTextAlignment(.center)
                }

                MTPrimaryButton(title: "Save & Finish", systemImage: "checkmark") {
                    Task { await saveAndFinish() }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            Haptics.success()
            AppSound.achievement()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                celebrate = true
            }
            Task {
                try? await Task.sleep(for: .seconds(4))
                showConfetti = false
            }
        }
    }

    private var trophyBadge: some View {
        ZStack {
            Circle()
                .fill(MTTheme.voltDim)
                .frame(width: 108, height: 108)
            Image(systemName: "trophy.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(MTTheme.volt)
        }
        .scaleEffect(celebrate ? 1 : 0.3)
        .rotationEffect(.degrees(celebrate ? 0 : -20))
        .shadow(color: MTTheme.volt.opacity(0.35), radius: 24)
    }

    private var motivationalLine: String {
        let lines = [
            "Every rep counts. You showed up.",
            "That's how progress is built.",
            "Strong work — your body thanks you.",
            "Consistency beats intensity. Nailed it.",
            "One more session in the books."
        ]
        return lines[completedExerciseIDs.count % lines.count]
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

    private func beginSet() {
        Haptics.tap()
        phase = .working
        resetPhaseAnchor()
    }

    private func completeSet() {
        Haptics.success()
        recordPersonalBest()
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

    // MARK: - Personal bests

    /// Upserts this exercise's personal best from the just-completed set, recording which exercises
    /// hit a new record so the celebration can call it out.
    private func recordPersonalBest() {
        let exercise = currentItem.exercise
        let id = exercise.id
        let descriptor = FetchDescriptor<PersonalBest>(
            predicate: #Predicate<PersonalBest> { $0.exerciseID == id })
        let record: PersonalBest
        if let existing = try? modelContext.fetch(descriptor).first {
            record = existing
        } else {
            record = PersonalBest(exerciseID: id)
            modelContext.insert(record)
        }

        var improved = false
        switch currentItem.kind {
        case .reps(let n):
            if n > record.bestReps { record.bestReps = n; improved = true }
            if currentLoadKg > record.bestLoadKg { record.bestLoadKg = currentLoadKg; improved = true }
        case .timed(let seconds):
            if seconds > record.bestHoldSeconds { record.bestHoldSeconds = seconds; improved = true }
        }

        if improved {
            record.updatedAt = .now
            if !newPRExercises.contains(exercise.name) {
                newPRExercises.append(exercise.name)
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

/// Lightweight Canvas confetti for the completion celebration — colored pieces fall from above,
/// drift, spin, and fade past the bottom. Precomputes random pieces once; draws each frame.
private struct CelebrationConfetti: View {
    let colors: [Color]
    private let pieces: [ConfettiPiece]
    @State private var start = Date()

    init(colors: [Color], count: Int = 110) {
        self.colors = colors
        self.pieces = (0..<count).map { _ in ConfettiPiece.random(colors: colors) }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                for piece in pieces {
                    let s = piece.state(at: t, height: size.height)
                    guard s.alpha > 0.01 else { continue }
                    let progress = min(max((t - piece.delay) / piece.fallDuration, 0), 1)
                    let x = piece.xFrac * size.width + piece.drift * CGFloat(progress)
                    context.drawLayer { layer in
                        layer.opacity = s.alpha
                        layer.translateBy(x: x, y: s.y)
                        layer.rotate(by: .degrees(s.rot))
                        let rect = CGRect(x: -piece.w / 2, y: -piece.h / 2, width: piece.w, height: piece.h)
                        layer.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(piece.color))
                    }
                }
            }
        }
    }
}

private struct ConfettiPiece {
    let xFrac: CGFloat
    let delay: Double
    let fallDuration: Double
    let drift: CGFloat
    let rotationSpeed: Double
    let w: CGFloat
    let h: CGFloat
    let color: Color
    let startY: CGFloat

    static func random(colors: [Color]) -> ConfettiPiece {
        ConfettiPiece(
            xFrac: .random(in: 0...1),
            delay: .random(in: 0...0.7),
            fallDuration: .random(in: 2.0...3.2),
            drift: .random(in: -50...50),
            rotationSpeed: .random(in: -240...240),
            w: .random(in: 6...10),
            h: .random(in: 9...15),
            color: colors.randomElement() ?? .green,
            startY: .random(in: -160 ... -20)
        )
    }

    /// Position/rotation/alpha at elapsed `time`. Falls from `startY` to past the bottom over
    /// `fallDuration`, fading in the last stretch.
    func state(at time: Double, height: CGFloat) -> (y: CGFloat, rot: Double, alpha: Double) {
        let t = time - delay
        guard t >= 0 else { return (startY, 0, 0) }
        let p = min(t / fallDuration, 1)
        let y = startY + (height + 200) * CGFloat(p)
        let rot = rotationSpeed * t
        let alpha: Double = p > 0.82 ? Double((1 - p) / 0.18) : 1
        return (y, rot, alpha)
    }
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
