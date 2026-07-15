import SwiftUI
import SwiftData

@main
struct MetabolicApp: App {
    @State private var appState = AppState()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var healthKitService = HealthKitService()
    @State private var smartScale = SmartScaleService()

    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self,
                ScanRecord.self, CustomWorkout.self, PersonalBest.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    RootTabView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                } else {
                    OnboardingFlowView()
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: appState.hasCompletedOnboarding)
            .environment(appState)
            .environment(subscriptionManager)
            .environment(healthKitService)
            .environment(smartScale)
            .modelContainer(modelContainer)
            .preferredColorScheme(nil)
            .task {
                await subscriptionManager.configure()
                DemoDataSeeder.seedIfNeeded(context: modelContainer.mainContext, appState: appState)
            }
        }
    }
}
