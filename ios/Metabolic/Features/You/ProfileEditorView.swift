import SwiftUI
import MetabolicCore

/// Full fitness-profile editor. Edits a local draft and commits on Save —
/// `AppState` recomputes targets and persists automatically.
struct ProfileEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var draft = FitnessProfile.default
    @State private var loaded = false
    @State private var showBodyMap = false
    @State private var customEquipmentText = ""

    private var focusableGroups: [MuscleGroup] {
        MuscleGroup.allCases.filter { $0 != .fullBody && $0 != .cardio }
    }

    private var recommendation: (days: Int, minutes: Int) {
        ScheduleRecommender.recommendation(for: draft)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                bodySection
                goalSection
                lifestyleSection
                healthSection
                dietSection
                equipmentSection
                scheduleSection
                macrosSection
                targetsFooter
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .background(MTBackground().ignoresSafeArea())
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
        .sheet(isPresented: $showBodyMap) {
            BodyMapView(selectedAreas: $draft.focusAreas, customFlags: $draft.customFlags)
        }
    }

    private var bodySection: some View {
        section("Body") {
            @Bindable var appState = appState

            Picker("Units", selection: $appState.unitSystem) {
                ForEach(UnitSystem.allCases, id: \.self) { system in
                    Text(system == .metric ? "Metric" : "US").tag(system)
                }
            }
            .pickerStyle(.segmented)

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

            heightRow(unitSystem: appState.unitSystem)
            weightRow(unitSystem: appState.unitSystem)
        }
    }

    private func heightRow(unitSystem: UnitSystem) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("Height")
                    .font(.system(size: 15))
                    .foregroundStyle(MTTheme.textSecondary)
                Spacer()
                Text(Units.heightString(cm: draft.heightCm, system: unitSystem))
                    .font(MTTheme.numberFont(size: 20))
                    .foregroundStyle(MTTheme.textPrimary)
            }
            Slider(value: $draft.heightCm, in: 140...210, step: 1)
                .tint(MTTheme.volt)
        }
    }

    private func weightRow(unitSystem: UnitSystem) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("Weight")
                    .font(.system(size: 15))
                    .foregroundStyle(MTTheme.textSecondary)
                Spacer()
                Text(Units.weightString(kg: draft.weightKg, system: unitSystem))
                    .font(MTTheme.numberFont(size: 20))
                    .foregroundStyle(MTTheme.textPrimary)
            }
            if unitSystem == .metric {
                Slider(value: $draft.weightKg, in: 40...160, step: 0.5)
                    .tint(MTTheme.volt)
            } else {
                Slider(value: weightPoundsBinding, in: 90...350, step: 1)
                    .tint(MTTheme.volt)
            }
        }
    }

    /// Lets the slider operate in pounds while `draft.weightKg` keeps metric storage.
    private var weightPoundsBinding: Binding<Double> {
        Binding(
            get: { Units.pounds(fromKg: draft.weightKg) },
            set: { draft.weightKg = Units.kg(fromPounds: $0) }
        )
    }

    private var goalSection: some View {
        section("Goals") {
            sectionLabel("SELECT ALL THAT APPLY — FIRST PICK LEADS")
            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                let isPrimary = draft.goal == goal
                let title = isPrimary && !draft.secondaryGoals.isEmpty
                    ? goal.displayName + "  ·  Primary" : goal.displayName
                selectableRow(title: title,
                              isSelected: isPrimary || draft.secondaryGoals.contains(goal)) {
                    toggleGoal(goal)
                }
            }
        }
    }

    /// Same semantics as onboarding: first pick is primary (drives targets), tapping the
    /// primary promotes the next selected goal, and at least one goal always remains.
    private func toggleGoal(_ goal: FitnessGoal) {
        if draft.goal == goal {
            if let promoted = FitnessGoal.allCases.first(where: { draft.secondaryGoals.contains($0) }) {
                draft.secondaryGoals.remove(promoted)
                draft.goal = promoted
            }
        } else if draft.secondaryGoals.contains(goal) {
            draft.secondaryGoals.remove(goal)
        } else {
            draft.secondaryGoals.insert(goal)
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
            sectionLabel("ROUTE AROUND")
            FlowChips(items: InjuryFlag.allCases.map { ($0.displayName, draft.injuries.contains($0)) }) { index in
                let flag = InjuryFlag.allCases[index]
                if draft.injuries.contains(flag) { draft.injuries.remove(flag) }
                else { draft.injuries.insert(flag) }
            }

            sectionLabel("STRENGTHEN · FIRM · FOCUS")
                .padding(.top, 6)
            FlowChips(items: focusableGroups.map { ($0.displayName, draft.focusAreas.contains($0)) }) { index in
                let group = focusableGroups[index]
                if draft.focusAreas.contains(group) { draft.focusAreas.remove(group) }
                else { draft.focusAreas.insert(group) }
            }

            MTSecondaryButton(title: "Open body map", systemImage: "figure.arms.open") {
                showBodyMap = true
            }
            .padding(.top, 4)

            if !draft.customFlags.isEmpty {
                sectionLabel("FLAGGED")
                    .padding(.top, 6)
                FlowChips(items: draft.customFlags.map { ($0, true) }) { index in
                    draft.customFlags.remove(at: index)
                }
            }

            Toggle(isOn: $draft.includeMobilityWork) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mobility work")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("Add PT-style warm-up & cooldown to every session")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                }
            }
            .tint(MTTheme.volt)
            .padding(.top, 8)
        }
    }

    private var dietSection: some View {
        section("Diet") {
            ForEach(DietaryPreference.allCases, id: \.self) { preference in
                selectableRow(title: preference.displayName,
                              isSelected: draft.dietaryPreference == preference) {
                    draft.dietaryPreference = preference
                }
            }
            sectionLabel("ALLERGIES")
                .padding(.top, 6)
            FlowChips(items: FoodAllergen.allCases.map { ($0.displayName, draft.allergies.contains($0)) }) { index in
                let allergen = FoodAllergen.allCases[index]
                if draft.allergies.contains(allergen) { draft.allergies.remove(allergen) }
                else { draft.allergies.insert(allergen) }
            }
            Text("Meal-prep plans strictly exclude flagged foods.")
                .font(.system(size: 12))
                .foregroundStyle(MTTheme.textTertiary)
        }
    }

    private var equipmentSection: some View {
        section("Equipment") {
            FlowChips(items: Equipment.allCases.map { ($0.displayName, draft.equipment.contains($0)) }) { index in
                let equipment = Equipment.allCases[index]
                if draft.equipment.contains(equipment) { draft.equipment.remove(equipment) }
                else { draft.equipment.insert(equipment) }
            }

            sectionLabel("CUSTOM EQUIPMENT")
                .padding(.top, 6)
            HStack(spacing: 10) {
                TextField("e.g. Cable machine", text: $customEquipmentText)
                    .font(.system(size: 15))
                    .foregroundStyle(MTTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
                Button {
                    addCustomEquipment()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .frame(width: 40, height: 40)
                        .background(MTTheme.volt, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(customEquipmentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if !draft.customEquipment.isEmpty {
                FlowChips(items: draft.customEquipment.map { ($0, true) }) { index in
                    draft.customEquipment.remove(at: index)
                }
            }
        }
    }

    private func addCustomEquipment() {
        let trimmed = customEquipmentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !draft.customEquipment.contains(trimmed) else { return }
        Haptics.tap()
        draft.customEquipment.append(trimmed)
        customEquipmentText = ""
    }

    private var scheduleSection: some View {
        section("Schedule") {
            Picker("Anchor", selection: $draft.scheduleAnchor) {
                ForEach(ScheduleAnchor.allCases, id: \.self) { anchor in
                    Text(anchor.displayName).tag(anchor)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: draft.scheduleAnchor) { _, _ in syncSchedule() }

            if draft.scheduleAnchor == .daysPerWeek {
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
                    .onChange(of: draft.workoutDaysPerWeek) { _, _ in syncSchedule() }
                }
                recommendationChip(text: "Recommended: \(draft.sessionMinutes) min session")
            } else {
                HStack(spacing: 8) {
                    ForEach([15, 30, 45, 60, 90], id: \.self) { minutes in
                        Button {
                            Haptics.tap()
                            draft.sessionMinutes = minutes
                            syncSchedule()
                        } label: {
                            MTChip(text: "\(minutes)m", isActive: draft.sessionMinutes == minutes)
                        }
                        .buttonStyle(.plain)
                    }
                }
                recommendationChip(text: "Recommended: \(draft.workoutDaysPerWeek) days/week")
            }

            Text("Based on your profile we suggest \(recommendation.days) days · \(recommendation.minutes) min")
                .font(.system(size: 12))
                .foregroundStyle(MTTheme.textTertiary)
        }
    }

    private func syncSchedule() {
        switch draft.scheduleAnchor {
        case .daysPerWeek:
            draft.sessionMinutes = ScheduleRecommender.recommendedMinutes(forDays: draft.workoutDaysPerWeek, profile: draft)
        case .sessionLength:
            draft.workoutDaysPerWeek = ScheduleRecommender.recommendedDays(forMinutes: draft.sessionMinutes, profile: draft)
        }
    }

    private func recommendationChip(text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Color.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(MTTheme.volt)
        .clipShape(Capsule())
    }

    private var macrosSection: some View {
        section("Macros") {
            Text("Leave blank for automatic targets")
                .font(.system(size: 12))
                .foregroundStyle(MTTheme.textTertiary)
            macroOverrideRow(label: "Protein (g)", tint: MTTheme.protein, text: optionalIntBinding(\.customProteinG))
            macroOverrideRow(label: "Carbs (g)", tint: MTTheme.carbs, text: optionalIntBinding(\.customCarbsG))
            macroOverrideRow(label: "Fat (g)", tint: MTTheme.fat, text: optionalIntBinding(\.customFatG))
        }
    }

    private func macroOverrideRow(label: String, tint: Color, text: Binding<String>) -> some View {
        HStack {
            Circle().fill(tint).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(MTTheme.textSecondary)
            Spacer()
            TextField("Auto", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
                .frame(width: 70)
        }
    }

    /// Bridges an optional-Int profile field to a text field: empty text means "automatic".
    private func optionalIntBinding(_ keyPath: WritableKeyPath<FitnessProfile, Int?>) -> Binding<String> {
        Binding(
            get: { draft[keyPath: keyPath].map(String.init) ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                draft[keyPath: keyPath] = trimmed.isEmpty ? nil : Int(trimmed)
            }
        )
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

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(MTTheme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
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
