import SwiftUI
import SwiftData
import MetabolicCore

/// Full water tracker: an animated glass hero scaled to today's progress, quick-add chips,
/// and today's individual entries with delete.
struct WaterDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterEntry.date, order: .reverse) private var allWater: [WaterEntry]

    @State private var bounce = false

    private var todayEntries: [WaterEntry] {
        allWater.filter { Calendar.current.isDate($0.date, inSameDayAs: .now) }
    }

    private var totalML: Int { todayEntries.reduce(0) { $0 + $1.amountML } }
    private var goalML: Int { appState.targets.waterML }
    private var progress: Double { goalML > 0 ? Double(totalML) / Double(goalML) : 0 }
    private var remainingML: Int { max(goalML - totalML, 0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                hero
                quickAddRow
                entriesList
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(MTBackground())
        .navigationTitle("Water")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(MTTheme.surface2)
                    .frame(width: 140, height: 260)

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MTTheme.water.opacity(0.55), MTTheme.water],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 140, height: 260 * min(max(progress, 0), 1))
                    .animation(.spring(response: 0.55, dampingFraction: 0.75), value: progress)

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(MTTheme.stroke, lineWidth: 1)
                    .frame(width: 140, height: 260)
            }
            .scaleEffect(bounce ? 1.03 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: bounce)

            VStack(spacing: 4) {
                Text(Units.waterAmountString(ml: remainingML, system: appState.unitSystem))
                    .font(MTTheme.numberFont(size: 32))
                    .foregroundStyle(MTTheme.textPrimary)
                Text("remaining of \(Units.waterGoalString(ml: goalML, system: appState.unitSystem)) goal")
                    .font(.system(size: 13))
                    .foregroundStyle(MTTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var quickAddRow: some View {
        HStack(spacing: 10) {
            ForEach(Units.waterQuickAdds(system: appState.unitSystem), id: \.ml) { preset in
                Button {
                    addWater(preset.ml)
                } label: {
                    Text("+\(preset.label)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MTTheme.surface2)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var entriesList: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("TODAY'S ENTRIES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)

                if todayEntries.isEmpty {
                    Text("No water logged yet today.")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(todayEntries) { entry in
                            waterRow(entry)
                        }
                    }
                }
            }
        }
    }

    private func waterRow(_ entry: WaterEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "drop.fill")
                .font(.system(size: 13))
                .foregroundStyle(MTTheme.water)
            Text(entry.date, style: .time)
                .font(.system(size: 14))
                .foregroundStyle(MTTheme.textPrimary)
            Spacer()
            Text(Units.waterAmountString(ml: entry.amountML, system: appState.unitSystem))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MTTheme.textSecondary)
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    modelContext.delete(entry)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(MTTheme.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private func addWater(_ amount: Int) {
        Haptics.success()
        bounce = true
        modelContext.insert(WaterEntry(date: .now, amountML: amount))
        Task { await healthKit.saveWater(ml: amount, date: .now) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            bounce = false
        }
    }
}

#Preview {
    NavigationStack {
        WaterDetailView()
    }
    .environment(AppState())
    .environment(HealthKitService())
    .modelContainer(
        for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
        inMemory: true
    )
}
