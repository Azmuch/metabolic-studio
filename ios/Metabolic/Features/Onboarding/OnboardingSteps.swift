import SwiftUI
import MetabolicCore

/// Shared "title + subtitle" header used at the top of every onboarding step.
fileprivate struct OnboardingStepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(MTTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(MTTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Small tracked-caps overline used above a grouped section within a step.
fileprivate struct OnboardingSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(MTTheme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Volt "recommended" pill shown next to auto-computed schedule values.
fileprivate struct OnboardingRecommendationChip: View {
    let text: String

    var body: some View {
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
}

// MARK: - Step 1: Welcome

struct OnboardingWelcomeStep: View {
    let onNext: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                MTRing(progress: 0.7, lineWidth: 10)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulse ? 1.06 : 0.94)
                    .opacity(pulse ? 1 : 0.7)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(MTTheme.accentText)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }

            VStack(spacing: 10) {
                Text("Metabolic")
                    .font(MTTheme.numberFont(size: 40))
                    .foregroundStyle(MTTheme.textPrimary)
                Text("Train smarter. Eat better. See it add up.")
                    .font(.system(size: 15))
                    .foregroundStyle(MTTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            MTPrimaryButton(title: "Start") { onNext() }
        }
        .padding(20)
    }
}

// MARK: - Step 2: About you

struct OnboardingAboutYouStep: View {
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            OnboardingStepHeader(title: "About you", subtitle: "So we can dial in your numbers.")

            Picker("Age", selection: $draft.age) {
                ForEach(14...90, id: \.self) { age in
                    Text("\(age)").tag(age)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 160)

            Picker("Sex", selection: $draft.sex) {
                ForEach(BiologicalSex.allCases, id: \.self) { sex in
                    Text(sex == .male ? "Male" : "Female").tag(sex)
                }
            }
            .pickerStyle(.segmented)

            Spacer()
            MTPrimaryButton(title: "Continue") { onNext() }
        }
        .padding(20)
    }
}

// MARK: - Step 3: Body

struct OnboardingBodyStep: View {
    @Environment(AppState.self) private var appState
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 28) {
            OnboardingStepHeader(title: "Body", subtitle: "Height and weight shape your targets.")

            Picker("Units", selection: $appState.unitSystem) {
                ForEach(UnitSystem.allCases, id: \.self) { system in
                    Text(system == .metric ? "Metric" : "US").tag(system)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 8) {
                Text(Units.heightString(cm: draft.heightCm, system: appState.unitSystem))
                    .font(MTTheme.numberFont(size: 44))
                    .foregroundStyle(MTTheme.textPrimary)
                Slider(value: $draft.heightCm, in: 140...210, step: 1)
                    .tint(MTTheme.volt)
            }

            VStack(spacing: 8) {
                Text(Units.weightString(kg: draft.weightKg, system: appState.unitSystem))
                    .font(MTTheme.numberFont(size: 44))
                    .foregroundStyle(MTTheme.textPrimary)
                if appState.unitSystem == .metric {
                    Slider(value: $draft.weightKg, in: 40...160, step: 0.5)
                        .tint(MTTheme.volt)
                } else {
                    Slider(value: weightPoundsBinding, in: 90...350, step: 1)
                        .tint(MTTheme.volt)
                }
            }

            Spacer()
            MTPrimaryButton(title: "Continue") { onNext() }
        }
        .padding(20)
    }

    /// Lets the slider operate in pounds while `draft.weightKg` keeps metric storage.
    private var weightPoundsBinding: Binding<Double> {
        Binding(
            get: { Units.pounds(fromKg: draft.weightKg) },
            set: { draft.weightKg = Units.kg(fromPounds: $0) }
        )
    }
}

// MARK: - Step 4: Goal

struct OnboardingGoalStep: View {
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            OnboardingStepHeader(title: "Goals",
                                 subtitle: "Pick everything that applies — your first pick leads the plan.")

