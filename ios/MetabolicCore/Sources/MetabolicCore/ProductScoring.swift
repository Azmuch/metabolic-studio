import Foundation

public struct ScannedProduct: Codable, Equatable, Sendable {
    public var barcode: String
    public var name: String
    public var brand: String?
    public var imageURLString: String?
    public var isBeverage: Bool
    public var isOrganic: Bool
    // Per 100 g (solids) / 100 ml (beverages):
    public var energyKcal: Double?
    public var sugarsG: Double?
    public var satFatG: Double?
    public var sodiumMg: Double?
    public var fiberG: Double?
    public var proteinG: Double?
    public var fruitVegPercent: Double?
    public var additives: [String]
    public var categories: [String]

    public init(barcode: String, name: String, brand: String? = nil,
                imageURLString: String? = nil, isBeverage: Bool = false,
                isOrganic: Bool = false, energyKcal: Double? = nil,
                sugarsG: Double? = nil, satFatG: Double? = nil,
                sodiumMg: Double? = nil, fiberG: Double? = nil,
                proteinG: Double? = nil, fruitVegPercent: Double? = nil,
                additives: [String] = [], categories: [String] = []) {
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.imageURLString = imageURLString
        self.isBeverage = isBeverage
        self.isOrganic = isOrganic
        self.energyKcal = energyKcal
        self.sugarsG = sugarsG
        self.satFatG = satFatG
        self.sodiumMg = sodiumMg
        self.fiberG = fiberG
        self.proteinG = proteinG
        self.fruitVegPercent = fruitVegPercent
        self.additives = additives
        self.categories = categories
    }
}

public enum ScoreRating: String, Codable, Sendable {
    case excellent, good, poor, bad          // 75–100 / 50–74 / 25–49 / 0–24

    public var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .poor: return "Poor"
        case .bad: return "Bad"
        }
    }

    public static func rating(for value: Int) -> ScoreRating {
        switch value {
        case 75...: return .excellent
        case 50...74: return .good
        case 25...49: return .poor
        default: return .bad
        }
    }
}

public struct ScoreFactor: Identifiable, Codable, Equatable, Sendable {
    public var id: String { title }
    public var title: String
    public var detail: String
    public var isPositive: Bool
    public var symbolName: String

    public init(title: String, detail: String, isPositive: Bool, symbolName: String) {
        self.title = title
        self.detail = detail
        self.isPositive = isPositive
        self.symbolName = symbolName
    }
}

public struct ProductScore: Codable, Equatable, Sendable {
    public var value: Int                    // 0...100
    public var rating: ScoreRating
    public var positives: [ScoreFactor]
    public var negatives: [ScoreFactor]

    public init(value: Int, rating: ScoreRating, positives: [ScoreFactor], negatives: [ScoreFactor]) {
        self.value = value
        self.rating = rating
        self.positives = positives
        self.negatives = negatives
    }
}

/// How well a product fits *this* user's declared goal — the personalized second layer on top
/// of the standards-based health score. Kept strictly separate so the base number stays
/// comparable with other Nutri-Score-derived apps (Yuka et al.).
public enum FitVerdict: String, Codable, Sendable {
    case strong, mixed, caution

    public var displayName: String {
        switch self {
        case .strong: return "Fits your goal"
        case .mixed: return "Situational"
        case .caution: return "Off-plan"
        }
    }

    public var symbolName: String {
        switch self {
        case .strong: return "hand.thumbsup.fill"
        case .mixed: return "hand.raised.fill"
        case .caution: return "hand.thumbsdown.fill"
        }
    }
}

public struct PersonalFit: Codable, Equatable, Sendable {
    public var verdict: FitVerdict
    public var factors: [ScoreFactor]

    public init(verdict: FitVerdict, factors: [ScoreFactor]) {
        self.verdict = verdict
        self.factors = factors
    }
}

/// Yuka-style blend: 60% nutrition (Nutri-Score 2017 point tables), 30% additive risk,
/// 10% organic — with hard caps so a risky additive can never hide behind good macros.
public enum ProductScoringEngine {

