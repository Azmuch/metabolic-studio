import SwiftUI
import SwiftData
import UIKit
import MetabolicCore

/// UserDefaults key gating the one-time diet-preferences prompt; shared by `MealPrepView`
/// and `DietPreferencesSheet` below.
private let mealPrepDietPromptedKey = "mt.mealprep.dietPrompted"

/// Weekly meal-prep planner: a deterministic 7-day plan from `MealPlanGenerator`, seeded by
/// the ISO calendar week plus a stored "regenerate" offset. Per-meal logging inserts each
/// planned item as its own `FoodEntry`, and an aggregated grocery list supports tap-to-check.
/// Pushed from `NutritionView`.
struct MealPrepView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKit

    @State private var week: [MealPlanDay] = []
    @State private var selectedDayIndex: Int
    @State private var checkedGroceries: Set<String> = []
    @State private var loggedMealKeys: Set<String> = []
    @State private var showGroceryList = true
    @State private var showDietPrefs = false
    @State private var selectedMeal: PlannedMeal?
    @State private var favoriteMeals: [PlannedMeal] = []

    private static let favoritesKey = "mt.meals.favorites"

    private let calendar = Calendar.current
    private static let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]
    private static let offsetKey = "mt.mealprep.offset"
    private static let checkedKeyPrefix = "mt.grocery.checked."

    /// Checked-off items persist per plan seed, so the shopping list survives app restarts
    /// for the whole week and resets naturally when the plan changes.
    private var checkedKey: String { Self.checkedKeyPrefix + String(currentWeekSeed()) }

    init() {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: .now) // Gregorian: 1 = Sunday
        _selectedDayIndex = State(initialValue: (weekday + 5) % 7)
    }

    private var todayIndex: Int {
        let weekday = calendar.component(.weekday, from: .now)
        return (weekday + 5) % 7
    }

    private var selectedDay: MealPlanDay? {
        week.first { $0.dayIndex == selectedDayIndex }
    }

    private var groceries: [GroceryLine] {
        MealPlanGenerator.groceryList(for: week)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                daySelector

                if let day = selectedDay {
                    VStack(spacing: 14) {
                        ForEach(day.meals) { meal in
                            mealCard(meal, dayIndex: day.dayIndex)
                        }
                    }
                    dayTotalsFooter(day)
                    dietSummaryCaption
                }

                groceryListSection

                if !favoriteMeals.isEmpty {
                    favoriteMealsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(MTBackground())
        .navigationTitle("Meal Prep")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.tap()
                    showDietPrefs = true
                } label: {
                    Image(systemName: "fork.knife.circle")
                }
                .foregroundStyle(MTTheme.volt)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    regenerate()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .foregroundStyle(MTTheme.volt)
            }
        }
        .onAppear {
            loadFavoriteMeals()
            // Ask about allergies & preferences before the first plan is built.
            if !UserDefaults.standard.bool(forKey: mealPrepDietPromptedKey) {
                showDietPrefs = true
            } else if week.isEmpty {
                loadWeek()
            }
        }
        .sheet(isPresented: $showDietPrefs) {
            DietPreferencesSheet {
                loadWeek()
            }
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailSheet(meal: meal)
        }
    }

    /// Quiet summary of the rules the plan honors, shown under the day totals.
    @ViewBuilder
    private var dietSummaryCaption: some View {
        let p = appState.profile
        if p.dietaryPreference != .none || !p.allergies.isEmpty {
            let allergyText = p.allergies.isEmpty ? ""
                : " · avoiding: " + p.allergies.map(\.displayName).sorted().joined(separator: ", ")
            Text((p.dietaryPreference == .none ? "Custom" : p.dietaryPreference.displayName) + allergyText)
                .font(.system(size: 12))
                .foregroundStyle(MTTheme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Day selector

    private var daySelector: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                dayChip(index)
            }
        }
    }

    private func dayChip(_ index: Int) -> some View {
        let isSelected = index == selectedDayIndex
        let isToday = index == todayIndex
        let dayCalories = week.first { $0.dayIndex == index }?.calories ?? 0

        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                selectedDayIndex = index
            }
        } label: {
            VStack(spacing: 6) {
                Text(Self.weekdayLetters[index])
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? MTTheme.textPrimary : MTTheme.textSecondary)
                Circle()
                    .fill(dayCalories > 0 ? MTTheme.volt : MTTheme.textTertiary)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? MTTheme.voltDim : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                    .stroke(isToday ? MTTheme.volt : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meal cards

    private func mealCard(_ meal: PlannedMeal, dayIndex: Int) -> some View {
        MTCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Button {
                        Haptics.tap()
                        selectedMeal = meal
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: meal.mealType.symbolName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(MTTheme.textSecondary)
                            Text(meal.mealType.displayName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(MTTheme.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("\(Int(meal.calories.rounded())) kcal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MTTheme.textSecondary)
                    favoriteHeart(meal)
                }

                if meal.items.isEmpty {
                    Text("No items generated for this meal.")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textTertiary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(meal.items) { item in
                            Text("\(formattedServings(item.servings)) × \(item.food.name) — \(Int(item.calories.rounded())) kcal")
                                .font(.system(size: 13))
                                .foregroundStyle(MTTheme.textSecondary)
                        }
                    }

                    let logged = isMealLogged(meal, dayIndex: dayIndex)
                    MTSecondaryButton(
                        title: logged ? "Logged" : "Log this meal",
                        systemImage: logged ? "checkmark.circle.fill" : "checkmark.circle"
                    ) {
                        logMeal(meal, dayIndex: dayIndex)
                    }
                    .disabled(logged)
                    .opacity(logged ? 0.5 : 1)
                }
            }
        }
    }

    private func mealLogKey(_ meal: PlannedMeal, dayIndex: Int) -> String {
        "\(dayIndex)-\(meal.mealType.rawValue)"
    }

    private func isMealLogged(_ meal: PlannedMeal, dayIndex: Int) -> Bool {
        loggedMealKeys.contains(mealLogKey(meal, dayIndex: dayIndex))
    }

    private func logMeal(_ meal: PlannedMeal, dayIndex: Int) {
        for item in meal.items {
            let entry = FoodEntry(
                date: .now, mealType: meal.mealType, name: item.food.name, brand: item.food.brand,
                calories: item.calories, proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG,
                grams: nil, source: .manual
            )
            modelContext.insert(entry)
            Task { await healthKit.saveMeal(entry) }
        }
        loggedMealKeys.insert(mealLogKey(meal, dayIndex: dayIndex))
        Haptics.success()
    }

    // MARK: - Day totals

    private func dayTotalsFooter(_ day: MealPlanDay) -> some View {
        MTCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("DAY TOTAL")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(Int(day.calories.rounded())) kcal")
                            .font(MTTheme.numberFont(size: 20))
                            .foregroundStyle(MTTheme.textPrimary)
                        Spacer()
                        Text("target \(appState.targets.calories)")
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textSecondary)
                    }
                    MTProgressBar(
                        progress: appState.targets.calories > 0 ? day.calories / Double(appState.targets.calories) : 0,
                        tint: MTTheme.volt
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(Int(day.proteinG.rounded()))g protein")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MTTheme.textPrimary)
                        Spacer()
                        Text("target \(appState.targets.proteinG)g")
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textSecondary)
                    }
                    MTProgressBar(
                        progress: appState.targets.proteinG > 0 ? day.proteinG / Double(appState.targets.proteinG) : 0,
                        tint: MTTheme.protein
                    )
                }
            }
        }
    }

    // MARK: - Grocery list

    private var groceryListSection: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showGroceryList.toggle()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.volt)
                            Text("Weekly shopping list")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            Spacer()
                            Image(systemName: showGroceryList ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MTTheme.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if !groceries.isEmpty {
                        ShareLink(item: groceryShareText) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(MTTheme.volt)
                                .frame(width: 32, height: 32)
                                .background(MTTheme.voltDim, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if showGroceryList {
                    if groceries.isEmpty {
                        Text("Nothing to shop for yet.")
                            .font(.system(size: 13))
                            .foregroundStyle(MTTheme.textTertiary)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(groceries) { line in
                                groceryRow(line)
                                if line.id != groceries.last?.id {
                                    Divider().overlay(MTTheme.stroke)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func groceryRow(_ line: GroceryLine) -> some View {
        let isChecked = checkedGroceries.contains(line.foodID)
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                if isChecked {
                    checkedGroceries.remove(line.foodID)
                } else {
                    checkedGroceries.insert(line.foodID)
                }
                UserDefaults.standard.set(Array(checkedGroceries), forKey: checkedKey)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isChecked ? MTTheme.volt : MTTheme.textTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.name)
                        .font(.system(size: 14, weight: .semibold))
                        .strikethrough(isChecked)
                        .foregroundStyle(isChecked ? MTTheme.textTertiary : MTTheme.textPrimary)
                    Text("\(formattedServings(line.totalServings))× serving")
                        .font(.system(size: 11))
                        .foregroundStyle(MTTheme.textTertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Favorite meals (persisted snapshots, independent of the weekly plan)

    /// Content signature — generated meals get fresh UUIDs every plan, so favorites match on
    /// what's actually on the plate.
    private func mealSignature(_ meal: PlannedMeal) -> String {
        meal.mealType.rawValue + "|"
            + meal.items.map { "\($0.food.id)×\($0.servings)" }.joined(separator: ",")
    }

    private func isFavorite(_ meal: PlannedMeal) -> Bool {
        favoriteMeals.contains { mealSignature($0) == mealSignature(meal) }
    }

    private func favoriteHeart(_ meal: PlannedMeal) -> some View {
        let isFav = isFavorite(meal)
        return Button {
            Haptics.tap()
            toggleFavorite(meal)
        } label: {
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isFav ? MTTheme.volt : MTTheme.textTertiary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFav ? "Remove meal from favorites" : "Save meal to favorites")
    }

    private func toggleFavorite(_ meal: PlannedMeal) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            if let index = favoriteMeals.firstIndex(where: { mealSignature($0) == mealSignature(meal) }) {
                favoriteMeals.remove(at: index)
            } else {
                favoriteMeals.append(meal)
            }
        }
        if let data = try? JSONEncoder().encode(favoriteMeals) {
            UserDefaults.standard.set(data, forKey: Self.favoritesKey)
        }
    }

    private func loadFavoriteMeals() {
        guard let data = UserDefaults.standard.data(forKey: Self.favoritesKey),
              let meals = try? JSONDecoder().decode([PlannedMeal].self, from: data) else { return }
        favoriteMeals = meals
    }

    private var favoriteMealsSection: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                    Text("Favorite meals")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                }
                VStack(spacing: 0) {
                    ForEach(favoriteMeals) { meal in
                        favoriteMealRow(meal)
                        if meal.id != favoriteMeals.last?.id {
                            Divider().overlay(MTTheme.stroke)
                        }
                    }
                }
            }
        }
    }

    private func favoriteMealRow(_ meal: PlannedMeal) -> some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap()
                selectedMeal = meal
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: meal.mealType.symbolName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                        .frame(width: 32, height: 32)
                        .background(MTTheme.voltDim, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.items.map(\.food.name).joined(separator: " · "))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MTTheme.textPrimary)
                            .lineLimit(2)
                        Text("\(meal.mealType.displayName) · \(Int(meal.calories.rounded())) kcal")
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            favoriteHeart(meal)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Week seed + regenerate

    /// `year * 100 + weekOfYear` (ISO calendar week) plus a stored offset that only moves
    /// when the user taps Regenerate — keeps the plan stable across app launches within
    /// the same week otherwise.
    private func currentWeekSeed() -> UInt64 {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = .current
        let comps = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        let year = comps.yearForWeekOfYear ?? 2026
        let weekOfYear = comps.weekOfYear ?? 1
        let base = UInt64(year * 100 + weekOfYear)
        let offset = UserDefaults.standard.integer(forKey: Self.offsetKey)
        return base + UInt64(max(offset, 0))
    }

    private func loadWeek() {
        week = MealPlanGenerator.weeklyPlan(
            targets: appState.targets, profile: appState.profile, weekSeed: currentWeekSeed()
        )
        checkedGroceries = Set(UserDefaults.standard.stringArray(forKey: checkedKey) ?? [])
    }

    private func regenerate() {
        Haptics.tap()
        UserDefaults.standard.removeObject(forKey: checkedKey)   // old plan's checks are obsolete
        let nextOffset = UserDefaults.standard.integer(forKey: Self.offsetKey) + 1
        UserDefaults.standard.set(nextOffset, forKey: Self.offsetKey)
        loggedMealKeys.removeAll()
        checkedGroceries.removeAll()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            week = MealPlanGenerator.weeklyPlan(
                targets: appState.targets, profile: appState.profile, weekSeed: currentWeekSeed()
            )
        }
    }

    // MARK: - Share

    /// Plain-text export of the week's list — pastes cleanly into Messages, Notes, or Reminders.
    /// Open items get a bullet, already-bought items a check.
    private var groceryShareText: String {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = .current
        let weekStart = iso.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        var lines = ["Metabolic — Shopping list (week of \(weekStart.formatted(date: .abbreviated, time: .omitted)))", ""]
        for line in groceries {
            let mark = checkedGroceries.contains(line.foodID) ? "✓" : "•"
            lines.append("\(mark) \(line.name) — \(formattedServings(line.totalServings))× serving")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Formatting

    /// "1.5", "2", "0.75" — two decimals with trailing zeros trimmed.
    private func formattedServings(_ value: Double) -> String {
        var text = String(format: "%.2f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }
}

#Preview {
    NavigationStack {
        MealPrepView()
            .environment(AppState())
            .environment(HealthKitService())
            .modelContainer(
                for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
                inMemory: true
            )
    }
}

// MARK: - Meal detail

/// Detail for one planned meal: hero image (asset convention `meal.<foodID>` — soft placeholder
/// until the imagery batch lands), macro strip, ingredients with servings, simple prep steps,
/// and one-tap logging.
struct MealDetailSheet: View {
    let meal: PlannedMeal

    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var logged = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroImage

                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.mealType.displayName)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("\(meal.items.count) ingredient\(meal.items.count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                }

                macroStrip
                ingredientsCard
                prepCard

                MTPrimaryButton(title: logged ? "Logged" : "Log this meal",
                                systemImage: logged ? "checkmark.circle.fill" : "checkmark") {
                    log()
                }
                .disabled(logged)
                .opacity(logged ? 0.5 : 1)
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(MTBackground().ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var heroImage: some View {
        Group {
            if let image = meal.items.lazy
                .compactMap({ UIImage(named: "meal.\($0.food.id)") }).first {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(colors: [MTTheme.voltDim, MTTheme.surface2],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: meal.mealType.symbolName)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                }
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
    }

    private var macroStrip: some View {
        MTCard {
            HStack(spacing: 0) {
                macroColumn("\(Int(meal.calories.rounded()))", "kcal", MTTheme.volt)
                macroDivider
                macroColumn("\(Int(meal.proteinG.rounded()))g", "Protein", MTTheme.protein)
                macroDivider
                macroColumn("\(Int(meal.carbsG.rounded()))g", "Carbs", MTTheme.carbs)
                macroDivider
                macroColumn("\(Int(meal.fatG.rounded()))g", "Fat", MTTheme.fat)
            }
        }
    }

    private var macroDivider: some View {
        Rectangle().fill(MTTheme.stroke).frame(width: 1, height: 36)
    }

    private func macroColumn(_ value: String, _ label: String, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(MTTheme.numberFont(size: 18))
                .foregroundStyle(tint)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundStyle(MTTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var ingredientsCard: some View {
        MTCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("INGREDIENTS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                ForEach(meal.items) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Text(servingsText(item.servings) + "×")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(MTTheme.volt)
                            .frame(width: 40, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.food.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            Text("\(item.food.servingDescription) · \(Int(item.calories.rounded())) kcal")
                                .font(.system(size: 12))
                                .foregroundStyle(MTTheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Assembly-style guidance — the plan generates food combinations, not authored recipes,
    /// so the steps stay honest: portion, prepare, assemble.
    private var prepCard: some View {
        let names = meal.items.map { "\(servingsText($0.servings))× \($0.food.name)" }
        let steps = [
            "Portion out " + names.joined(separator: ", ") + ".",
            "Cook or heat anything served warm; keep fresh items chilled until you assemble.",
            "Plate it together and season to taste — the macros above already reflect these portions.",
        ]
        return MTCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("HOW TO PREP")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle().fill(MTTheme.voltDim).frame(width: 24, height: 24)
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(MTTheme.volt)
                        }
                        Text(step)
                            .font(.system(size: 13))
                            .foregroundStyle(MTTheme.textPrimary)
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func servingsText(_ value: Double) -> String {
        var text = String(format: "%.2f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }

    private func log() {
        for item in meal.items {
            let entry = FoodEntry(
                date: .now, mealType: meal.mealType, name: item.food.name, brand: item.food.brand,
                calories: item.calories, proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG,
                grams: nil, source: .manual
            )
            modelContext.insert(entry)
            Task { await healthKit.saveMeal(entry) }
        }
        Haptics.success()
        withAnimation(.snappy(duration: 0.25)) { logged = true }
    }
}

// MARK: - Diet preferences gate

/// Asked once before the first meal plan is built (and reopenable from the toolbar):
/// diet style + allergies, written straight onto the fitness profile so the whole
/// planning engine honors them.
struct DietPreferencesSheet: View {
    var onSaved: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var preference: DietaryPreference = .none
    @State private var allergies: Set<FoodAllergen> = []
    @State private var favoriteFoods: [String] = []
    @State private var favoriteFoodText = ""
    @State private var loaded = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MTSheetHeader(title: "Your food rules")

                Text("We'll build every plan around this.")
                    .font(.system(size: 14))
                    .foregroundStyle(MTTheme.textSecondary)

                MTCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DIET STYLE")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(MTTheme.textTertiary)
                        ForEach(DietaryPreference.allCases, id: \.self) { option in
                            Button {
                                Haptics.tap()
                                preference = option
                            } label: {
                                HStack {
                                    Text(option.displayName)
                                        .font(.system(size: 15,
                                                      weight: preference == option ? .semibold : .regular))
                                        .foregroundStyle(MTTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: preference == option
                                          ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(preference == option
                                                         ? MTTheme.volt : MTTheme.textTertiary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                MTCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ALLERGIES")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(MTTheme.textTertiary)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                            ForEach(FoodAllergen.allCases, id: \.self) { allergen in
                                Button {
                                    Haptics.tap()
                                    if allergies.contains(allergen) {
                                        allergies.remove(allergen)
                                    } else {
                                        allergies.insert(allergen)
                                    }
                                } label: {
                                    MTChip(text: allergen.displayName,
                                           isActive: allergies.contains(allergen))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text("Flagged foods are strictly excluded from generated plans.")
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                MTCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FAVORITE FOODS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(MTTheme.textTertiary)
                        HStack(spacing: 10) {
                            TextField("e.g. Salmon", text: $favoriteFoodText)
                                .font(.system(size: 15))
                                .foregroundStyle(MTTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
                            Button {
                                let trimmed = favoriteFoodText.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty, !favoriteFoods.contains(trimmed) else { return }
                                Haptics.tap()
                                favoriteFoods.append(trimmed)
                                favoriteFoodText = ""
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.black)
                                    .frame(width: 40, height: 40)
                                    .background(MTTheme.volt, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(favoriteFoodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        if !favoriteFoods.isEmpty {
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                                ForEach(favoriteFoods, id: \.self) { food in
                                    Button {
                                        Haptics.tap()
                                        favoriteFoods.removeAll { $0 == food }
                                    } label: {
                                        MTChip(text: food, systemImage: "xmark", isActive: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        Text("We'll lean toward these when they fit your targets.")
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                MTPrimaryButton(title: "Build my plan", systemImage: "sparkles") {
                    var profile = appState.profile
                    profile.dietaryPreference = preference
                    profile.allergies = allergies
                    profile.favoriteFoods = favoriteFoods
                    appState.profile = profile
                    UserDefaults.standard.set(true, forKey: mealPrepDietPromptedKey)
                    Haptics.success()
                    onSaved()
                    dismiss()
                }
            }
            .padding(20)
        }
        .background(MTBackground().ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            guard !loaded else { return }
            preference = appState.profile.dietaryPreference
            allergies = appState.profile.allergies
            favoriteFoods = appState.profile.favoriteFoods
            loaded = true
        }
    }
}
