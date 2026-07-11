import XCTest
@testable import MetabolicCore

final class ScheduleRecommenderTests: XCTestCase {

    func testBaselineByExperience() {
        let beginner = ScheduleRecommender.recommendation(for: FitnessProfile.default)
        XCTAssertEqual(beginner.days, 3)
        XCTAssertEqual(beginner.minutes, 30)

        let advanced = ScheduleRecommender.recommendation(
            for: FitnessProfile(goal: .gainMuscle, experience: .advanced))
        XCTAssertEqual(advanced.days, 5)
        XCTAssertEqual(advanced.minutes, 75)
    }

    func testBoundsAlwaysRespected() {
        let profiles = [
            FitnessProfile(age: 72, goal: .improveMobility, activityLevel: .veryActive),
            FitnessProfile(age: 18, goal: .loseFat, activityLevel: .sedentary,
                           experience: .advanced),
        ]
        for p in profiles {
            let rec = ScheduleRecommender.recommendation(for: p)
            XCTAssertTrue((2...6).contains(rec.days))
            XCTAssertTrue((15...90).contains(rec.minutes))
        }
    }

    func testPinnedDimensionsPreserveWeeklyVolume() {
        let p = FitnessProfile(experience: .intermediate)   // baseline 4 × 45 = 180 weekly min
        let minutesFor3 = ScheduleRecommender.recommendedMinutes(forDays: 3, profile: p)
        XCTAssertEqual(minutesFor3, 60)
        let daysFor90 = ScheduleRecommender.recommendedDays(forMinutes: 90, profile: p)
        XCTAssertEqual(daysFor90, 2)
    }
}

final class ProfileV2Tests: XCTestCase {

    func testV1ProfileJSONStillDecodes() throws {
        let v1JSON = """
        {"age":34,"sex":"female","heightCm":168,"weightKg":62,"goal":"loseFat",
        "activityLevel":"active","experience":"intermediate","equipment":["dumbbells"],
        "injuries":["wrist"],"workoutDaysPerWeek":4,"sessionMinutes":45}
        """.data(using: .utf8)!
        let profile = try JSONDecoder().decode(FitnessProfile.self, from: v1JSON)
        XCTAssertEqual(profile.age, 34)
        XCTAssertTrue(profile.focusAreas.isEmpty)
        XCTAssertTrue(profile.customFlags.isEmpty)
        XCTAssertFalse(profile.includeMobilityWork)
        XCTAssertNil(profile.customProteinG)
        XCTAssertEqual(profile.scheduleAnchor, .daysPerWeek)
    }

    func testMacroOverridesApply() {
        var p = FitnessProfile.default
        p.customProteinG = 150
        p.customFatG = 60
        let t = NutritionEngine.targets(for: p)
        XCTAssertEqual(t.proteinG, 150)
        XCTAssertEqual(t.fatG, 60)
        // Carbs re-balance to remaining calories.
        XCTAssertEqual(t.carbsG, Int(((Double(t.calories) - 150 * 4 - 60 * 9) / 4).rounded()))
    }

    func testMobilityGoalTargetsMatchMaintenance() {
        var mobility = FitnessProfile.default
        mobility.goal = .improveMobility
        XCTAssertEqual(NutritionEngine.targets(for: mobility).calories,
                       NutritionEngine.targets(for: .default).calories)
    }
}

final class MobilityPlanTests: XCTestCase {

    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var monday: Date {
        utcCalendar.date(from: DateComponents(year: 2026, month: 7, day: 6, hour: 12))!
    }

    func testMobilityBlocksBookendThePlanWhenEnabled() {
        var p = FitnessProfile.default
        p.includeMobilityWork = true
        let plan = WorkoutPlanGenerator.plan(for: p, date: monday, calendar: utcCalendar)
        XCTAssertGreaterThanOrEqual(plan.items.count, 5)
        XCTAssertEqual(plan.items.first?.exercise.category, .mobility)
        XCTAssertEqual(plan.items.last?.exercise.category, .mobility)
        XCTAssertEqual(plan.items.first?.sets, 1)
        // Main block stays strength.
        let middle = plan.items.dropFirst(2).dropLast(2)
        XCTAssertTrue(middle.allSatisfy { $0.exercise.category == .strength })
    }

    func testNoMobilityBlocksByDefault() {
        let plan = WorkoutPlanGenerator.plan(for: .default, date: monday, calendar: utcCalendar)
        XCTAssertTrue(plan.items.allSatisfy { $0.exercise.category == .strength })
    }

    func testFocusAreasBiasSelection() {
        var p = FitnessProfile.default
        p.focusAreas = [.glutes]
        let plan = WorkoutPlanGenerator.plan(for: p, date: monday, calendar: utcCalendar)
        XCTAssertTrue(plan.items.contains { $0.exercise.muscleGroups.contains(.glutes) },
                      "focus areas should pull matching exercises into the plan")
    }

    func testMobilityExercisesAreWellFormed() {
        let mobility = ExerciseLibrary.all.filter { $0.category == .mobility }
        XCTAssertGreaterThanOrEqual(mobility.count, 10)
        for exercise in mobility {
            XCTAssertGreaterThanOrEqual(exercise.keyframes.count, 2, exercise.id)
            for keyframe in exercise.keyframes {
                XCTAssertEqual(keyframe.joints.count, Joint.allCases.count, exercise.id)
            }
        }
    }
}

final class MealPlanGeneratorTests: XCTestCase {

    private let targets = NutritionEngine.targets(for: .default)

    func testDeterministicForSameSeed() {
        let a = MealPlanGenerator.weeklyPlan(targets: targets, profile: .default, weekSeed: 20260706)
        let b = MealPlanGenerator.weeklyPlan(targets: targets, profile: .default, weekSeed: 20260706)
        XCTAssertEqual(a, b)
        let c = MealPlanGenerator.weeklyPlan(targets: targets, profile: .default, weekSeed: 20260713)
        XCTAssertNotEqual(a, c)
    }

    func testWeekShapeAndCalorieAccuracy() {
        let week = MealPlanGenerator.weeklyPlan(targets: targets, profile: .default, weekSeed: 42)
        XCTAssertEqual(week.count, 7)
        for day in week {
            XCTAssertEqual(day.meals.count, 4)
            let deviation = abs(day.calories - Double(targets.calories)) / Double(targets.calories)
            XCTAssertLessThanOrEqual(deviation, 0.18,
                                     "day \(day.dayIndex) calories \(Int(day.calories)) vs \(targets.calories)")
            XCTAssertGreaterThanOrEqual(day.proteinG, Double(targets.proteinG) * 0.65,
                                        "day \(day.dayIndex) protein too low")
        }
    }

    func testGroceryListAggregates() {
        let week = MealPlanGenerator.weeklyPlan(targets: targets, profile: .default, weekSeed: 42)
        let groceries = MealPlanGenerator.groceryList(for: week)
        XCTAssertFalse(groceries.isEmpty)
        XCTAssertTrue(groceries.allSatisfy { $0.totalServings > 0 })
        let totalFromLines = groceries.reduce(0.0) { $0 + $1.totalServings }
        let totalFromMeals = week.flatMap(\.meals).flatMap(\.items).reduce(0.0) { $0 + $1.servings }
        XCTAssertEqual(totalFromLines, totalFromMeals, accuracy: 0.001)
    }
}
