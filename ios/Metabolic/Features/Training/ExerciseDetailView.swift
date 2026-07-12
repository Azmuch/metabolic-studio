import SwiftUI
import MetabolicCore

/// Big hero animation, muscle/equipment chips, numbered cues, and an injury flag banner
/// when the exercise is contraindicated for the user's profile.
struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(AppState.self) private var appState

    init(exercise: Exercise) {
        self.exercise = exercise
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                muscleMapCard

                if hasFlaggedInjury {
                    warningBanner
                }

                Text(exercise.name)
                    .font(MTTheme.numberFont(size: 28))
                    .foregroundStyle(MTTheme.textPrimary)

                chipsSection
                infoRow
                howToSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(MTBackground())
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var heroCard: some View {
        AnatomyHeroView(exercise: exercise)
            .frame(height: 300)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Muscle map

    private var muscleMapCard: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("MUSCLES ACTIVATED")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                MuscleMapView(highlighted: exercise.muscleGroups)
            }
        }
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

    // MARK: - Chips

    private var chipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(exercise.muscleGroups, id: \.self) { group in
                    MTChip(text: group.displayName)
                }
            }
            HStack(spacing: 8) {
                ForEach(sortedEquipment, id: \.self) { equipment in
                    MTChip(text: equipment.displayName, systemImage: equipment.symbolName)
                }
            }
        }
    }

    private var sortedEquipment: [Equipment] {
        exercise.equipment.sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Info row

    private var infoRow: some View {
        HStack(spacing: 8) {
            MTChip(text: "MET \(String(format: "%.1f", exercise.met))", systemImage: "bolt.fill")
            MTChip(text: "~\(estimatedCaloriesPer10Min) kcal / 10 min", systemImage: "flame")
            MTChip(text: prescriptionText, systemImage: "repeat")
        }
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

    // MARK: - How to

    private var howToSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HOW TO")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textTertiary)

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
