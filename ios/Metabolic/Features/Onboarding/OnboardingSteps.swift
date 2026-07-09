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
                    .foregroundStyle(MTTheme.volt)
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
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            OnboardingStepHeader(title: "Body", subtitle: "Height and weight shape your targets.")

            VStack(spacing: 8) {
                Text(String(format: "%.0f cm", draft.heightCm))
                    .font(MTTheme.numberFont(size: 44))
                    .foregroundStyle(MTTheme.textPrimary)
                Slider(value: $draft.heightCm, in: 140...210, step: 1)
                    .tint(MTTheme.volt)
            }

            VStack(spacing: 8) {
                Text(String(format: "%.1f kg", draft.weightKg))
                    .font(MTTheme.numberFont(size: 44))
                    .foregroundStyle(MTTheme.textPrimary)
                Slider(value: $draft.weightKg, in: 40...160, step: 0.5)
                    .tint(MTTheme.volt)
            }

            Spacer()
            MTPrimaryButton(title: "Continue") { onNext() }
        }
        .padding(20)
    }
}

// MARK: - Step 4: Goal

struct OnboardingGoalStep: View {
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            OnboardingStepHeader(title: "Goal", subtitle: "What are we optimizing for?")

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

    private func symbol(for goal: FitnessGoal) -> String {
        switch goal {
        case .loseFat: return "flame.fill"
        case .maintain: return "equal.circle.fill"
        case .gainMuscle: return "dumbbell.fill"
        case .improveEndurance: return "heart.fill"
        }
    }

    private func description(for goal: FitnessGoal) -> String {
        switch goal {
        case .loseFat: return "Trim down with a calorie deficit."
        case .maintain: return "Hold steady where you are."
        case .gainMuscle: return "Build strength and size."
        case .improveEndurance: return "Go longer, recover faster."
        }
    }

    private func goalCard(_ goal: FitnessGoal) -> some View {
        let isSelected = draft.goal == goal
        return Button {
            Haptics.tap()
            draft.goal = goal
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(MTTheme.voltDim).frame(width: 44, height: 44)
                    Image(systemName: symbol(for: goal))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text(description(for: goal))
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

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        VStack(spacing: 24) {
            OnboardingStepHeader(title: "Health flags", subtitle: "We'll route around anything that hurts.")

            LazyVGrid(columns: columns, spacing: 10) {
                noneChip
                ForEach(InjuryFlag.allCases, id: \.self) { flag in
                    chip(flag)
                }
            }

            Spacer()
            MTPrimaryButton(title: "Continue") { onNext() }
        }
        .padding(20)
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

    private func chip(_ flag: InjuryFlag) -> some View {
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
}

// MARK: - Step 8: Equipment & schedule

struct OnboardingEquipmentScheduleStep: View {
    @Binding var draft: FitnessProfile
    let onNext: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 10)]
    private let minuteOptions = [15, 30, 45, 60, 90]

    var body: some View {
        VStack(spacing: 24) {
            OnboardingStepHeader(title: "Equipment & schedule", subtitle: "What you've got, and how often.")

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Equipment.allCases, id: \.self) { equipment in
                    chip(equipment)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("DAYS PER WEEK")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                Picker("Days", selection: $draft.workoutDaysPerWeek) {
                    ForEach(2...6, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SESSION LENGTH")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                HStack(spacing: 8) {
                    ForEach(minuteOptions, id: \.self) { minutes in
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

            Spacer()
            MTPrimaryButton(title: "Continue") {
                if draft.equipment.isEmpty {
                    draft.equipment = [.none]
                }
                onNext()
            }
        }
        .padding(20)
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
                                .foregroundStyle(MTTheme.volt)
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
