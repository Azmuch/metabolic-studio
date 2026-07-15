import SwiftUI
import SwiftData
import MetabolicCore

/// "You" tab: profile header, quick stats, and entry points into profile editing,
/// Apple Health, membership, and settings.
struct YouView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    @Query private var foods: [FoodEntry]
    @Query private var workouts: [WorkoutLog]

    @State private var showWeightSheet = false
    @State private var showPaywall = false
    @State private var restingHR: Double?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    headerCard
                    linksCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
            .background(MTBackground().ignoresSafeArea())
            .navigationTitle("You")
            .sheet(isPresented: $showWeightSheet) { WeightLogSheet() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .task {
                restingHR = await healthKit.readRestingHeartRate()
            }
        }
    }

    private var currentWeight: Double {
        weights.first?.weightKg ?? appState.profile.weightKg
    }

    private var weightDisplayValue: String {
        switch appState.unitSystem {
        case .metric: return String(format: "%.1f", currentWeight)
        case .imperial: return String(format: "%.1f", Units.pounds(fromKg: currentWeight))
        }
    }

    private var weightDisplayUnit: String {
        appState.unitSystem == .metric ? "kg" : "lb"
    }

    private var restingHRValue: String {
        guard let restingHR else { return "—" }
        return "\(Int(restingHR.rounded()))"
    }

    private var streak: Int {
        StreakCalculator.currentStreak(
            loggedDays: Set(foods.map(\.date)),
            today: .now, calendar: .current)
    }

    private var workoutsThisWeek: Int {
        guard let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start else { return 0 }
        return workouts.filter { $0.date >= weekStart }.count
    }

    private var headerCard: some View {
        MTCard {
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(MTTheme.voltDim).frame(width: 56, height: 56)
                        Image(systemName: "figure.run")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(MTTheme.volt)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your profile")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(MTTheme.textPrimary)
                        MTChip(text: subscriptionManager.tier.displayName,
                               systemImage: subscriptionManager.tier > .free ? "crown.fill" : nil,
                               isActive: subscriptionManager.tier > .free)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 0) {
                    statColumn(value: weightDisplayValue, unit: weightDisplayUnit,
                               label: "Weight", action: { showWeightSheet = true })
                    divider
                    statColumn(value: "\(streak)", unit: streak == 1 ? "day" : "days",
                               label: "Streak", action: nil)
                    divider
                    statColumn(value: "\(workoutsThisWeek)", unit: "this week",
                               label: "Workouts", action: nil)
                    divider
                    statColumn(value: restingHRValue, unit: "bpm",
                               label: "Resting HR", action: nil)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var divider: some View {
        Rectangle().fill(MTTheme.stroke).frame(width: 1, height: 40)
    }

    private func statColumn(value: String, unit: String, label: String,
                            action: (() -> Void)?) -> some View {
        Button {
            if let action {
                Haptics.tap()
                action()
            }
        } label: {
            VStack(spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(MTTheme.numberFont(size: 22))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(MTTheme.textTertiary)
                }
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(MTTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private var linksCard: some View {
        MTCard {
            VStack(spacing: 0) {
                NavigationLink { ProfileEditorView() } label: {
                    linkRow(symbol: "person.text.rectangle.fill", title: "Edit profile",
                            caption: profileSummary)
                }
                rowDivider
                NavigationLink { AchievementsView() } label: {
                    linkRow(symbol: "trophy.fill", title: "Achievements",
                            caption: "Badges you've unlocked")
                }
                rowDivider
                linkRow(symbol: "target", title: "Daily targets", caption: targetsSummary)
                rowDivider
                Button {
                    Haptics.tap()
                    Task { await healthKit.requestAuthorization() }
                } label: {
                    linkRow(symbol: "heart.fill", title: "Apple Health",
                            caption: healthKit.isAuthorized ? "Connected" : "Tap to connect")
                }
                rowDivider
                Button {
                    Haptics.tap()
                    showPaywall = true
                } label: {
                    linkRow(symbol: "crown.fill", title: "Membership",
                            caption: subscriptionManager.tier.displayName)
                }
                rowDivider
                NavigationLink { PacksView() } label: {
                    linkRow(symbol: "puzzlepiece.extension.fill", title: "Expansion Packs",
                            caption: "Yoga · Pilates · HIIT · Kickboxing")
                }
                rowDivider
                NavigationLink { SettingsView() } label: {
                    linkRow(symbol: "gearshape.fill", title: "Settings",
                            caption: appState.demoMode ? "Demo mode on" : "API key, export, about")
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Rectangle().fill(MTTheme.stroke).frame(height: 1).padding(.leading, 48)
    }

    private var profileSummary: String {
        let p = appState.profile
        return "\(p.age)y · \(Int(p.heightCm)) cm · \(p.goal.displayName)"
    }

    private var targetsSummary: String {
        let t = appState.targets
        return "\(t.calories) kcal · \(t.proteinG) g protein · \(String(format: "%.1f", Double(t.waterML) / 1000)) L water"
    }

    private func linkRow(symbol: String, title: String, caption: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MTTheme.volt)
                .frame(width: 36, height: 36)
                .background(MTTheme.voltDim, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                Text(caption)
                    .font(.system(size: 12))
                    .foregroundStyle(MTTheme.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MTTheme.textTertiary)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

/// Quick weight logging sheet: one decimal field, saves a `WeightEntry` and syncs to Health.
private struct WeightLogSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @FocusState private var focused: Bool

    private var unitLabel: String { appState.unitSystem == .metric ? "kg" : "lb" }

    var body: some View {
        VStack(spacing: 24) {
            MTSheetHeader(title: "Log weight")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0.0", text: $text)
                    .keyboardType(.decimalPad)
                    .focused($focused)
                    .font(MTTheme.numberFont(size: 44))
                    .foregroundStyle(MTTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize()
                Text(unitLabel)
                    .font(.system(size: 17))
                    .foregroundStyle(MTTheme.textSecondary)
            }

            MTPrimaryButton(title: "Save") {
                save()
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 12)
        .background(MTBackground().ignoresSafeArea())
        .presentationDetents([.height(280)])
        .onAppear { focused = true }
    }

    /// Parses the entered value in the user's display unit, converts to kg for storage,
    /// and validates against a sane human-weight range (25...350 kg).
    private func save() {
        guard let entered = Double(text.replacingOccurrences(of: ",", with: ".")) else {
            Haptics.warning()
            return
        }
        let kgValue = appState.unitSystem == .metric ? entered : Units.kg(fromPounds: entered)
        guard (25...350).contains(kgValue) else {
            Haptics.warning()
            return
        }
        modelContext.insert(WeightEntry(date: .now, weightKg: kgValue))
        var profile = appState.profile
        profile.weightKg = kgValue
        appState.profile = profile
        Haptics.success()
        dismiss()
    }
}

#Preview {
    YouView()
        .environment(AppState())
        .environment(SubscriptionManager())
        .environment(HealthKitService())
        .modelContainer(for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self,
                              WeightEntry.self, ScanRecord.self], inMemory: true)
}
