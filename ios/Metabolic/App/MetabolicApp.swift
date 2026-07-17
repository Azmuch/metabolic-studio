import SwiftUI
import SwiftData

@main
struct MetabolicApp: App {
    @State private var appState = AppState()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var healthKitService = HealthKitService()
    @State private var smartScale = SmartScaleService()
    @State private var importedWorkoutName: String?

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
            .preferredColorScheme(appState.appearanceMode.colorScheme)
            .task {
                await subscriptionManager.configure()
                DemoDataSeeder.seedIfNeeded(context: modelContainer.mainContext, appState: appState)
            }
            // A shared .metabolicworkout file tapped in Messages/Mail/Files lands here.
            .onOpenURL { url in
                guard let workout = WorkoutShare.importWorkout(from: url) else { return }
                modelContainer.mainContext.insert(workout)
                appState.selectedTab = .training
                Haptics.success()
                importedWorkoutName = workout.name
            }
            .alert(
                "Workout imported",
                isPresented: Binding(get: { importedWorkoutName != nil },
                                     set: { if !$0 { importedWorkoutName = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("“\(importedWorkoutName ?? "")” was added to My Workouts.")
            }
        }
    }
}
