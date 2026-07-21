import SwiftUI
import SwiftData
import MetabolicCore

/// Search tab of `AddFoodSheet`: instant, token-aware results from the local seed database,
/// plus a debounced OpenFoodFacts lookup. Tapping a result opens a portion sheet before
/// logging. When both sources come up empty for a real query, offers to hand the typed
/// name off to Manual entry via `onCreateCustom`.
struct FoodSearchView: View {
    let mealType: MealType
    var onCreateCustom: (String) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var offFoods: [FoodItem] = []
    @State private var isSearchingOFF = false
    @State private var offFailed = false
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedFood: FoodItem?
    @FocusState private var isFocused: Bool

    init(mealType: MealType, onCreateCustom: @escaping (String) -> Void = { _ in }) {
        self.mealType = mealType
        self.onCreateCustom = onCreateCustom
    }

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Merges `FoodDatabase.search`'s substring match with a token-aware pass so partial,
    /// reordered, or abbreviated words ("chick br", "greek yog", "rice brown") still hit —
    /// every query token must prefix/contain some word in the item's name + brand. Runs
    /// synchronously on every keystroke; no debounce for local results.
    private var localResults: [FoodItem] {
        guard !trimmedQuery.isEmpty else { return [] }
        let dbResults = FoodDatabase.search(trimmedQuery)
        let tokenResults = Self.tokenMatches(query: trimmedQuery, in: FoodDatabase.common)
        var seen = Set<String>()
        var merged: [FoodItem] = []
        for item in dbResults + tokenResults where seen.insert(item.id).inserted {
            merged.append(item)
        }
        return merged
    }

    private static func tokenMatches(query: String, in items: [FoodItem]) -> [FoodItem] {
        let tokens = query
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
        guard !tokens.isEmpty else { return [] }
        return items
            .filter { item in
                let words = (item.name + " " + (item.brand ?? ""))
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
                    .lowercased()
                    .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                    .map(String.init)
                return tokens.allSatisfy { token in words.contains { $0.contains(token) } }
            }
            .sorted { $0.name.count < $1.name.count }
    }

