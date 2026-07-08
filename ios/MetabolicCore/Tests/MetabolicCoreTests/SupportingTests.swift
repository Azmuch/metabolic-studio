import XCTest
@testable import MetabolicCore

final class FoodDatabaseTests: XCTestCase {

    func testSeedSizeAndIntegrity() {
        XCTAssertGreaterThanOrEqual(FoodDatabase.common.count, 60)
        XCTAssertEqual(Set(FoodDatabase.common.map(\.id)).count, FoodDatabase.common.count)
        for item in FoodDatabase.common {
            XCTAssertGreaterThan(item.calories, 0, item.id)
            XCTAssertFalse(item.name.isEmpty, item.id)
            XCTAssertFalse(item.servingDescription.isEmpty, item.id)
        }
    }

    func testSearchBehavior() {
        XCTAssertFalse(FoodDatabase.search("chicken").isEmpty)
        XCTAssertEqual(FoodDatabase.search("chicken").map(\.id),
                       FoodDatabase.search("CHICKEN").map(\.id))
        XCTAssertTrue(FoodDatabase.search("zzzqqqxxx").isEmpty)
        XCTAssertTrue(FoodDatabase.search("   ").isEmpty)
        XCTAssertLessThanOrEqual(FoodDatabase.search("a").count, 25)
    }
}

final class SeededRandomTests: XCTestCase {

    func testSameSeedSameSequence() {
        var a = SeededRandom(seed: 42)
        var b = SeededRandom(seed: 42)
        for _ in 0..<20 {
            XCTAssertEqual(a.next(), b.next())
        }
    }

    func testDifferentSeedsDiverge() {
        var a = SeededRandom(seed: 1)
        var b = SeededRandom(seed: 2)
        let aValues = (0..<5).map { _ in a.next() }
        let bValues = (0..<5).map { _ in b.next() }
        XCTAssertNotEqual(aValues, bValues)
    }

    func testIntStaysInBounds() {
        var rng = SeededRandom(seed: 7)
        for _ in 0..<1000 {
            let value = rng.int(in: 3...9)
            XCTAssertTrue((3...9).contains(value))
        }
    }

    func testZeroSeedIsUsable() {
        var rng = SeededRandom(seed: 0)
        XCTAssertNotEqual(rng.next(), 0)
    }

    func testPick() {
        var rng = SeededRandom(seed: 5)
        XCTAssertNil(rng.pick([Int]()))
        var other = SeededRandom(seed: 5)
        XCTAssertEqual(rng.pick([1, 2, 3]), other.pick([1, 2, 3]))
    }
}

final class StreakCalculatorTests: XCTestCase {

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func day(_ offset: Int, hour: Int = 15) -> Date {
        let base = calendar.date(from: DateComponents(year: 2026, month: 7, day: 8, hour: hour))!
        return calendar.date(byAdding: .day, value: offset, to: base)!
    }

    func testEmptyIsZero() {
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDays: [], today: day(0), calendar: calendar), 0)
    }

    func testTodayOnly() {
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDays: [day(0)], today: day(0), calendar: calendar), 1)
    }

    func testRunOfDays() {
        let logged: Set<Date> = [day(0), day(-1), day(-2)]
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDays: logged, today: day(0), calendar: calendar), 3)
    }

    func testTodayMissingContinuesFromYesterday() {
        let logged: Set<Date> = [day(-1), day(-2)]
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDays: logged, today: day(0), calendar: calendar), 2)
    }

    func testGapBreaksStreak() {
        let logged: Set<Date> = [day(0), day(-2), day(-3)]
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDays: logged, today: day(0), calendar: calendar), 1)
    }

    func testTimeOfDayIsNormalized() {
        let logged: Set<Date> = [day(0, hour: 23), day(-1, hour: 1)]
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDays: logged, today: day(0, hour: 6), calendar: calendar), 2)
    }
}

final class ModelCodableTests: XCTestCase {

    func testFitnessProfileRoundTrip() throws {
        let profile = FitnessProfile(age: 27, sex: .female, heightCm: 168, weightKg: 61,
                                     goal: .gainMuscle, activityLevel: .active,
                                     experience: .intermediate,
                                     equipment: [.dumbbells, .bench], injuries: [.wrist],
                                     workoutDaysPerWeek: 4, sessionMinutes: 45)
        let data = try JSONEncoder().encode(profile)
        XCTAssertEqual(try JSONDecoder().decode(FitnessProfile.self, from: data), profile)
    }

    func testExerciseKindRoundTrip() throws {
        for kind in [ExerciseKind.reps(12), .timed(seconds: 45)] {
            let data = try JSONEncoder().encode(kind)
            XCTAssertEqual(try JSONDecoder().decode(ExerciseKind.self, from: data), kind)
        }
    }

    func testMealPhotoAnalysisDecodingFromModelJSON() throws {
        // Mirrors the JSON contract the vision prompt demands from the model.
        let json = """
        {"items":[{"name":"Grilled chicken","portionDescription":"1 breast","estimatedGrams":150,
        "calories":248,"proteinG":46.5,"carbsG":0,"fatG":5.4,"confidence":0.92}],"notes":null}
        """.data(using: .utf8)!
        let analysis = try JSONDecoder().decode(MealPhotoAnalysis.self, from: json)
        XCTAssertEqual(analysis.items.count, 1)
        XCTAssertEqual(analysis.totalCalories, 248, accuracy: 0.001)
        XCTAssertNil(analysis.notes)
    }

    func testWorkoutPlanRoundTrip() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2026, month: 7, day: 6))!
        let plan = WorkoutPlanGenerator.plan(for: .default, date: date, calendar: cal)
        let data = try JSONEncoder().encode(plan)
        XCTAssertEqual(try JSONDecoder().decode(WorkoutPlan.self, from: data), plan)
    }
}
