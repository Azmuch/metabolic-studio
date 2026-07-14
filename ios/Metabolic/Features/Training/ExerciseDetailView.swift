import SwiftUI
import MetabolicCore

/// Exercise detail: a full-bleed 9:16 animation hero with the name + muscles overlaid poster-style,
/// a compact info row, a **Preview & Customize** block (level + sets/reps/duration/rest → start a
/// single-exercise session), and a pull-down "How to". An injury-flag banner appears when the move
/// is contraindicated for the user's profile.
struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(AppState.self) private var appState

    @State private var howToExpanded = false
    @State private var level: TrainingLevel = .intermediate
    @State private var sets: Int
    @State private var reps: Int
    @State private var seconds: Int
    @State private var restSeconds: Int
    @State private var runningPlan: RunnablePlan?

    init(exercise: Exercise) {
        self.exercise = exercise
        switch exercise.kind {
        case .reps(let n):
            _reps = State(initialValue: n)
            _seconds = State(initialValue: 40)
        case .timed(let s):
            _seconds = State(initialValue: s)
            _reps = State(initialValue: 12)
        }
        _sets = State(initialValue: 3)
        _restSeconds = State(initialValue: 45)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroCard

                VStack(alignment: .leading, spacing: 16) {
                    if hasFlaggedInjury {
                        warningBanner
                    }
                    infoRow
                    customizeCard
                    howToDisclosure
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background(MTBackground().ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(MTTheme.volt)
        .fullScreenCover(item: $runningPlan) { runnable in
            SessionPlayerView(plan: runnable.plan)
        }
    }

    // MARK: - Hero (edge-to-edge 9:16, extends under the status bar, name + muscles overlaid)

    private var heroCard: some View {
        AnatomyHeroView(exercise: exercise, isPlaying: true, contentInset: 0)
            .aspectRatio(9.0 / 16.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) { topScrim }
            .overlay(alignment: .bottom) { heroOverlay }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 28,
                    bottomTrailingRadius: 28, topTrailingRadius: 0, style: .continuous))
    }

    /// Subtle darkening under the status bar so the transparent-nav-bar back chevron stays legible
    /// over the light hero top (keeps the native swipe-back gesture intact).
    private var topScrim: some View {
        LinearGradient(colors: [.black.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: 130)
    }

    private var heroOverlay: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(exercise.muscleGroups, id: \.self) { group in
                    overlayChip(group.displayName)
                }
            }
            HStack(alignment: .center, spacing: 12) {
                Text(exercise.name)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
                Spacer(minLength: 0)
                Button {
                    startCustomSession()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(width: 56, height: 56)
                        .background(MTTheme.volt, in: Circle())
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start \(exercise.name)")
            }
        }
        .padding(20)
        .padding(.top, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(scrim)
    }

    /// A single clean gradient into the deep, accent-tinted `heroScrim` — coordinates with the UI
    /// theme (re-renders live when the accent changes) while staying dark enough for white text and
    /// reading clean rather than a muddy black + bright-accent mix.
    private var scrim: some View {
        LinearGradient(
            colors: [.clear, MTTheme.heroScrim.opacity(0.38), MTTheme.heroScrim.opacity(0.84)],
            startPoint: .top, endPoint: .bottom)
    }

    private func overlayChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.20), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.30), lineWidth: 0.5))
    }

    // MARK: - Injury warning

    private var flaggedInjuries: Set<InjuryFlag> {
        exercise.contraindications.intersection(appState.profile.injuries)
    }

    private var hasFlaggedInjury: Bool {
        !exercise.contraindications.isDisjoint(with: appState.profile.injuries)
    }

    private var flaggedInjuryNames: String {
        flaggedInjuries.map(\.displayName).sorted().joined(separator: ", ")
    }

    private var warningBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MTTheme.warning)
            Text("Flagged for your \(flaggedInjuryNames) — swap or go light.")
                .font(.system(size: 13))
                .foregroundStyle(MTTheme.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(MTTheme.warning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
    }

    // MARK: - Info row (equipment + metrics)

    private var infoRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(sortedEquipment, id: \.self) { equipment in
                    MTChip(text: equipment.displayName, systemImage: equipment.symbolName)
                }
            }
            HStack(spacing: 8) {
                MTChip(text: "MET \(String(format: "%.1f", exercise.met))", systemImage: "bolt.fill")
                MTChip(text: "~\(estimatedCaloriesPer10Min) kcal / 10 min", systemImage: "flame")
            }
        }
    }

    private var sortedEquipment: [Equipment] {
        exercise.equipment.sorted { $0.displayName < $1.displayName }
    }

    private var estimatedCaloriesPer10Min: Int {
        Int(
            CalorieBurnCalculator.kilocalories(
                met: exercise.met, weightKg: appState.profile.weightKg, minutes: 10
            ).rounded()
        )
    }

    // MARK: - Preview & customize

    private var isReps: Bool {
        if case .reps = exercise.kind { return true }
        return false
    }

    private var customizeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PREVIEW & CUSTOMIZE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textTertiary)

            Picker("Level", selection: $level) {
                ForEach(TrainingLevel.allCases, id: \.self) { lvl in
                    Text(lvl.displayName).tag(lvl)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: level) { _, newValue in applyLevel(newValue) }

            Text("Levels preset your volume — fine-tune anything below.")
                .font(.system(size: 12))
                .foregroundStyle(MTTheme.textTertiary)

            stepperRow("Sets", value: $sets, range: 1...8)
            if isReps {
                stepperRow("Reps", value: $reps, range: 1...50)
            } else {
                stepperRow("Seconds", value: $seconds, range: 5...300, step: 5, suffix: "s")
            }
            stepperRow("Rest", value: $restSeconds, range: 0...180, step: 5, suffix: "s")

            MTPrimaryButton(title: level == .freestyle ? "Start Freestyle" : "Start Exercise",
                            systemImage: "play.fill") {
                startCustomSession()
            }
        }
        .padding(16)
        .background(MTTheme.surface, in: RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
    }

    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>,
                            step: Int = 1, suffix: String = "") -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
            Spacer()
            Text("\(value.wrappedValue)\(suffix)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(MTTheme.textSecondary)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
                .tint(MTTheme.volt)
        }
    }

    private func applyLevel(_ level: TrainingLevel) {
        switch level {
        case .beginner: sets = 2; scaleVolume(0.7)
        case .intermediate: sets = 3; scaleVolume(1.0)
        case .advanced: sets = 4; scaleVolume(1.3)
        case .freestyle: sets = 1; scaleVolume(1.0)
        }
    }

    private func scaleVolume(_ scale: Double) {
        switch exercise.kind {
        case .reps(let base): reps = max(1, Int((Double(base) * scale).rounded()))
        case .timed(let base): seconds = max(5, Int((Double(base) * scale).rounded()))
        }
    }

    private func startCustomSession() {
        let kind: ExerciseKind = isReps ? .reps(reps) : .timed(seconds: seconds)
        let item = WorkoutItem(id: exercise.id, exercise: exercise, sets: sets, kind: kind,
                               restSeconds: restSeconds)
        let workSeconds = isReps ? sets * reps * 3 : sets * seconds
        let estimated = max(1, (workSeconds + sets * restSeconds) / 60)
        let plan = WorkoutPlan(date: .now, focus: .fullBody, title: exercise.name,
                               items: [item], estimatedMinutes: estimated)
        runningPlan = RunnablePlan(plan: plan)
    }

    // MARK: - How to (pull-down)

    private var howToDisclosure: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptics.tap()
                withAnimation(.snappy(duration: 0.28)) { howToExpanded.toggle() }
            } label: {
                HStack {
                    Text("HOW TO")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MTTheme.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MTTheme.textTertiary)
                        .rotationEffect(.degrees(howToExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if howToExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, cue in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle().fill(MTTheme.voltDim).frame(width: 26, height: 26)
                                Text("\(index + 1)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(MTTheme.volt)
                            }
                            Text(cue)
                                .font(.system(size: 15))
                                .foregroundStyle(MTTheme.textPrimary)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.top, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(MTTheme.surface, in: RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
    }
}

/// Preset difficulty for the single-exercise preview session. Presets scale sets + reps/seconds;
/// the steppers stay editable. Freestyle is a single self-paced set.
fileprivate enum TrainingLevel: String, CaseIterable {
    case beginner, intermediate, advanced, freestyle

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Inter"
        case .advanced: return "Advanced"
        case .freestyle: return "Freestyle"
        }
    }
}

#Preview {
    NavigationStack {
        Group {
            if let exercise = ExerciseLibrary.all.first {
                ExerciseDetailView(exercise: exercise)
            } else {
                Text("No exercises")
                    .foregroundStyle(MTTheme.textSecondary)
            }
        }
    }
    .environment(AppState())
}