    public static func score(_ product: ScannedProduct) -> ProductScore {
        let nutrition = nutritionSubscore(product)
        var seen = Set<String>()
        let uniqueAdditives = product.additives.map(AdditiveTable.normalize)
            .filter { seen.insert($0).inserted }
        let worstRisk = uniqueAdditives.map(AdditiveTable.risk(for:)).max() ?? AdditiveRisk.none

        let additiveSubscore: Double
        if uniqueAdditives.isEmpty {
            additiveSubscore = 100
        } else {
            switch worstRisk {
            case .none: additiveSubscore = 100
            case .limited: additiveSubscore = 70
            case .moderate: additiveSubscore = 35
            case .high: additiveSubscore = 0
            }
        }

        let organicSubscore: Double = product.isOrganic ? 100 : 0

        var total = Int((0.6 * nutrition + 0.3 * additiveSubscore + 0.1 * organicSubscore).rounded())
        if worstRisk == .high { total = min(total, 49) }
        else if worstRisk == .moderate { total = min(total, 74) }
        total = min(max(total, 0), 100)

        let (positives, negatives) = factors(for: product, uniqueAdditives: uniqueAdditives, worstRisk: worstRisk)

        return ProductScore(value: total, rating: ScoreRating.rating(for: total),
                            positives: positives, negatives: negatives)
    }

    // MARK: - Personal fit (goal-aware second layer)

    /// Evaluates the product against the user's primary goal. Rules are deliberately simple and
    /// explainable: protein density (g per 100 kcal), energy density, sugar, fiber, and sodium,
    /// each thresholded per goal. Returns a verdict plus the reasons behind it.
    public static func personalFit(_ p: ScannedProduct, goal: FitnessGoal) -> PersonalFit {
        var pros: [ScoreFactor] = []
        var cons: [ScoreFactor] = []
        let unit = p.isBeverage ? "100 ml" : "100 g"

        let kcal = p.energyKcal ?? 0
        let protein = p.proteinG ?? 0
        let sugars = p.sugarsG ?? 0
        let fiber = p.fiberG ?? 0
        let sodium = p.sodiumMg ?? 0
        // Protein density: grams of protein per 100 kcal — load-bearing for every training goal.
        let proteinDensity = kcal > 0 ? protein / kcal * 100 : 0

        if proteinDensity >= 8 {
            pros.append(ScoreFactor(
                title: "Protein dense",
                detail: String(format: "%.0f g of protein per 100 kcal — efficient for your training.", proteinDensity),
                isPositive: true, symbolName: "bolt.fill"))
        }

        switch goal {
        case .gainMuscle:
            if kcal >= 250 && proteinDensity >= 6 {
                pros.append(ScoreFactor(
                    title: "Building fuel",
                    detail: "Calorie-dense with solid protein — useful in a surplus.",
                    isPositive: true, symbolName: "dumbbell.fill"))
            }
            if sugars > 22.5 {
                cons.append(ScoreFactor(
                    title: "Sugar-heavy calories",
                    detail: String(format: "%.0f g sugar per %@ — surplus calories better spent on protein.", sugars, unit),
                    isPositive: false, symbolName: "cube.fill"))
            }
        case .loseFat:
            if kcal > 0 && kcal <= (p.isBeverage ? 25 : 120) {
                pros.append(ScoreFactor(
                    title: "Light on calories",
                    detail: String(format: "Only %.0f kcal per %@ — easy to fit in a deficit.", kcal, unit),
                    isPositive: true, symbolName: "feather"))
            }
            if !p.isBeverage && kcal > 350 {
                cons.append(ScoreFactor(
                    title: "Energy dense",
                    detail: String(format: "%.0f kcal per %@ — portion carefully while cutting.", kcal, unit),
                    isPositive: false, symbolName: "flame.fill"))
            }
            if sugars > (p.isBeverage ? 6 : 13.5) {
                cons.append(ScoreFactor(
                    title: "High sugar for a cut",
                    detail: String(format: "%.1f g sugar per %@.", sugars, unit),
                    isPositive: false, symbolName: "cube.fill"))
            }
            if fiber > 3.7 {
                pros.append(ScoreFactor(
                    title: "Keeps you full",
                    detail: String(format: "%.1f g fiber per %@ helps satiety in a deficit.", fiber, unit),
                    isPositive: true, symbolName: "leaf.fill"))
            }
        case .improveEndurance:
            if p.isBeverage && sodium > 0 && sodium <= 450 && sugars > 0 && sugars <= 9 {
                pros.append(ScoreFactor(
                    title: "Session-friendly",
                    detail: "Moderate sugar and electrolytes suit longer efforts.",
                    isPositive: true, symbolName: "figure.run"))
            }
            if fiber > 3.7 {
                pros.append(ScoreFactor(
                    title: "Steady energy",
                    detail: String(format: "%.1f g fiber per %@ smooths energy release.", fiber, unit),
                    isPositive: true, symbolName: "leaf.fill"))
            }
        case .maintain, .improveMobility:
            if fiber > 3.7 {
                pros.append(ScoreFactor(
                    title: "Good fiber",
                    detail: String(format: "%.1f g fiber per %@.", fiber, unit),
                    isPositive: true, symbolName: "leaf.fill"))
            }
        }

        if sodium > 720 {
            cons.append(ScoreFactor(
                title: "High sodium",
                detail: String(format: "%.0f mg per %@ — heavy for daily use.", sodium, unit),
                isPositive: false, symbolName: "aqi.medium"))
        }

        let verdict: FitVerdict
        if cons.isEmpty && !pros.isEmpty {
            verdict = .strong
        } else if pros.isEmpty && !cons.isEmpty {
            verdict = .caution
        } else {
            verdict = .mixed
        }
        return PersonalFit(verdict: verdict, factors: pros + cons)
    }

