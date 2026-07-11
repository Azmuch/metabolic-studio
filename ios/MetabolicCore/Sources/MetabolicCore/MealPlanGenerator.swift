import Foundation

public struct PlannedMealItem: Codable, Equatable, Sendable, Identifiable {
    public var id: String { food.id }
    public var food: FoodItem
    public var servings: Double

    public var calories: Double { food.calories * servings }
    public var proteinG: Double { food.proteinG * servings }
    public var carbsG: Double { food.carbsG * servings }
    public var fatG: Double { food.fatG * servings }

    public init(food: FoodItem, servings: Double) {
        self.food = food
        self.servings = servings
    }
}

public struct PlannedMeal: Codable, Equatable, Sendable, Identifiable {
    public var id: String { mealType.rawValue }
    public var mealType: MealType
    public var items: [PlannedMealItem]

    public var calories: Double { items.reduce(0) { $0 + $1.calories } }
    public var proteinG: Double { items.reduce(0) { $0 + $1.proteinG } }
    public var carbsG: Double { items.reduce(0) { $0 + $1.carbsG } }
    public var fatG: Double { items.reduce(0) { $0 + $1.fatG } }

    public init(mealType: MealType, items: [PlannedMealItem]) {
        self.mealType = mealType
        self.items = items
    }
}

public struct MealPlanDay: Codable, Equatable, Sendable, Identifiable {
    public var id: Int { dayIndex }
    public var dayIndex: Int          // 0 = Monday … 6 = Sunday
    public var meals: [PlannedMeal]

    public var calories: Double { meals.reduce(0) { $0 + $1.calories } }
    public var proteinG: Double { meals.reduce(0) { $0 + $1.proteinG } }

    public init(dayIndex: Int, meals: [PlannedMeal]) {
        self.dayIndex = dayIndex
        self.meals = meals
    }
}

public struct GroceryLine: Codable, Equatable, Sendable, Identifiable {
    public var id: String { foodID }
    public var foodID: String
    public var name: String
    public var servingDescription: String
    public var totalServings: Double

    public init(foodID: String, name: String, servingDescription: String, totalServings: Double) {
        self.foodID = foodID
        self.name = name
        self.servingDescription = servingDescription
        self.totalServings = totalServings
    }
}

/// Deterministic weekly meal-prep planner. Builds each day from curated component pools
/// in the seed food database, scaled so daily calories land within ~8% of target and
/// protein lands at or above ~90% of target.
public enum MealPlanGenerator {

    /// Calorie split across the day.
    private static let mealBudgets: [(MealType, Double)] = [
        (.breakfast, 0.25), (.lunch, 0.30), (.dinner, 0.35), (.snack, 0.10),
    ]

    // Component pools reference seed FoodDatabase ids.
    private static let proteinPool = [
        "chicken-breast", "salmon", "tuna-canned", "ground-beef", "turkey-breast",
        "tofu-firm", "egg", "greek-yogurt", "cottage-cheese", "shrimp", "tempeh",
    ]
    private static let carbPool = [
        "brown-rice", "white-rice", "quinoa", "oatmeal", "pasta", "sweet-potato",
        "potato-baked", "bread-whole-wheat", "tortilla-flour",
    ]
    private static let vegFruitPool = [
        "broccoli", "spinach", "carrots", "bell-pepper", "green-beans", "mixed-salad",
        "banana", "apple", "blueberries", "strawberries", "orange",
    ]
    private static let fatPool = [
        "avocado", "almonds", "peanut-butter", "olive-oil", "walnuts", "hummus",
    ]
    private static let snackPool = [
        "greek-yogurt", "protein-bar", "almonds", "apple", "cottage-cheese",
        "dark-chocolate", "banana", "hummus",
    ]

    public static func weeklyPlan(targets: NutritionTargets, profile: FitnessProfile,
                                  weekSeed: UInt64) -> [MealPlanDay] {
        var rng = SeededRandom(seed: weekSeed ^ 0x6D65616C70726570)
        return (0..<7).map { dayIndex in
            let meals = mealBudgets.map { mealType, share in
                buildMeal(type: mealType,
                          calorieBudget: Double(targets.calories) * share,
                          proteinBudget: Double(targets.proteinG) * share,
                          rng: &rng)
            }
            return MealPlanDay(dayIndex: dayIndex, meals: meals)
        }
    }

    public static func groceryList(for days: [MealPlanDay]) -> [GroceryLine] {
        var totals: [String: GroceryLine] = [:]
        for day in days {
            for meal in day.meals {
                for item in meal.items {
                    if var line = totals[item.food.id] {
                        line.totalServings += item.servings
                        totals[item.food.id] = line
                    } else {
                        totals[item.food.id] = GroceryLine(
                            foodID: item.food.id, name: item.food.name,
                            servingDescription: item.food.servingDescription,
                            totalServings: item.servings)
                    }
                }
            }
        }
        return totals.values.sorted { $0.name < $1.name }
    }

    // MARK: - Meal assembly

    private static func buildMeal(type: MealType, calorieBudget: Double,
                                  proteinBudget: Double, rng: inout SeededRandom) -> PlannedMeal {
        if type == .snack {
            guard let snack = food(rng.pick(snackPool)) else {
                return PlannedMeal(mealType: type, items: [])
            }
            let servings = clampServings(calorieBudget / snack.calories)
            return PlannedMeal(mealType: type,
                               items: [PlannedMealItem(food: snack, servings: servings)])
        }

        guard let protein = food(rng.pick(proteinPool)),
              let carb = food(rng.pick(carbPool)),
              let vegFruit = food(rng.pick(vegFruitPool)),
              let fat = food(rng.pick(fatPool)) else {
            return PlannedMeal(mealType: type, items: [])
        }

        // Protein first: hit the meal's protein budget with the protein component,
        // capped so it can't eat the whole calorie budget.
        var proteinServings = clampServings(proteinBudget / max(protein.proteinG, 1))
        if protein.calories * proteinServings > calorieBudget * 0.55 {
            proteinServings = clampServings(calorieBudget * 0.55 / protein.calories)
        }

        let vegServings = clampServings(min(1.5, calorieBudget * 0.12 / max(vegFruit.calories, 15)))
        let fatServings = clampServings(calorieBudget * 0.15 / max(fat.calories, 40))

        let spent = protein.calories * proteinServings
            + vegFruit.calories * vegServings
            + fat.calories * fatServings
        let carbServings = clampServings((calorieBudget - spent) / max(carb.calories, 60))

        return PlannedMeal(mealType: type, items: [
            PlannedMealItem(food: protein, servings: proteinServings),
            PlannedMealItem(food: carb, servings: carbServings),
            PlannedMealItem(food: vegFruit, servings: vegServings),
            PlannedMealItem(food: fat, servings: fatServings),
        ])
    }

    private static func food(_ id: String?) -> FoodItem? {
        guard let id else { return nil }
        return FoodDatabase.common.first { $0.id == id }
    }

    /// Servings in quarter-steps between 0.5 and 3.
    private static func clampServings(_ raw: Double) -> Double {
        let clamped = min(max(raw, 0.5), 3.0)
        return (clamped * 4).rounded() / 4
    }
}
