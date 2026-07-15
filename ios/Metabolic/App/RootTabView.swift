import SwiftUI

/// The five-tab shell: Today, Nutrition, Training, Scan, You.
struct RootTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "circle.grid.2x2.fill") }
                .tag(AppTab.today)

            NutritionView()
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }
                .tag(AppTab.nutrition)

            TrainingView()
                .tabItem { Label("Training", systemImage: "figure.strengthtraining.traditional") }
                .tag(AppTab.training)

            ScanTabView()
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
                .tag(AppTab.scan)

            YouView()
                .tabItem { Label("You", systemImage: "person.fill") }
                .tag(AppTab.you)
        }
        .tint(MTTheme.volt)
    }
}

#Preview {
    RootTabView()
        .environment(AppState())
        .environment(SubscriptionManager())
        .environment(HealthKitService())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self, CustomWorkout.self, PersonalBest.self],
            inMemory: true
        )
}
