import Foundation

public struct NutritionTargets: Codable, Equatable, Sendable {
    public var calories: Int
    public var proteinG: Int
    public var carbsG: Int
    public var fatG: Int
    public var waterML: Int

    public init(calories: Int, proteinG: Int, carbsG: Int, fatG: Int, waterML: Int) {
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.waterML = waterML
    }
}

public enum NutritionEngine {
    /// Mifflin-St Jeor: 10w + 6.25h − 5a + (male ? +5 : −161)
    public static func bmr(for p: FitnessProfile) -> Double {
        let base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * Double(p.age)
        return base + (p.sex == .male ? 5 : -161)
    }

    /// bmr × activity multiplier
    public static func tdee(for p: FitnessProfile) -> Double {
        bmr(for: p) * p.activityLevel.multiplier
    }

    public static func targets(for p: FitnessProfile) -> NutritionTargets {
        let tdeeValue = tdee(for: p)

        let goalAdjustment: Double
        switch p.goal {
        case .loseFat: goalAdjustment = -0.20
        case .maintain: goalAdjustment = 0
        case .gainMuscle: goalAdjustment = 0.12
        case .improveEndurance: goalAdjustment = 0.05
        }

        var calories = (tdeeValue * (1 + goalAdjustment)).rounded()

        let floor: Double = p.sex == .female ? 1200 : 1500
        calories = max(calories, floor)

        let proteinPerKg: Double
        switch p.goal {
        case .loseFat: proteinPerKg = 2.0
        case .maintain: proteinPerKg = 1.6
        case .gainMuscle: proteinPerKg = 2.0
        case .improveEndurance: proteinPerKg = 1.6
        }
        let proteinG = (proteinPerKg * p.weightKg).rounded()

        let fatG = (0.27 * calories / 9).rounded()
        let carbsG = max(0, ((calories - proteinG * 4 - fatG * 9) / 4).rounded())

        let waterRaw = (35 * p.weightKg / 50).rounded() * 50
        let waterML = min(max(waterRaw, 1500), 4000)

        return NutritionTargets(
            calories: Int(calories),
            proteinG: Int(proteinG),
            carbsG: Int(carbsG),
            fatG: Int(fatG),
            waterML: Int(waterML)
        )
    }
}

public enum CalorieBurnCalculator {
    /// kcal = MET × 3.5 × kg / 200 × minutes
    public static func kilocalories(met: Double, weightKg: Double, minutes: Double) -> Double {
        met * 3.5 * weightKg / 200 * minutes
    }
}