    /// True once the remote lookup has settled (success or failure) with nothing to show —
    /// the trigger for the "Create" fallback row.
    private var remoteCameUpEmpty: Bool { !isSearchingOFF && offFoods.isEmpty }
    private var showCreateRow: Bool {
        localResults.isEmpty && remoteCameUpEmpty && trimmedQuery.count >= 2
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField

            List {
                if !localResults.isEmpty {
                    Section {
                        ForEach(localResults) { food in
                            foodRow(food)
                        }
                    } header: {
                        sectionHeader("FOOD LIBRARY")
                    }
                }

                if !trimmedQuery.isEmpty, isSearchingOFF || offFailed || !offFoods.isEmpty {
                    Section {
                        if isSearchingOFF {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(MTTheme.textSecondary)
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } else if offFailed {
                            Text("Couldn't reach OpenFoodFacts")
                                .font(.system(size: 13))
                                .foregroundStyle(MTTheme.textTertiary)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(offFoods) { food in
                                foodRow(food)
                            }
                        }
                    } header: {
                        sectionHeader("FROM OPENFOODFACTS")
                    }
                }

                if showCreateRow {
                    Section {
                        createCustomRow
                    }
                }

                if trimmedQuery.isEmpty {
                    Section {
                        Text("Search the food library or OpenFoodFacts to add an item.")
                            .font(.system(size: 13))
                            .foregroundStyle(MTTheme.textTertiary)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(MTBackground())
        .onAppear { isFocused = true }
        .onChange(of: query) { _, newValue in
            searchTask?.cancel()
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                offFoods = []
                offFailed = false
                isSearchingOFF = false
                return
            }
            searchTask = Task {
                isSearchingOFF = true
                offFailed = false
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                do {
                    let results = try await OpenFoodFactsClient().searchFoods(query: trimmed)
                    guard !Task.isCancelled else { return }
                    offFoods = results
                } catch {
                    guard !Task.isCancelled else { return }
                    offFoods = []
                    offFailed = true
                }
                isSearchingOFF = false
            }
        }
        .sheet(item: $selectedFood) { food in
            FoodPortionSheet(food: food, mealType: mealType) {
                dismiss()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var createCustomRow: some View {
        Button {
            Haptics.tap()
            onCreateCustom(trimmedQuery)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MTTheme.accentText)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create \"\(trimmedQuery)\"")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("Not in either database — add it manually.")
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MTTheme.textTertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(MTTheme.voltDim)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(MTTheme.textTertiary)
            TextField("Search foods", text: $query)
                .focused($isFocused)
                .foregroundStyle(MTTheme.textPrimary)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MTTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(MTTheme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(MTTheme.textTertiary)
            .textCase(nil)
    }

    private func foodRow(_ food: FoodItem) -> some View {
        Button {
            Haptics.tap()
            selectedFood = food
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text([food.brand, food.servingDescription].compactMap { $0 }.joined(separator: " · "))
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(Int(food.calories.rounded())) kcal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MTTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(MTTheme.surface)
    }
}

/// Quantity picker shown after tapping a search result — scales the base serving's
/// calories/macros live before logging.
private struct FoodPortionSheet: View {
    let food: FoodItem
    let mealType: MealType
    var onAdded: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKit
    @State private var quantity: Double = 1.0
    @State private var weighedGrams: Double?
    @State private var showScale = false

    private var calories: Double { food.calories * quantity }
    private var protein: Double { food.proteinG * quantity }
    private var carbs: Double { food.carbsG * quantity }
    private var fat: Double { food.fatG * quantity }

    /// Gram (or ml) amount of one serving, parsed from strings like "per 100 g",
    /// "1 cup (240 ml)" or "1 oz (28 g)" — the basis for scale-weighed portions.
    private var servingGrams: Double? {
        let text = food.servingDescription.lowercased()
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: " ")
        let tokens = text.split(separator: " ").map(String.init)
        for (index, token) in tokens.enumerated() {
            if let value = Double(token), index + 1 < tokens.count,
               tokens[index + 1] == "g" || tokens[index + 1] == "ml" {
                return value
            }
            let numeric = token.hasSuffix("ml") ? String(token.dropLast(2))
                : token.hasSuffix("g") ? String(token.dropLast(1)) : ""
            if let value = Double(numeric) {
                return value
            }
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 24) {
            MTSheetHeader(title: food.name)

            VStack(spacing: 4) {
                if let brand = food.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Text(food.servingDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(MTTheme.textSecondary)
            }

            MTCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Quantity")
                            .font(.system(size: 15))
                            .foregroundStyle(MTTheme.textSecondary)
                        Spacer()
                        Stepper(value: $quantity, in: 0.25...10, step: 0.25) {
                            Text("×\(quantity, specifier: "%.2f")")
                                .font(MTTheme.numberFont(size: 17))
                                .foregroundStyle(MTTheme.textPrimary)
                        }
                        .fixedSize()
                    }

                    if servingGrams != nil {
                        Button {
                            Haptics.tap()
                            showScale = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "scalemass.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(weighedGrams.map { "Weighed \(Int($0.rounded())) g" }
                                    ?? "Weigh with smart scale")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(MTTheme.accentText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(MTTheme.voltDim, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider().overlay(MTTheme.stroke)

                    Text("\(Int(calories.rounded())) kcal")
                        .font(MTTheme.numberFont(size: 32))
                        .foregroundStyle(MTTheme.textPrimary)

                    HStack(spacing: 20) {
                        macroStat("Protein", protein, MTTheme.protein)
                        macroStat("Carbs", carbs, MTTheme.carbs)
                        macroStat("Fat", fat, MTTheme.fat)
                    }
                }
            }

            Spacer(minLength: 0)

            MTPrimaryButton(title: "Add to \(mealType.displayName)") {
                let entry = FoodEntry(
                    date: .now, mealType: mealType, name: food.name, brand: food.brand,
                    calories: calories, proteinG: protein, carbsG: carbs, fatG: fat,
                    grams: weighedGrams, source: .search
                )
                modelContext.insert(entry)
                Task { await healthKit.saveMeal(entry) }
                Haptics.success()
                onAdded()
            }
        }
        .padding(20)
        .background(MTBackground())
        .sheet(isPresented: $showScale) {
            SmartScaleSheet { grams in
                guard let basis = servingGrams, basis > 0 else { return }
                weighedGrams = grams
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    quantity = min(max(grams / basis, 0.05), 20)
                }
            }
        }
    }

    private func macroStat(_ label: String, _ value: Double, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Circle().fill(tint).frame(width: 6, height: 6)
            Text("\(Int(value.rounded()))g")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(MTTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FoodSearchView(mealType: .breakfast)
        .environment(HealthKitService())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
            inMemory: true
        )
}
