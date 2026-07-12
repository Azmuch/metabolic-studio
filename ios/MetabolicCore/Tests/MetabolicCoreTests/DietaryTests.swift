import XCTest
@testable import MetabolicCore

final class DietaryTests: XCTestCase {

    private let targets = NutritionEngine.targets(for: .default)

    func testCompatibilityRules() {
        let chicken = FoodDatabase.common.first { $0.id == "chicken-breast" }!
        let salmon = FoodDatabase.common.first { $0.id == "salmon" }!
        let yogurt = FoodDatabase.common.first { $0.id == "greek-yogurt" }!
        let tofu = FoodDatabase.common.first { $0.id == "tofu-firm" }!
        let almonds = FoodDatabase.common.first { $0.id == "almonds" }!

        XCTAssertFalse(chicken.isCompatible(with: .vegetarian, allergies: []))
        XCTAssertFalse(chicken.isCompatible(with: .pescatarian, allergies: []))
        XCTAssertTrue(salmon.isCompatible(with: .pescatarian, allergies: []))
        XCTAssertFalse(salmon.isCompatible(with: .vegetarian, allergies: []))
        XCTAssertTrue(yogurt.isCompatible(with: .vegetarian, allergies: []))
        XCTAssertFalse(yogurt.isCompatible(with: .vegan, allergies: []))
        XCTAssertFalse(yogurt.isCompatible(with: .none, allergies: [.dairy]))
        XCTAssertTrue(tofu.isCompatible(with: .vegan, allergies: []))
        XCTAssertFalse(tofu.isCompatible(with: .vegan, allergies: [.soy]))
        XCTAssertFalse(almonds.isCompatible(with: .none, allergies: [.nuts]))
    }

    func testVeganWeeklyPlanContainsNoAnimalProducts() {
        var p = FitnessProfile.default
        p.dietaryPreference = .vegan
        let week = MealPlanGenerator.weeklyPlan(targets: targets, profile: p, weekSeed: 7)
        let banned: Set<FoodTag> = [.meat, .poultry, .fish, .shellfish, .dairy, .egg]
        for day in week {
            for meal in day.meals {
                for item in meal.items {
                    XCTAssertTrue(item.food.tags.isDisjoint(with: banned),
                                  "\(item.food.id) violates vegan preference")
                }
                XCTAssertFalse(meal.items.isEmpty, "vegan filtering emptied a meal")
            }
        }
    }

    func testNutAllergyExcludesNuts() {
        var p = FitnessProfile.default
        p.allergies = [.nuts]
        let week = MealPlanGenerator.weeklyPlan(targets: targets, profile: p, weekSeed: 9)
        for item in week.flatMap(\.meals).flatMap(\.items) {
            XCTAssertFalse(item.food.tags.contains(.nuts), "\(item.food.id) contains nuts")
        }
    }

    func testGlutenFreePescatarianStillBuildsFullMeals() {
        var p = FitnessProfile.default
        p.dietaryPreference = .pescatarian
        p.allergies = [.gluten]
        let week = MealPlanGenerator.weeklyPlan(targets: targets, profile: p, weekSeed: 11)
        for day in week {
            XCTAssertEqual(day.meals.count, 4)
            let deviation = abs(day.calories - Double(targets.calories)) / Double(targets.calories)
            XCTAssertLessThanOrEqual(deviation, 0.25)
        }
    }

    func testDietFieldsDefaultForV1Profiles() throws {
        let v1JSON = """
        {"age":30,"sex":"male","heightCm":175,"weightKg":75,"goal":"maintain",
        "activityLevel":"moderate","experience":"beginner","equipment":["none"],
        "injuries":[],"workoutDaysPerWeek":3,"sessionMinutes":30}
        """.data(using: .utf8)!
        let profile = try JSONDecoder().decode(FitnessProfile.self, from: v1JSON)
        XCTAssertEqual(profile.dietaryPreference, DietaryPreference.none)
        XCTAssertTrue(profile.allergies.isEmpty)
    }
}
