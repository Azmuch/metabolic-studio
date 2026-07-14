import SwiftUI
import MetabolicCore

/// Exercise detail: a dominant 9:16 animation hero (matching the Seedance clip aspect ratio) with
/// the exercise name and target muscles overlaid poster-style, a compact info row, and a
/// pull-down "How to". An injury-flag banner appears when the move is contraindicated.
struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(AppState.self) private var appState
    @State private var howToExpanded = false

    init(exercise: Exercise) {
        self.exercise = exercise
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroCard

                if hasFlaggedInjury {
                    warningBanner
                }

                infoRow
                howToDisclosure
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(MTBackground())
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero (9:16, name + muscles overlaid)

    private var heroCard: some View {
        AnatomyHeroView(exercise: exercise)
            .aspectRatio(9.0 / 16.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) { heroOverlay }
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                    .stroke(MTTheme.stroke, lineWidth: 1))
    }

    private var heroOverlay: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(exercise.muscleGroups, id: \.self) { group in
                    overlayChip(group.displayName)
                }
            }
            Text(exercise.name)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
        }
        .padding(20)
        .padding(.top, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.black.opacity(0), .black.opacity(0.35), .black.opacity(0.72)],
                startPoint: .top, endPoint: .bottom)
        )
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
                MTChip(text: prescriptionText, systemImage: "repeat")
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

    private var prescriptionText: String {
        switch exercise.kind {
        case .reps(let n): return "\(n) reps"
        case .timed(let seconds): return "\(seconds)s"
        }
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
