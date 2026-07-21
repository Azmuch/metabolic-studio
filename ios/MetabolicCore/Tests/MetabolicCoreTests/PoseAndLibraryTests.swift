import XCTest
@testable import MetabolicCore

final class PoseTests: XCTestCase {

    private let from = Pose([.head: PosePoint(0, 0)])
    private let to = Pose([.head: PosePoint(1, 1)])

    func testInterpolationEndpoints() {
        XCTAssertEqual(Pose.interpolate(from: from, to: to, t: 0).joints[.head], PosePoint(0, 0))
        XCTAssertEqual(Pose.interpolate(from: from, to: to, t: 1).joints[.head], PosePoint(1, 1))
    }

    func testSmoothstepMidpointAndShape() {
        let mid = Pose.interpolate(from: from, to: to, t: 0.5).joints[.head]!
        XCTAssertEqual(mid.x, 0.5, accuracy: 1e-9)          // smoothstep(0.5) == 0.5
        let quarter = Pose.interpolate(from: from, to: to, t: 0.25).joints[.head]!
        XCTAssertEqual(quarter.x, 0.15625, accuracy: 1e-9)  // 0.25²(3 − 0.5)
    }

    func testInterpolationClampsT() {
        XCTAssertEqual(Pose.interpolate(from: from, to: to, t: -3).joints[.head], PosePoint(0, 0))
        XCTAssertEqual(Pose.interpolate(from: from, to: to, t: 42).joints[.head], PosePoint(1, 1))
    }

    func testMissingJointFallsBack() {
        let partial = Pose.interpolate(from: Pose([.head: PosePoint(0.3, 0.3)]),
                                       to: Pose([:]), t: 0.9)
        XCTAssertEqual(partial.joints[.head], PosePoint(0.3, 0.3))
    }
}

final class ExerciseLibraryTests: XCTestCase {

    func testLibrarySizeAndUniqueIDs() {
        XCTAssertGreaterThanOrEqual(ExerciseLibrary.all.count, 22)
        XCTAssertEqual(Set(ExerciseLibrary.all.map(\.id)).count, ExerciseLibrary.all.count)
    }

    func testEveryExerciseIsWellFormed() {
        for exercise in ExerciseLibrary.all {
            XCTAssertGreaterThanOrEqual(exercise.keyframes.count, 2, exercise.id)
            XCTAssertGreaterThan(exercise.secondsPerCycle, 0, exercise.id)
            XCTAssertGreaterThanOrEqual(exercise.instructions.count, 3, exercise.id)
            XCTAssertGreaterThan(exercise.met, 0, exercise.id)
            XCTAssertFalse(exercise.muscleGroups.isEmpty, exercise.id)
            XCTAssertFalse(exercise.equipment.isEmpty, exercise.id)
            for (index, keyframe) in exercise.keyframes.enumerated() {
                XCTAssertEqual(keyframe.joints.count, Joint.allCases.count,
                               "\(exercise.id) keyframe \(index) is missing joints")
                for (joint, point) in keyframe.joints {
                    XCTAssertTrue((0...1).contains(point.x) && (0...1).contains(point.y),
                                  "\(exercise.id).\(joint.rawValue) out of bounds at keyframe \(index)")
                }
            }
        }
    }

    func testInjuryFiltering() {
        let kneeSafe = ExerciseLibrary.available(equipment: [.fullGym], injuries: [.knee])
        XCTAssertFalse(kneeSafe.contains { $0.contraindications.contains(.knee) })
        XCTAssertFalse(kneeSafe.contains { $0.id == "squat" })
        XCTAssertTrue(kneeSafe.contains { $0.id == "pushUp" })
    }

    func testEquipmentFiltering() {
        let bodyweight = ExerciseLibrary.available(equipment: [.none], injuries: [])
        XCTAssertTrue(bodyweight.allSatisfy { $0.equipment.contains(.none) })

        let dumbbells = ExerciseLibrary.available(equipment: [.dumbbells], injuries: [])
        XCTAssertTrue(dumbbells.contains { $0.id == "dbCurl" })
        XCTAssertFalse(dumbbells.contains { $0.id == "kbSwing" })
        XCTAssertFalse(dumbbells.contains { $0.id == "pullUp" })

        let gym = ExerciseLibrary.available(equipment: [.fullGym], injuries: [])
        XCTAssertTrue(gym.contains { $0.id == "pullUp" })
        XCTAssertTrue(gym.contains { $0.id == "kbSwing" })

        // Either-or equipment: goblet squat works with a kettlebell alone.
        let kettlebell = ExerciseLibrary.available(equipment: [.kettlebell], injuries: [])
        XCTAssertTrue(kettlebell.contains { $0.id == "gobletSquat" })
    }

    func testLookupByID() {
        XCTAssertNotNil(ExerciseLibrary.exercise(id: "squat"))
        XCTAssertNil(ExerciseLibrary.exercise(id: "underwater-basket-weaving"))
    }
}
