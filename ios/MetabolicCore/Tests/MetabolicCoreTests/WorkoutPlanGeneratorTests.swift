import XCTest
@testable import MetabolicCore

final class WorkoutPlanGeneratorTests: XCTestCase {

    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // 2026-07-06 is a Monday.
    private let monday = DateComponents(year: 2026, month: 7, day: 6)

    func testSplitsHaveSevenEntriesAndCorrectWorkoutCount() {
        for days in 2...6 {
            let p = FitnessProfile(workoutDaysPerWeek: days)
            let split = WorkoutPlanGenerator.weeklySplit(for: p)
            XCTAssertEqual(split.count, 7)
            XCTAssertEqual(split.filter { $0 != .rest }.count, days)
        }
    }

    func testSplitClampsOutOfRangeDays() {
        XCTAssertEqual(WorkoutPlanGenerator.weeklySplit(for: FitnessProfile(workoutDaysPerWeek: 0))
            .filter { $0 != .rest }.count, 2)
        XCTAssertEqual(WorkoutPlanGenerator.weeklySplit(for: FitnessProfile(workoutDaysPerWeek: 10))
            .filter { $0 != .rest }.count, 6)
    }

    func testDeterminism() {
        let d = date(2026, 7, 6)
        let a = WorkoutPlanGenerator.plan(for: .default, date: d, calendar: utcCalendar)
        let b = WorkoutPlanGenerator.plan(for: .default, date: d, calendar: utcCalendar)
        XCTAssertEqual(a, b)
    }

    func testMondayIsWorkoutDayForDefaultProfile() {
        let plan = WorkoutPlanGenerator.plan(for: .default, date: date(2026, 7, 6), calendar: utcCalendar)
        XCTAssertEqual(plan.focus, .fullBody)     // beginner 3-day split starts Monday
        XCTAssertFalse(plan.items.isEmpty)
        XCTAssertGreaterThan(plan.estimatedMinutes, 0)
        XCTAssertFalse(plan.title.isEmpty)
        XCTAssertTrue(plan.items.allSatisfy { $0.sets == 3 })   // beginner
        XCTAssertGreaterThan(plan.estimatedCalories(weightKg: 75), 0)
    }

    func testTuesdayIsRestDayForDefaultProfile() {
        let plan = WorkoutPlanGenerator.plan(for: .default, date: date(2026, 7, 7), calendar: utcCalendar)
        XCTAssertEqual(plan.focus, .rest)
        XCTAssertTrue(plan.items.isEmpty)
        XCTAssertEqual(plan.estimatedMinutes, 0)
    }

    func testPlansVaryAcrossDates() {
        var distinctItemSets = Set<Set<String>>()
        for day in 0..<28 {
            let d = utcCalendar.date(byAdding: .day, value: day, to: date(2026, 7, 6))!
            let plan = WorkoutPlanGenerator.plan(for: .default, date: d, calendar: utcCalendar)
            guard plan.focus != .rest else { continue }
            distinctItemSets.insert(Set(plan.items.map(\.id)))
        }
        XCTAssertGreaterThanOrEqual(distinctItemSets.count, 2,
                                    "a month of plans should not be identical")
    }

    func testInjuryFilteringExcludesContraindicatedExercises() {
        let p = FitnessProfile(injuries: [.knee])
        for day in 0..<7 {
            let d = utcCalendar.date(byAdding: .day, value: day, to: date(2026, 7, 6))!
            let plan = WorkoutPlanGenerator.plan(for: p, date: d, calendar: utcCalendar)
            for item in plan.items {
                XCTAssertFalse(item.exercise.contraindications.contains(.knee),
                               "\(item.id) is contraindicated for knees")
            }
        }
    }

    func testBodyweightProfileNeverGetsEquipmentExercises() {
        for day in 0..<7 {
            let d = utcCalendar.date(byAdding: .day, value: day, to: date(2026, 7, 6))!
            let plan = WorkoutPlanGenerator.plan(for: .default, date: d, calendar: utcCalendar)
            for item in plan.items {
                XCTAssertTrue(item.exercise.equipment.contains(.none),
                              "\(item.id) needs equipment the user doesn't have")
            }
        }
    }

    func testFullGymAdvancedUpperDayUsesEquipment() {
        let p = FitnessProfile(experience: .advanced, equipment: [.fullGym],
                               workoutDaysPerWeek: 4, sessionMinutes: 45)
        // 4-day split: Monday = upperBody. Advanced 45 min → 6 exercises; the upper-body pool
        // has only 4 bodyweight options, so equipment work is guaranteed.
        let plan = WorkoutPlanGenerator.plan(for: p, date: date(2026, 7, 6), calendar: utcCalendar)
        XCTAssertEqual(plan.focus, .upperBody)
        XCTAssertTrue(plan.items.contains { !$0.exercise.equipment.contains(.none) })
        XCTAssertTrue(plan.items.allSatisfy { $0.sets == 4 })   // advanced
    }

    func testGoalDrivesPrescription() {
        var p = FitnessProfile.default
        p.goal = .gainMuscle
        let plan = WorkoutPlanGenerator.plan(for: p, date: date(2026, 7, 6), calendar: utcCalendar)
        for item in plan.items {
            XCTAssertEqual(item.restSeconds, 90)
            if case .reps(let n) = item.kind {
                XCTAssertTrue((8...12).contains(n), "gainMuscle reps out of range: \(n)")
            }
        }
    }
}