            VStack(spacing: 12) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    goalCard(goal)
                }
            }

            Spacer()
            MTPrimaryButton(title: "Continue") { onNext() }
        }
        .padding(20)
    }

    /// Selecting is additive: the first pick becomes the primary goal (drives calorie/macro
    /// math), later picks are secondary. Tapping the primary hands leadership to the next
    /// selected goal — the profile always keeps at least one.
    private func toggleGoal(_ goal: FitnessGoal) {
        Haptics.tap()
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

    private func symbol(for goal: FitnessGoal) -> String {
        switch goal {
        case .loseFat: return "flame.fill"
        case .maintain: return "equal.circle.fill"
        case .gainMuscle: return "dumbbell.fill"
        case .improveEndurance: return "heart.fill"
        case .improveMobility: return "figure.flexibility"
        }
    }

    private func description(for goal: FitnessGoal) -> String {
        switch goal {
        case .loseFat: return "Trim down with a calorie deficit."
        case .maintain: return "Hold steady where you are."
        case .gainMuscle: return "Build strength and size."
        case .improveEndurance: return "Go longer, recover faster."
        case .improveMobility: return "Move freely, stretch further, age well."
        }
    }

    private func goalCard(_ goal: FitnessGoal) -> some View {
        let isPrimary = draft.goal == goal
        let isSelected = isPrimary || draft.secondaryGoals.contains(goal)
        return Button {
            toggleGoal(goal)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(MTTheme.voltDim).frame(width: 44, height: 44)
                    Image(systemName: symbol(for: goal))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MTTheme.accentText)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(goal.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MTTheme.textPrimary)
                        if isPrimary && !draft.secondaryGoals.isEmpty {
                            Text("PRIMARY")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(MTTheme.volt, in: Capsule())
                        }
                    }
                    Text(description(for: goal))
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MTTheme.accentText)
                }
            }
            .padding(16)
            .background(isSelected ? MTTheme.voltDim : MTTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                    .stroke(isSelected ? MTTheme.volt : MTTheme.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 5: Lifestyle

struct OnboardingLifestyleStep: View {
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            OnboardingStepHeader(title: "Lifestyle", subtitle: "How active is your day-to-day?")

            VStack(spacing: 10) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    row(level)
                }
            }

            Spacer()
            MTPrimaryButton(title: "Continue") { onNext() }
        }
        .padding(20)
    }

    private func description(for level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "Desk job, little movement"
        case .light: return "Light exercise 1-3 days a week"
        case .moderate: return "Moderate exercise 3-5 days a week"
        case .active: return "Hard exercise 6-7 days a week"
        case .veryActive: return "Physical job or twice-a-day training"
        }
    }

    private func row(_ level: ActivityLevel) -> some View {
        let isSelected = draft.activityLevel == level
        return Button {
            Haptics.tap()
            draft.activityLevel = level
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(level.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text(description(for: level))
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? MTTheme.volt : MTTheme.stroke)
            }
            .padding(16)
            .background(isSelected ? MTTheme.voltDim : MTTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                    .stroke(isSelected ? MTTheme.volt : MTTheme.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 6: Experience

struct OnboardingExperienceStep: View {
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            OnboardingStepHeader(title: "Experience", subtitle: "We'll calibrate difficulty to match.")

            VStack(spacing: 12) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    card(level)
                }
            }

            Spacer()
            MTPrimaryButton(title: "Continue") { onNext() }
        }
        .padding(20)
    }

    private func description(for level: ExperienceLevel) -> String {
        switch level {
        case .beginner: return "New to structured training"
        case .intermediate: return "Consistent for 6+ months"
        case .advanced: return "Years of dedicated training"
        }
    }

    private func card(_ level: ExperienceLevel) -> some View {
        let isSelected = draft.experience == level
        return Button {
            Haptics.tap()
            draft.experience = level
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(level.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text(description(for: level))
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(isSelected ? MTTheme.voltDim : MTTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                    .stroke(isSelected ? MTTheme.volt : MTTheme.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 7: Health flags

struct OnboardingHealthFlagsStep: View {
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    @State private var showBodyMap = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    private var focusableGroups: [MuscleGroup] {
        MuscleGroup.allCases.filter { $0 != .fullBody && $0 != .cardio }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingStepHeader(title: "Health flags", subtitle: "We'll route around anything that hurts.")

                VStack(alignment: .leading, spacing: 10) {
                    OnboardingSectionLabel(text: "ROUTE AROUND")
                    LazyVGrid(columns: columns, spacing: 10) {
                        noneChip
                        ForEach(InjuryFlag.allCases, id: \.self) { flag in
                            injuryChip(flag)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    OnboardingSectionLabel(text: "STRENGTHEN · FIRM · FOCUS")
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(focusableGroups, id: \.self) { group in
                            focusChip(group)
                        }
                    }
                }

                MTSecondaryButton(title: "Open body map", systemImage: "figure.arms.open") {
                    showBodyMap = true
                }

                mobilityToggle

                disclaimer

                Spacer(minLength: 8)
                MTPrimaryButton(title: "Continue") { onNext() }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showBodyMap) {
            BodyMapView(selectedAreas: $draft.focusAreas, customFlags: $draft.customFlags)
        }
    }

    private var noneChip: some View {
        Button {
            Haptics.tap()
            draft.injuries = []
        } label: {
            MTChip(text: "None", isActive: draft.injuries.isEmpty)
        }
        .buttonStyle(.plain)
    }

    private func injuryChip(_ flag: InjuryFlag) -> some View {
        let isSelected = draft.injuries.contains(flag)
        return Button {
            Haptics.tap()
            if isSelected {
                draft.injuries.remove(flag)
            } else {
                draft.injuries.insert(flag)
            }
        } label: {
            MTChip(text: flag.displayName, isActive: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func focusChip(_ group: MuscleGroup) -> some View {
        let isSelected = draft.focusAreas.contains(group)
        return Button {
            Haptics.tap()
            if isSelected {
                draft.focusAreas.remove(group)
            } else {
                draft.focusAreas.insert(group)
            }
        } label: {
            MTChip(text: group.displayName, isActive: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var mobilityToggle: some View {
        MTCard {
            Toggle(isOn: $draft.includeMobilityWork) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Mobility work")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("Add PT-style warm-up & cooldown to every session")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                }
            }
            .tint(MTTheme.volt)
        }
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 11))
            Text("For pre-existing conditions — or any flagged area that has persisted 3 months or more — consult a physician or physical therapist before training it.")
                .font(.system(size: 11))
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(MTTheme.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Step 8: Equipment & schedule

struct OnboardingEquipmentScheduleStep: View {
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    @State private var customEquipmentText = ""

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 10)]
    private let customColumns = [GridItem(.adaptive(minimum: 110), spacing: 8)]
    private let minuteOptions = [15, 30, 45, 60, 90]

    private var recommendation: (days: Int, minutes: Int) {
        ScheduleRecommender.recommendation(for: draft)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingStepHeader(title: "Equipment & schedule", subtitle: "What you've got, and how often.")

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Equipment.allCases, id: \.self) { equipment in
                        chip(equipment)
                    }
                }

                customEquipmentSection

                scheduleSection

                Spacer(minLength: 8)
                MTPrimaryButton(title: "Continue") {
                    if draft.equipment.isEmpty {
                        draft.equipment = [.none]
                    }
                    onNext()
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .onAppear { syncSchedule() }
    }

    private func chip(_ equipment: Equipment) -> some View {
        let isSelected = draft.equipment.contains(equipment)
        return Button {
            Haptics.tap()
            if isSelected {
                draft.equipment.remove(equipment)
            } else {
                draft.equipment.insert(equipment)
            }
        } label: {
            MTChip(text: equipment.displayName, systemImage: equipment.symbolName, isActive: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var customEquipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            OnboardingSectionLabel(text: "CUSTOM EQUIPMENT")
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
                LazyVGrid(columns: customColumns, alignment: .leading, spacing: 8) {
                    ForEach(draft.customEquipment, id: \.self) { item in
                        Button {
                            Haptics.tap()
                            draft.customEquipment.removeAll { $0 == item }
                        } label: {
                            MTChip(text: item, systemImage: "xmark", isActive: true)
                        }
                        .buttonStyle(.plain)
                    }
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
        VStack(alignment: .leading, spacing: 16) {
            OnboardingSectionLabel(text: "SCHEDULE")

            Picker("Anchor", selection: $draft.scheduleAnchor) {
                ForEach(ScheduleAnchor.allCases, id: \.self) { anchor in
                    Text(anchor.displayName).tag(anchor)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: draft.scheduleAnchor) { _, _ in syncSchedule() }

            if draft.scheduleAnchor == .daysPerWeek {
                VStack(alignment: .leading, spacing: 8) {
                    OnboardingSectionLabel(text: "DAYS PER WEEK")
                    Picker("Days", selection: $draft.workoutDaysPerWeek) {
                        ForEach(2...6, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: draft.workoutDaysPerWeek) { _, _ in syncSchedule() }
                }
                OnboardingRecommendationChip(text: "Recommended: \(draft.sessionMinutes) min session")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    OnboardingSectionLabel(text: "SESSION LENGTH")
                    HStack(spacing: 8) {
                        ForEach(minuteOptions, id: \.self) { minutes in
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
                }
                OnboardingRecommendationChip(text: "Recommended: \(draft.workoutDaysPerWeek) days/week")
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
}

// MARK: - Step 9: Sync & build

struct OnboardingSyncBuildStep: View {
    @Binding var isBuilding: Bool
    let onConnectHealth: () async -> Void
    let onBuild: () async -> Void

    @State private var isConnecting = false
    @State private var isConnected = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                OnboardingStepHeader(title: "Sync & build", subtitle: "Last step — then we design your week.")

                MTCard {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(MTTheme.voltDim).frame(width: 48, height: 48)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(MTTheme.accentText)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Apple Health")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            Text(isConnected ? "Connected" : "Sync meals, water, and workouts")
                                .font(.system(size: 13))
                                .foregroundStyle(MTTheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                        connectControl
                    }
                }

                Spacer()

                MTPrimaryButton(title: "Build my plan", systemImage: "sparkles") {
                    Task { await onBuild() }
                }
                .disabled(isBuilding)
            }
            .padding(20)
            .opacity(isBuilding ? 0.15 : 1)

            if isBuilding {
                buildingOverlay
            }
        }
    }

    @ViewBuilder
    private var connectControl: some View {
        if isConnected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(MTTheme.success)
        } else {
            Button {
                Haptics.tap()
                isConnecting = true
                Task {
                    await onConnectHealth()
                    isConnecting = false
                    isConnected = true
                }
            } label: {
                Text(isConnecting ? "Connecting…" : "Connect")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(MTTheme.volt)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isConnecting)
        }
    }

    private var buildingOverlay: some View {
        VStack(spacing: 20) {
            MTRing(progress: 0.7, lineWidth: 10)
                .frame(width: 100, height: 100)
                .scaleEffect(pulse ? 1.08 : 0.92)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
            Text("Designing your week…")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
        }
    }
}
