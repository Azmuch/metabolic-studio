import SwiftUI
import MetabolicCore

/// Nine-step onboarding: welcome → profile building → Apple Health sync → plan generation.
/// Collects a `FitnessProfile` draft and hands it to `AppState.completeOnboarding(with:)`.
struct OnboardingFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthKitService.self) private var healthKit

    @State private var step = 0
    @State private var draft = FitnessProfile.default
    @State private var isBuilding = false

    private let stepCount = 9

    var body: some View {
        VStack(spacing: 0) {
            header

            ZStack {
                currentStep
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)))
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: step)
        }
        .background(MTTheme.bg.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button {
                Haptics.tap()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    step = max(0, step - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MTTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(MTTheme.surface2, in: Circle())
            }
            .opacity(step > 0 && !isBuilding ? 1 : 0)
            .disabled(step == 0 || isBuilding)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(MTTheme.stroke)
                    Capsule()
                        .fill(MTTheme.volt)
                        .frame(width: geo.size.width * Double(step + 1) / Double(stepCount))
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: step)
                }
            }
            .frame(height: 5)

            Text("\(step + 1)/\(stepCount)")
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(MTTheme.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var currentStep: some View {
        switch step {
        case 0: OnboardingWelcomeStep(onNext: advance)
        case 1: OnboardingAboutYouStep(draft: $draft, onNext: advance)
        case 2: OnboardingBodyStep(draft: $draft, onNext: advance)
        case 3: OnboardingGoalStep(draft: $draft, onNext: advance)
        case 4: OnboardingLifestyleStep(draft: $draft, onNext: advance)
        case 5: OnboardingExperienceStep(draft: $draft, onNext: advance)
        case 6: OnboardingHealthFlagsStep(draft: $draft, onNext: advance)
        case 7: OnboardingEquipmentScheduleStep(draft: $draft, onNext: advance)
        default:
            OnboardingSyncBuildStep(
                isBuilding: $isBuilding,
                onConnectHealth: { await healthKit.requestAuthorization() },
                onBuild: finish)
        }
    }

    private func advance() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            step = min(stepCount - 1, step + 1)
        }
    }

    private func finish() async {
        if draft.equipment.isEmpty { draft.equipment = [Equipment.none] }
        withAnimation(.easeInOut(duration: 0.25)) { isBuilding = true }
        try? await Task.sleep(for: .seconds(0.8))
        Haptics.success()
        appState.completeOnboarding(with: draft)
    }
}

#Preview {
    OnboardingFlowView()
        .environment(AppState())
        .environment(HealthKitService())
}
