import XCTest
@testable import MetabolicCore

final class NutritionEngineTests: XCTestCase {

    func testDefaultProfileBMRAndTDEE() {
        let p = FitnessProfile.default   // 30y male, 175 cm, 75 kg, moderate
        XCTAssertEqual(NutritionEngine.bmr(for: p), 1698.75, accuracy: 0.001)
        XCTAssertEqual(NutritionEngine.tdee(for: p), 2633.0625, accuracy: 0.001)
    }

    func testDefaultProfileTargets() {
        let t = NutritionEngine.targets(for: .default)
        XCTAssertEqual(t.calories, 2633)
        XCTAssertEqual(t.proteinG, 120)      // 1.6 g/kg × 75
        XCTAssertEqual(t.fatG, 79)           // 27% of calories / 9
        XCTAssertEqual(t.carbsG, 361)        // remainder / 4
        XCTAssertEqual(t.waterML, 2650)      // 35 ml/kg rounded to 50
    }

    func testFemaleCalorieFloor() {
        let p = FitnessProfile(age: 60, sex: .female, heightCm: 150, weightKg: 45,
                               goal: .loseFat, activityLevel: .sedentary)
        // Raw: (926.5 × 1.2) × 0.8 ≈ 889 — must be floored.
        XCTAssertEqual(NutritionEngine.targets(for: p).calories, 1200)
    }

    func testWaterClamps() {
        let light = FitnessProfile(sex: .female, weightKg: 40)
        XCTAssertEqual(NutritionEngine.targets(for: light).waterML, 1500)
        let heavy = FitnessProfile(weightKg: 130)
        XCTAssertEqual(NutritionEngine.targets(for: heavy).waterML, 4000)
    }

    func testMacroEnergyConsistency() {
        let profiles = [
            FitnessProfile.default,
            FitnessProfile(age: 25, sex: .female, heightCm: 165, weightKg: 60, goal: .loseFat),
            FitnessProfile(age: 40, sex: .male, heightCm: 185, weightKg: 95, goal: .gainMuscle,
                           activityLevel: .active),
            FitnessProfile(age: 33, sex: .female, heightCm: 170, weightKg: 68,
                           goal: .improveEndurance, activityLevel: .veryActive),
        ]
        for p in profiles {
            let t = NutritionEngine.targets(for: p)
            let energy = t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9
            XCTAssertLessThanOrEqual(abs(energy - t.calories), 20,
                                     "macros drift from calories for \(p)")
        }
    }

    func testGoalOrdering() {
        let base = FitnessProfile.default
        var cut = base; cut.goal = .loseFat
        var bulk = base; bulk.goal = .gainMuscle
        XCTAssertLessThan(NutritionEngine.targets(for: cut).calories,
                          NutritionEngine.targets(for: base).calories)
        XCTAssertGreaterThan(NutritionEngine.targets(for: bulk).calories,
                             NutritionEngine.targets(for: base).calories)
    }

    func testCalorieBurnFormula() {
        // MET 5 × 3.5 × 75 kg / 200 × 30 min
        XCTAssertEqual(CalorieBurnCalculator.kilocalories(met: 5, weightKg: 75, minutes: 30),
                       196.875, accuracy: 0.001)
    }
}
