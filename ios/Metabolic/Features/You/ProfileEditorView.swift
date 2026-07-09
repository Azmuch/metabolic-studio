import SwiftUI
import MetabolicCore

/// Full fitness-profile editor. Edits a local draft and commits on Save —
/// `AppState` recomputes targets and persists automatically.
struct ProfileEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var draft = FitnessProfile.default
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                bodySection
                goalSection
                lifestyleSection
                healthSection
                equipmentSection
                scheduleSection
                targetsFooter
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .background(MTTheme.bg.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if draft.equipment.isEmpty { draft.equipment = [Equipment.none] }
                    appState.profile = draft
                    Haptics.success()
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .tint(MTTheme.volt)
            }
        }
        .onAppear {
            guard !loaded else { return }
            draft = appState.profile
            loaded = true
        }
    }

    private var bodySection: some View {
        section("Body") {
            HStack(spacing: 12) {
                metricField(label: "Age", value: "\(draft.age)")
                Stepper("", value: $draft.age, in: 14...90).labelsHidden()
            }
            Picker("Sex", selection: $draft.sex) {
                ForEach(BiologicalSex.allCases, id: \.self) {
                    Text($0 == .male ? "Male" : "Female").tag($0)
                }
            }
            .pickerStyle(.segmented)
            sliderRow(label: "Height", value: $draft.heightCm, range: 140...210, step: 1,
                      format: { "\(Int($0)) cm" })
            sliderRow(label: "Weight", value: $draft.weightKg, range: 40...160, step: 0.5,
                      format: { String(format: "%.1f kg", $0) })
        }
    }

    private var goalSection: some View {
        section("Goal") {
            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                selectableRow(title: goal.displayName, isSelected: draft.goal == goal) {
                    draft.goal = goal
                }
            }
        }
    }

    private var lifestyleSection: some View {
        section("Lifestyle") {
            ForEach(ActivityLevel.allCases, id: \.self) { level in
                selectableRow(title: level.displayName, isSelected: draft.activityLevel == level) {
                    draft.activityLevel = level
                }
            }
            Picker("Experience", selection: $draft.experience) {
                ForEach(ExperienceLevel.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var healthSection: some View {
        section("Health flags") {
            FlowChips(items: InjuryFlag.allCases.map { ($0.displayName, draft.injuries.contains($0)) }) { index in
                let flag = InjuryFlag.allCases[index]
                if draft.injuries.contains(flag) { draft.injuries.remove(flag) }
                else { draft.injuries.insert(flag) }
            }
        }
    }

    private var equipmentSection: some View {
        section("Equipment") {
            FlowChips(items: Equipment.allCases.map { ($0.displayName, draft.equipment.contains($0)) }) { index in
                let equipment = Equipment.allCases[index]
                if draft.equipment.contains(equipment) { draft.equipment.remove(equipment) }
                else { draft.equipment.insert(equipment) }
            }
        }
    }

    private var scheduleSection: some View {
        section("Schedule") {
            HStack {
                Text("Days per week")
                    .font(.system(size: 15))
                    .foregroundStyle(MTTheme.textSecondary)
                Spacer()
                Picker("", selection: $draft.workoutDaysPerWeek) {
                    ForEach(2...6, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            HStack(spacing: 8) {
                ForEach([15, 30, 45, 60, 90], id: \.self) { minutes in
                    Button {
                        Haptics.tap()
                        draft.sessionMinutes = minutes
                    } label: {
                        MTChip(text: "\(minutes)m", isActive: draft.sessionMinutes == minutes)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var targetsFooter: some View {
        let targets = NutritionEngine.targets(for: draft)
        return Text("Daily target: \(targets.calories) kcal · \(targets.proteinG) g protein · \(targets.waterML) ml water")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(MTTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    // MARK: - Building blocks

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        MTCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricField(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(MTTheme.textSecondary)
            Spacer()
            Text(value)
                .font(MTTheme.numberFont(size: 20))
                .foregroundStyle(MTTheme.textPrimary)
        }
    }

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>,
                           step: Double, format: @escaping (Double) -> String) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(MTTheme.textSecondary)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(MTTheme.numberFont(size: 20))
                    .foregroundStyle(MTTheme.textPrimary)
            }
            Slider(value: value, in: range, step: step)
                .tint(MTTheme.volt)
        }
    }

    private func selectableRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(MTTheme.textPrimary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? MTTheme.volt : MTTheme.textTertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

/// Simple wrapping chip grid used for multi-select flag/equipment editing.
private struct FlowChips: View {
    let items: [(label: String, isActive: Bool)]
    let onTap: (Int) -> Void

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    Haptics.tap()
                    onTap(index)
                } label: {
                    MTChip(text: items[index].label, isActive: items[index].isActive)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    NavigationStack { ProfileEditorView() }
        .environment(AppState())
}
