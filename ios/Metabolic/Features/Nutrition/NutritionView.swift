import SwiftUI
import SwiftData
import MetabolicCore

/// The Nutrition tab root: a day-scoped food diary grouped by meal, a calorie/macro summary,
/// and a water strip that opens the full water tracker.
struct NutritionView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    // Day-scoped filtering happens in memory since `selectedDate` is `@State`-driven and
    // can't be expressed in a `#Predicate`.
    @Query private var allFoodEntries: [FoodEntry]
    @Query private var allWaterEntries: [WaterEntry]

    @State private var selectedDate: Date = .now
    @State private var addFoodMealType: MealType?
    @State private var showWaterDetail = false
    @State private var showMealPrep = false
    @State private var showScaleSheet = false

    private var calendar: Calendar { .current }

    private var dayEntries: [FoodEntry] {
        allFoodEntries
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date < $1.date }
    }

    private var dayWater: [WaterEntry] {
        allWaterEntries.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var isToday: Bool { calendar.isDate(selectedDate, inSameDayAs: .now) }

    private var eaten: Int { Int(dayEntries.reduce(0) { $0 + $1.calories }) }
    private var target: Int { appState.targets.calories }
    private var remaining: Int { max(target - eaten, 0) }
    private var progress: Double { target > 0 ? Double(eaten) / Double(target) : 0 }

    private var proteinTotal: Int { Int(dayEntries.reduce(0) { $0 + $1.proteinG }) }
    private var carbsTotal: Int { Int(dayEntries.reduce(0) { $0 + $1.carbsG }) }
    private var fatTotal: Int { Int(dayEntries.reduce(0) { $0 + $1.fatG }) }

    private var waterTotalML: Int { dayWater.reduce(0) { $0 + $1.amountML } }
    private var waterTargetML: Int { appState.targets.waterML }
    private var waterProgress: Double { waterTargetML > 0 ? Double(waterTotalML) / Double(waterTargetML) : 0 }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    dayNavigator
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 0, trailing: 20))
                    summaryCard
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20))
                    mealPrepCard
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20))
                }

                ForEach(MealType.allCases, id: \.self) { mealType in
                    Section {
                        let entries = mealEntries(mealType)
                        if entries.isEmpty {
                            Text("Nothing logged yet.")
                                .font(.system(size: 13))
                                .foregroundStyle(MTTheme.textTertiary)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(entries) { entry in
                                foodRow(entry)
                                    .listRowBackground(MTTheme.surface)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            delete(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    } header: {
                        mealHeader(mealType)
                    }
                }

                Section {
                    waterCard
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 20, trailing: 20))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(MTBackground())
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showScaleSheet = true
                    } label: {
                        Image(systemName: "scalemass.fill")
                            .symbolEffect(.pulse)
                            .phaseAnimator([false, true]) { content, breathe in
                                content.scaleEffect(breathe ? 1.1 : 1.0)
                            } animation: { _ in
                                .easeInOut(duration: 1.1)
                            }
                    }
                    .foregroundStyle(MTTheme.accentText)
                }
            }
            .navigationDestination(isPresented: $showWaterDetail) {
                WaterDetailView()
            }
            .navigationDestination(isPresented: $showMealPrep) {
                MealPrepView()
            }
            .sheet(isPresented: Binding(
                get: { addFoodMealType != nil },
                set: { isPresented in if !isPresented { addFoodMealType = nil } }
            )) {
                if let addFoodMealType {
                    AddFoodSheet(mealType: addFoodMealType)
                }
            }
            .sheet(isPresented: $showScaleSheet) {
                SmartScaleSheet()
            }
        }
    }

    // MARK: - Day navigator

    private var dayNavigator: some View {
        HStack {
            Button {
                Haptics.tap()
                changeDay(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(MTTheme.surface2)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(dayLabel)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)

            Spacer()

            Button {
                Haptics.tap()
                changeDay(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isToday ? MTTheme.textTertiary : MTTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(MTTheme.surface2)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isToday)
        }
    }

    private var dayLabel: String {
        if isToday { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    private func changeDay(by delta: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: delta, to: selectedDate) else { return }
        if calendar.compare(newDate, to: .now, toGranularity: .day) == .orderedDescending { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            selectedDate = newDate
        }
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("CALORIES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(remaining)")
                        .font(MTTheme.numberFont(size: 32))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("kcal left")
                        .font(.system(size: 14))
                        .foregroundStyle(MTTheme.textSecondary)
                    Spacer()
                    Text("\(eaten) / \(target)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MTTheme.textSecondary)
                }

                MTProgressBar(progress: progress, tint: eaten > target ? MTTheme.danger : MTTheme.volt)

                HStack(spacing: 16) {
                    macroMiniBar("Protein", proteinTotal, appState.targets.proteinG, MTTheme.protein)
                    macroMiniBar("Carbs", carbsTotal, appState.targets.carbsG, MTTheme.carbs)
                    macroMiniBar("Fat", fatTotal, appState.targets.fatG, MTTheme.fat)
                }
            }
        }
    }

    private func macroMiniBar(_ label: String, _ value: Int, _ target: Int, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(value)g")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(MTTheme.textSecondary)
            MTProgressBar(progress: target > 0 ? Double(value) / Double(target) : 0, tint: tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Meal Prep entry

    private var mealPrepCard: some View {
        Button {
            Haptics.tap()
            showMealPrep = true
        } label: {
            MTCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(MTTheme.voltDim).frame(width: 48, height: 48)
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(MTTheme.accentText)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meal Prep")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(MTTheme.textPrimary)
                        Text("Auto-plan your week and shop once.")
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MTTheme.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meal sections

    private func mealEntries(_ mealType: MealType) -> [FoodEntry] {
        dayEntries.filter { $0.mealType == mealType }
    }

    private func mealHeader(_ mealType: MealType) -> some View {
        HStack(spacing: 10) {
            Image(systemName: mealType.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MTTheme.textSecondary)
            Text(mealType.displayName.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textSecondary)
            Spacer()
            let kcal = Int(mealEntries(mealType).reduce(0) { $0 + $1.calories })
            Text("\(kcal) kcal")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MTTheme.textTertiary)
            Button {
                Haptics.tap()
                addFoodMealType = mealType
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(width: 26, height: 26)
                    .background(MTTheme.volt)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }

    private func foodRow(_ entry: FoodEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                if let brand = entry.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Text("P \(Int(entry.proteinG))g · C \(Int(entry.carbsG))g · F \(Int(entry.fatG))g")
                    .font(.system(size: 11))
                    .foregroundStyle(MTTheme.textTertiary)
            }
            Spacer(minLength: 8)
            Text("\(Int(entry.calories.rounded())) kcal")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
        }
        .padding(.vertical, 4)
    }

    private func delete(_ entry: FoodEntry) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            modelContext.delete(entry)
        }
    }

    // MARK: - Water strip

    private var waterCard: some View {
        Button {
            Haptics.tap()
            showWaterDetail = true
        } label: {
            MTCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(MTTheme.water.opacity(0.15)).frame(width: 48, height: 48)
                        Image(systemName: "drop.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(MTTheme.water)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Water")
                            .font(.system(size: 13))
                            .foregroundStyle(MTTheme.textSecondary)
                        Text(String(format: "%.2f / %.1f L", Double(waterTotalML) / 1000, Double(waterTargetML) / 1000))
                            .font(MTTheme.numberFont(size: 17))
                            .foregroundStyle(MTTheme.textPrimary)
                        MTProgressBar(progress: waterProgress, tint: MTTheme.water)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MTTheme.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NutritionView()
        .environment(AppState())
        .environment(SubscriptionManager())
        .environment(HealthKitService())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
            inMemory: true
        )
}
