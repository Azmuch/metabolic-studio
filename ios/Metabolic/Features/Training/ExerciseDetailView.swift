import SwiftUI
import SwiftData
import UIKit
import MetabolicCore

/// Exercise detail: a full-bleed 9:16 animation hero with the name + muscles overlaid poster-style,
/// a compact info row, a **Preview & Customize** block (level + sets/reps/duration/rest → start a
/// single-exercise session), and a pull-down "How to". An injury-flag banner appears when the move
/// is contraindicated for the user's profile.
struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var personalBests: [PersonalBest]

    @State private var howToExpanded = false
    @State private var level: TrainingLevel = .intermediate
    @State private var sets: Int
    @State private var reps: Int
    @State private var seconds: Int
    @State private var restSeconds: Int
    @State private var loadText = ""
    @State private var savedAsWorkout = false
    @State private var runningPlan: RunnablePlan?

    /// A progression-family sibling the user swapped to (via the Variations chips or a level
    /// preset). `nil` = the exercise this screen opened on.
    @State private var variant: Exercise?

    /// The movement everything on screen reflects — hero, chips, prescription, and session start.
    private var active: Exercise { variant ?? exercise }

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
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroCard

                    VStack(alignment: .leading, spacing: 16) {
                        if let pack = PackStore.shared.lockingPack(for: active.id) {
                            packUnlockBanner(pack)
                        }
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

            backButton
                .padding(.leading, 16)
                .padding(.top, 8)
        }
        .overlay(alignment: .topTrailing) {
            favoriteButton
                .padding(.trailing, 16)
                .padding(.top, 8)
        }
        .background(MTBackground().ignoresSafeArea())
        .background(SwipeBackEnabler())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $runningPlan) { runnable in
            SessionPlayerView(plan: runnable.plan, initialLoadsKg: runnable.initialLoadsKg)
        }
    }

    private var favoriteButton: some View {
        Button {
            Haptics.tap()
            appState.toggleFavorite(active.id)
        } label: {
            Image(systemName: appState.isFavorite(active.id) ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(appState.isFavorite(active.id) ? MTTheme.volt : .white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.32), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(appState.isFavorite(active.id) ? "Unsave exercise" : "Save exercise")
    }

    private var personalBest: PersonalBest? {
        personalBests.first { $0.exerciseID == active.id }
    }

    private func prSummary(_ pb: PersonalBest) -> String {
        var parts: [String] = []
        if pb.bestReps > 0 { parts.append("\(pb.bestReps) reps") }
        if pb.bestLoadKg > 0 {
            let value = appState.unitSystem == .imperial ? Units.pounds(fromKg: pb.bestLoadKg) : pb.bestLoadKg
            let unit = appState.unitSystem == .imperial ? "lb" : "kg"
            parts.append("\(Int(value.rounded())) \(unit)")
        }
        if pb.bestHoldSeconds > 0 { parts.append("\(pb.bestHoldSeconds)s hold") }
        return "PB · " + parts.joined(separator: " · ")
    }

    /// Floating, self-legible back button (dark translucent — reads over the light hero and over
    /// scrolled content alike, so no top gradient is needed). Swipe-back stays enabled via
    /// `SwipeBackEnabler`.
    private var backButton: some View {
        Button {
            Haptics.tap()
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.32), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero (edge-to-edge 9:16, extends under the status bar, name + muscles overlaid)

    private var heroCard: some View {
        AnatomyHeroView(exercise: active, isPlaying: true, contentInset: 0)
            .aspectRatio(9.0 / 16.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) { heroOverlay }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 28,
                    bottomTrailingRadius: 28, topTrailingRadius: 0, style: .continuous))
    }

    private var heroOverlay: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(active.muscleGroups, id: \.self) { group in
                    overlayChip(group.displayName)
                }
            }
            HStack(alignment: .center, spacing: 12) {
                Text(active.name)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(white: 0.12))
                Spacer(minLength: 0)
                Button {
                    startCustomSession()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(width: 56, height: 56)
                        .background(MTTheme.volt, in: Circle())
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start \(active.name)")
            }
        }
        .padding(20)
        .padding(.top, 72)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MTHeroScrim())
    }

    private func overlayChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(white: 0.22))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.75), in: Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 0.5))
    }

    // MARK: - Pack unlock

    /// Shown when this exercise belongs to an expansion pack the user hasn't purchased — the demo
    /// clip won't resolve until then, so route to the pack storefront.
    private func packUnlockBanner(_ pack: ExpansionPack) -> some View {
        NavigationLink {
            PacksView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MTTheme.accentText)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Part of the \(pack.title) Pack")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("Unlock to get the full demo and all \(pack.exerciseIDs.count) exercises.")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MTTheme.textTertiary)
            }
            .padding(14)
            .background(MTTheme.voltDim)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Injury warning

    private var flaggedInjuries: Set<InjuryFlag> {
        active.contraindications.intersection(appState.profile.injuries)
    }

    private var hasFlaggedInjury: Bool {
        !active.contraindications.isDisjoint(with: appState.profile.injuries)
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
                MTChip(text: "MET \(String(format: "%.1f", active.met))", systemImage: "bolt.fill")
                MTChip(text: "~\(estimatedCaloriesPer10Min) kcal / 10 min", systemImage: "flame")
            }
            if let pb = personalBest, pb.hasAnyRecord {
                MTChip(text: prSummary(pb), systemImage: "trophy.fill", isActive: true)
            }
        }
    }

    private var sortedEquipment: [Equipment] {
        active.equipment.sorted { $0.displayName < $1.displayName }
    }

    private var estimatedCaloriesPer10Min: Int {
        Int(
            CalorieBurnCalculator.kilocalories(
                met: active.met, weightKg: appState.profile.weightKg, minutes: 10
            ).rounded()
        )
    }

    // MARK: - Preview & customize

    private var isReps: Bool {
        if case .reps = active.kind { return true }
        return false
    }

    /// This exercise's progression family (easiest → hardest, including itself), or empty when
    /// it stands alone. Keyed off the exercise the screen opened on, so the row is stable while
    /// the user hops between siblings.
    private var variations: [Exercise] {
        ExerciseProgressions.variations(of: exercise.id)
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

            if variations.count > 1 {
                variationsRow
            }

            stepperRow("Sets", value: $sets, range: 1...8)
            if isReps {
                stepperRow("Reps", value: $reps, range: 1...50)
            } else {
                stepperRow("Seconds", value: $seconds, range: 5...300, step: 5, suffix: "s")
            }
            stepperRow("Rest", value: $restSeconds, range: 0...180, step: 5, suffix: "s")
            if showsLoadRow {
                loadRow
            }

            MTPrimaryButton(title: level == .freestyle ? "Start Freestyle" : "Start Exercise",
                            systemImage: "play.fill") {
                startCustomSession()
            }

            HStack(spacing: 10) {
                Button {
                    saveAsWorkout()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: savedAsWorkout ? "checkmark" : "bookmark")
                            .font(.system(size: 15, weight: .semibold))
                        Text(savedAsWorkout ? "Saved to My Workouts" : "Save to My Workouts")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(MTTheme.textPrimary)
                    .background(MTTheme.surface2, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(savedAsWorkout)

                if let shareURL = WorkoutShare.exportURL(
                    for: CustomWorkout(name: active.name, items: [configuredItem()])) {
                    ShareLink(item: shareURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MTTheme.accentText)
                            .frame(width: 44, height: 44)
                            .background(MTTheme.voltDim, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share this exercise setup")
                }
            }
        }
        .padding(16)
        .background(MTTheme.surface, in: RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
    }

    // MARK: - Load (entered here — the auto-rolling countdown leaves no time mid-session)

    private var showsLoadRow: Bool {
        !active.equipment.contains(.none)
    }

    private var loadUnit: String {
        appState.unitSystem == .imperial ? "lb" : "kg"
    }

    /// Entered load converted to kg, or 0 when empty/unparsable.
    private var currentLoadKg: Double {
        guard let value = Double(loadText.replacingOccurrences(of: ",", with: ".")), value > 0 else {
            return 0
        }
        return appState.unitSystem == .imperial ? Units.kg(fromPounds: value) : value
    }

    private var loadRow: some View {
        HStack {
            Text("Load")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
            Spacer()
            TextField("0", text: $loadText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(MTTheme.textPrimary)
                .frame(width: 64)
                .padding(.vertical, 7)
                .background(MTTheme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
            Text(loadUnit)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MTTheme.textTertiary)
        }
    }

    /// The exercise exactly as configured on this screen, as a shareable/saveable workout item.
    private func configuredItem() -> CustomWorkoutItem {
        var item = CustomWorkoutItem(exercise: active)
        item.sets = sets
        item.isTimed = !isReps
        item.reps = reps
        item.seconds = seconds
        item.restSeconds = restSeconds
        item.loadKg = currentLoadKg > 0 ? currentLoadKg : nil
        return item
    }

    private func saveAsWorkout() {
        guard !savedAsWorkout else { return }
        Haptics.success()
        modelContext.insert(CustomWorkout(name: active.name, items: [configuredItem()]))
        withAnimation(.snappy(duration: 0.25)) { savedAsWorkout = true }
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

    // MARK: - Variations (progression family)

    /// Chips for the family siblings, easiest → hardest. Tapping swaps the whole screen — hero
    /// clip, muscles, cues, prescription — to that movement; level presets pre-select the
    /// tier-matching sibling automatically.
    private var variationsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("VARIATIONS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                Spacer()
                Text("easiest → hardest")
                    .font(.system(size: 10))
                    .foregroundStyle(MTTheme.textTertiary)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(variations) { variation in
                        variationChip(variation)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    /// Each chip carries the movement's fixed tier badge, so an advanced sibling reads as
    /// advanced even while a Beginner preset is active.
    private func variationChip(_ variation: Exercise) -> some View {
        let selected = variation.id == active.id
        return Button {
            Haptics.tap()
            selectVariant(variation.id)
        } label: {
            HStack(spacing: 6) {
                Text(variation.name)
                    .font(.system(size: 13, weight: .semibold))
                if let tier = ExerciseProgressions.tier(of: variation.id) {
                    Text(tier.shortName)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(selected ? Color.black.opacity(0.55) : MTTheme.textTertiary)
                }
            }
            .foregroundStyle(selected ? Color.black : MTTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? MTTheme.volt : MTTheme.surface2, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Swaps the screen to a family sibling and re-baselines the prescription for it at the
    /// current level (its own default reps/seconds, scaled).
    private func selectVariant(_ id: String) {
        guard id != active.id, let target = ExerciseLibrary.exercise(id: id) else { return }
        withAnimation(.snappy(duration: 0.3)) {
            variant = target.id == exercise.id ? nil : target
        }
        applyVolumePreset(level)
    }

    /// Level presets map onto the family's **fixed** tiers: every exercise carries one absolute
    /// difficulty (L-Sit is Advanced everywhere), so Beginner always selects the family's
    /// beginner-tier movement regardless of which sibling the screen opened on. Freestyle keeps
    /// the user's manual pick — and a manual pick never re-labels the movement's own tier. The
    /// volume preset applies to whichever movement ends up active.
    private func applyLevel(_ level: TrainingLevel) {
        if let targetID = levelVariantID(for: level), targetID != active.id,
           let target = ExerciseLibrary.exercise(id: targetID) {
            withAnimation(.snappy(duration: 0.3)) {
                variant = target.id == exercise.id ? nil : target
            }
        }
        applyVolumePreset(level)
    }

    private func levelVariantID(for level: TrainingLevel) -> String? {
        guard let family = ExerciseProgressions.family(containing: exercise.id) else { return nil }
        let tier: ProgressionTier
        switch level {
        case .beginner: tier = .beginner
        case .intermediate: tier = .intermediate
        case .advanced: tier = .advanced
        case .freestyle: return nil
        }
        return ExerciseProgressions.member(of: family, tier: tier)
    }

    private func applyVolumePreset(_ level: TrainingLevel) {
        switch level {
        case .beginner: sets = 2; scaleVolume(0.7)
        case .intermediate: sets = 3; scaleVolume(1.0)
        case .advanced: sets = 4; scaleVolume(1.3)
        case .freestyle: sets = 1; scaleVolume(1.0)
        }
    }

    private func scaleVolume(_ scale: Double) {
        switch active.kind {
        case .reps(let base): reps = max(1, Int((Double(base) * scale).rounded()))
        case .timed(let base): seconds = max(5, Int((Double(base) * scale).rounded()))
        }
    }

    private func startCustomSession() {
        let kind: ExerciseKind = isReps ? .reps(reps) : .timed(seconds: seconds)
        let item = WorkoutItem(id: active.id, exercise: active, sets: sets, kind: kind,
                               restSeconds: restSeconds)
        let workSeconds = isReps ? sets * reps * 3 : sets * seconds
        let estimated = max(1, (workSeconds + sets * restSeconds) / 60)
        let plan = WorkoutPlan(date: .now, focus: .fullBody, title: active.name,
                               items: [item], estimatedMinutes: estimated)
        runningPlan = RunnablePlan(
            plan: plan,
            initialLoadsKg: currentLoadKg > 0 ? [active.id: currentLoadKg] : [:])
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
                    ForEach(Array(active.instructions.enumerated()), id: \.offset) { index, cue in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle().fill(MTTheme.voltDim).frame(width: 26, height: 26)
                                Text("\(index + 1)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(MTTheme.accentText)
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

/// Keeps the interactive edge-swipe-back gesture working while the system back button is hidden
/// (so the custom floating back button can be used without losing native swipe navigation).
private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { Proxy() }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private final class Proxy: UIViewController, UIGestureRecognizerDelegate {
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
            gesture.delegate = self
            gesture.isEnabled = true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
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
