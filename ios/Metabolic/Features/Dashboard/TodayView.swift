import SwiftUI

/// The Today dashboard: a greeting hero, then the user's customizable stack of widgets.
struct TodayView: View {
    @Environment(AppState.self) private var appState
    @State private var showEditSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    ForEach(appState.dashboardLayout.filter(\.isVisible)) { item in
                        widget(for: item.kind)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(MTTheme.bg)
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEditSheet) {
                DashboardEditSheet()
            }
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: .now)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(MTTheme.textSecondary)
                Text("let's move.")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(MTTheme.textPrimary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 12) {
                Button {
                    Haptics.tap()
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(MTTheme.surface2)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                MTChip(text: dateString, systemImage: "calendar")
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func widget(for kind: DashboardWidgetKind) -> some View {
        switch kind {
        case .calorieRing: CalorieRingWidget()
        case .macros: MacrosWidget()
        case .water: WaterWidget()
        case .todayWorkout: TodayWorkoutWidget()
        case .streak: StreakWidget()
        case .weightTrend: WeightTrendWidget()
        case .scanShortcut: ScanShortcutWidget()
        }
    }
}

#Preview {
    TodayView()
        .environment(AppState())
        .environment(SubscriptionManager())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
            inMemory: true
        )
}