    // MARK: - Nutrition (Nutri-Score points per 100 g/ml, 2017 tables)

    static func nutritionSubscore(_ p: ScannedProduct) -> Double {
        let energyKJ = (p.energyKcal ?? 0) * 4.184
        let sugars = p.sugarsG ?? 0
        let satFat = p.satFatG ?? 0
        let sodium = p.sodiumMg ?? 0
        let fiber = p.fiberG ?? 0
        let protein = p.proteinG ?? 0
        let fruitVeg = p.fruitVegPercent ?? 0

        let energyPoints: Int
        let sugarPoints: Int
        let fruitVegPoints: Int
        if p.isBeverage {
            energyPoints = points(energyKJ, over: [0, 30, 60, 90, 120, 150, 180, 210, 240, 270])
            sugarPoints = points(sugars, over: [0, 1.5, 3, 4.5, 6, 7.5, 9, 10.5, 12, 13.5])
            fruitVegPoints = fruitVeg > 80 ? 10 : fruitVeg > 60 ? 4 : fruitVeg > 40 ? 2 : 0
        } else {
            energyPoints = points(energyKJ, over: [335, 670, 1005, 1340, 1675, 2010, 2345, 2680, 3015, 3350])
            sugarPoints = points(sugars, over: [4.5, 9, 13.5, 18, 22.5, 27, 31, 36, 40, 45])
            fruitVegPoints = fruitVeg > 80 ? 5 : fruitVeg > 60 ? 2 : fruitVeg > 40 ? 1 : 0
        }
        let satFatPoints = points(satFat, over: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        let sodiumPoints = points(sodium, over: [90, 180, 270, 360, 450, 540, 630, 720, 810, 900])

        let fiberPoints = points(fiber, over: [0.9, 1.9, 2.8, 3.7, 4.7])
        let proteinPoints = points(protein, over: [1.6, 3.2, 4.8, 6.4, 8.0])

        let negative = energyPoints + sugarPoints + satFatPoints + sodiumPoints
        // Classic rule: high-negative products only get protein credit alongside strong fruit/veg.
        var positive = fiberPoints + fruitVegPoints
        if !(negative >= 11 && fruitVegPoints < 5) {
            positive += proteinPoints
        }

        let nutriScore = Double(negative - positive)               // −15 ... 40
        return min(max((40 - nutriScore) / 55 * 100, 0), 100)
    }

    private static func points(_ value: Double, over thresholds: [Double]) -> Int {
        thresholds.reduce(0) { $0 + (value > $1 ? 1 : 0) }
    }

    // MARK: - Human-readable factors

    private static func factors(for p: ScannedProduct, uniqueAdditives: [String],
                                worstRisk: AdditiveRisk) -> ([ScoreFactor], [ScoreFactor]) {
        var positives: [ScoreFactor] = []
        var negatives: [ScoreFactor] = []
        let unit = p.isBeverage ? "100 ml" : "100 g"

        if p.energyKcal == nil {
            negatives.append(ScoreFactor(
                title: "Incomplete data",
                detail: "Nutrition facts are missing for this product, so the score is conservative.",
                isPositive: false, symbolName: "questionmark.circle.fill"))
        }
        if let sugars = p.sugarsG, sugars > (p.isBeverage ? 6 : 13.5) {
            negatives.append(ScoreFactor(
                title: "High sugar",
                detail: String(format: "%.1f g of sugar per %@.", sugars, unit),
                isPositive: false, symbolName: "cube.fill"))
        }
        if let satFat = p.satFatG, satFat > 5 {
            negatives.append(ScoreFactor(
                title: "High saturated fat",
                detail: String(format: "%.1f g of saturated fat per %@.", satFat, unit),
                isPositive: false, symbolName: "drop.triangle.fill"))
        }
        if let sodium = p.sodiumMg, sodium > 630 {
            negatives.append(ScoreFactor(
                title: "High sodium",
                detail: String(format: "%.0f mg of sodium per %@.", sodium, unit),
                isPositive: false, symbolName: "aqi.medium"))
        }
        if !p.isBeverage, let kcal = p.energyKcal, kcal > 400 {
            negatives.append(ScoreFactor(
                title: "Energy dense",
                detail: String(format: "%.0f kcal per %@.", kcal, unit),
                isPositive: false, symbolName: "flame.fill"))
        }
        for code in uniqueAdditives {
            let risk = AdditiveTable.risk(for: code)
            guard risk >= .moderate else { continue }
            negatives.append(ScoreFactor(
                title: "Additive \(code.uppercased())",
                detail: "\(AdditiveTable.name(for: code)) — \(risk.displayName.lowercased()).",
                isPositive: false,
                symbolName: risk == .high ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill"))
        }

        if let fiber = p.fiberG, fiber > 2.8 {
            positives.append(ScoreFactor(
                title: "Good fiber",
                detail: String(format: "%.1f g of fiber per %@.", fiber, unit),
                isPositive: true, symbolName: "leaf.fill"))
        }
        if let protein = p.proteinG, protein > 6.4 {
            positives.append(ScoreFactor(
                title: "Protein rich",
                detail: String(format: "%.1f g of protein per %@.", protein, unit),
                isPositive: true, symbolName: "bolt.fill"))
        }
        if let fruitVeg = p.fruitVegPercent, fruitVeg > 60 {
            positives.append(ScoreFactor(
                title: "Mostly fruit & veg",
                detail: String(format: "About %.0f%% fruits, vegetables or nuts.", fruitVeg),
                isPositive: true, symbolName: "carrot.fill"))
        }
        if let sugars = p.sugarsG, sugars <= (p.isBeverage ? 0.5 : 4.5), p.energyKcal != nil {
            positives.append(ScoreFactor(
                title: "Low sugar",
                detail: String(format: "Only %.1f g of sugar per %@.", sugars, unit),
                isPositive: true, symbolName: "checkmark.seal.fill"))
        }
        if worstRisk < .moderate {
            positives.append(ScoreFactor(
                title: "No risky additives",
                detail: uniqueAdditives.isEmpty
                    ? "No additives listed."
                    : "No moderate- or high-risk additives detected.",
                isPositive: true, symbolName: "checkmark.shield.fill"))
        }
        if p.isOrganic {
            positives.append(ScoreFactor(
                title: "Organic",
                detail: "Carries an organic certification label.",
                isPositive: true, symbolName: "leaf.circle.fill"))
        }

        return (positives, negatives)
    }
}
