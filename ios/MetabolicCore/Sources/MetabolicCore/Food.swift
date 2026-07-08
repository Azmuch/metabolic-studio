import Foundation

public enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast, lunch, dinner, snack

    public var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    public var symbolName: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "sparkles"
        }
    }
}

public struct FoodItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var brand: String?
    public var servingDescription: String
    public var calories: Double
    public var proteinG: Double
    public var carbsG: Double
    public var fatG: Double

    public init(id: String, name: String, brand: String? = nil, servingDescription: String,
                calories: Double, proteinG: Double, carbsG: Double, fatG: Double) {
        self.id = id
        self.name = name
        self.brand = brand
        self.servingDescription = servingDescription
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }
}

public struct AnalyzedFoodItem: Codable, Equatable, Sendable, Identifiable {
    public var id: String { name }
    public var name: String
    public var portionDescription: String
    public var estimatedGrams: Double
    public var calories: Double
    public var proteinG: Double
    public var carbsG: Double
    public var fatG: Double
    public var confidence: Double            // 0...1

    public init(name: String, portionDescription: String, estimatedGrams: Double,
                calories: Double, proteinG: Double, carbsG: Double, fatG: Double,
                confidence: Double) {
        self.name = name
        self.portionDescription = portionDescription
        self.estimatedGrams = estimatedGrams
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.confidence = confidence
    }
}

public struct MealPhotoAnalysis: Codable, Equatable, Sendable {
    public var items: [AnalyzedFoodItem]
    public var notes: String?

    public var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }

    public init(items: [AnalyzedFoodItem], notes: String? = nil) {
        self.items = items
        self.notes = notes
    }
}
