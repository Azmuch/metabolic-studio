import XCTest
@testable import MetabolicCore

final class ProductScoringTests: XCTestCase {

    func testSodaScoresPoorWithHighRiskAdditiveCap() {
        let soda = ScannedProduct(
            barcode: "0001", name: "Cola", isBeverage: true,
            energyKcal: 42, sugarsG: 10.6, satFatG: 0, sodiumMg: 10,
            fiberG: 0, proteinG: 0,
            additives: ["e150d", "e951"]
        )
        let score = ProductScoringEngine.score(soda)
        // Beverage points: energy 6 + sugars 8 = 14 → nutrition 47.27 → 0.6× ≈ 28,
        // additives high-risk → 0, capped at 49.
        XCTAssertEqual(score.value, 28)
        XCTAssertEqual(score.rating, .poor)
        XCTAssertTrue(score.negatives.contains { $0.title == "High sugar" })
        XCTAssertTrue(score.negatives.contains { $0.title == "Additive E951" })
    }

    func testOrganicWaterScoresExcellent() {
        let water = ScannedProduct(
            barcode: "0002", name: "Spring Water", isBeverage: true, isOrganic: true,
            energyKcal: 0, sugarsG: 0, satFatG: 0, sodiumMg: 2, fiberG: 0, proteinG: 0
        )
        let score = ProductScoringEngine.score(water)
        // Nutrition 72.73 → 43.64 + additives 30 + organic 10 = 84.
        XCTAssertEqual(score.value, 84)
        XCTAssertEqual(score.rating, .excellent)
        XCTAssertTrue(score.positives.contains { $0.title == "No risky additives" })
        XCTAssertTrue(score.positives.contains { $0.title == "Organic" })
    }

    func testAlmondsScoreGoodWithFiberAndProteinFactors() {
        let almonds = ScannedProduct(
            barcode: "0003", name: "Raw Almonds",
            energyKcal: 600, sugarsG: 4, satFatG: 7, sodiumMg: 1,
            fiberG: 10, proteinG: 21
        )
        let score = ProductScoringEngine.score(almonds)
        // Points: energy 7 + satFat 6 = 13 negative; fiber 5 positive (protein suppressed by
        // the ≥11-negative rule) → Nutri-Score 8 → 58.18 → 34.9 + 30 additives = 65.
        XCTAssertEqual(score.value, 65)
        XCTAssertEqual(score.rating, .good)
        XCTAssertTrue(score.positives.contains { $0.title == "Good fiber" })
        XCTAssertTrue(score.positives.contains { $0.title == "Protein rich" })
        XCTAssertTrue(score.negatives.contains { $0.title == "High saturated fat" })
        XCTAssertTrue(score.negatives.contains { $0.title == "Energy dense" })
    }

    func testHighRiskAdditiveCapsScoreAt49() {
        let product = ScannedProduct(
            barcode: "0004", name: "Organic Sweet Drink Mix", isOrganic: true,
            energyKcal: 0, sugarsG: 0, satFatG: 0, sodiumMg: 0, fiberG: 0, proteinG: 0,
            additives: ["e951"]
        )
        // Uncapped this would be 54 (43.64 + 0 + 10); the high-risk cap pins it to 49.
        let score = ProductScoringEngine.score(product)
        XCTAssertEqual(score.value, 49)
        XCTAssertEqual(score.rating, .poor)
    }

    func testModerateAdditiveNeverExceeds74() {
        let product = ScannedProduct(
            barcode: "0005", name: "Organic Broth", isOrganic: true,
            energyKcal: 0, sugarsG: 0, satFatG: 0, sodiumMg: 0, fiberG: 0, proteinG: 0,
            additives: ["e621"]
        )
        let score = ProductScoringEngine.score(product)
        XCTAssertEqual(score.value, 64)
        XCTAssertLessThanOrEqual(score.value, 74)
    }

    func testMissingNutritionDataIsFlagged() {
        let mystery = ScannedProduct(barcode: "0006", name: "Mystery Snack")
        let score = ProductScoringEngine.score(mystery)
        XCTAssertTrue(score.negatives.contains { $0.title == "Incomplete data" })
    }

    func testBeverageThresholdsAreStricterThanSolids() {
        let asSolid = ScannedProduct(barcode: "s", name: "X", isBeverage: false,
                                     energyKcal: 42, sugarsG: 10.6, satFatG: 0,
                                     sodiumMg: 10, fiberG: 0, proteinG: 0)
        let asBeverage = ScannedProduct(barcode: "b", name: "X", isBeverage: true,
                                        energyKcal: 42, sugarsG: 10.6, satFatG: 0,
                                        sodiumMg: 10, fiberG: 0, proteinG: 0)
        XCTAssertGreaterThan(ProductScoringEngine.score(asSolid).value,
                             ProductScoringEngine.score(asBeverage).value)
    }

    func testRatingBands() {
        XCTAssertEqual(ScoreRating.rating(for: 100), .excellent)
        XCTAssertEqual(ScoreRating.rating(for: 75), .excellent)
        XCTAssertEqual(ScoreRating.rating(for: 74), .good)
        XCTAssertEqual(ScoreRating.rating(for: 50), .good)
        XCTAssertEqual(ScoreRating.rating(for: 49), .poor)
        XCTAssertEqual(ScoreRating.rating(for: 25), .poor)
        XCTAssertEqual(ScoreRating.rating(for: 24), .bad)
        XCTAssertEqual(ScoreRating.rating(for: 0), .bad)
    }
}

final class AdditiveTableTests: XCTestCase {

    func testLookupNormalization() {
        XCTAssertEqual(AdditiveTable.risk(for: "e330"), .none)
        XCTAssertEqual(AdditiveTable.risk(for: "E330"), .none)
        XCTAssertEqual(AdditiveTable.risk(for: "en:e330"), .none)
        XCTAssertEqual(AdditiveTable.risk(for: " e330 "), .none)
    }

    func testKnownRisks() {
        XCTAssertEqual(AdditiveTable.risk(for: "e102"), .high)
        XCTAssertEqual(AdditiveTable.risk(for: "e250"), .high)
        XCTAssertEqual(AdditiveTable.risk(for: "e621"), .moderate)
        XCTAssertEqual(AdditiveTable.risk(for: "e202"), .limited)
        XCTAssertEqual(AdditiveTable.risk(for: "e300"), .none)
    }

    func testUnknownDefaultsToLimited() {
        XCTAssertEqual(AdditiveTable.risk(for: "e9999"), .limited)
    }

    func testNames() {
        XCTAssertEqual(AdditiveTable.name(for: "en:e951"), "Aspartame")
        XCTAssertEqual(AdditiveTable.name(for: "e9999"), "E9999")
    }

    func testRiskOrdering() {
        XCTAssertLessThan(AdditiveRisk.none, .limited)
        XCTAssertLessThan(AdditiveRisk.limited, .moderate)
        XCTAssertLessThan(AdditiveRisk.moderate, .high)
    }
}
