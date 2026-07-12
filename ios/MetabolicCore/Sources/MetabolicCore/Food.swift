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

/// Dietary composition tags used to honor preferences and exclude allergens
/// when generating meal plans.
public enum FoodTag: String, Codable, CaseIterable, Sendable {
    case meat, poultry, fish, shellfish, dairy, egg, gluten, nuts, soy
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
    public var tags: Set<FoodTag>

    public init(id: String, name: String, brand: String? = nil, servingDescription: String,
                calories: Double, proteinG: Double, carbsG: Double, fatG: Double,
                tags: Set<FoodTag> = []) {
        self.id = id
        self.name = name
        self.brand = brand
        self.servingDescription = servingDescription
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.tags = tags
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        brand = try c.decodeIfPresent(String.self, forKey: .brand)
        servingDescription = try c.decode(String.self, forKey: .servingDescription)
        calories = try c.decode(Double.self, forKey: .calories)
        proteinG = try c.decode(Double.self, forKey: .proteinG)
        carbsG = try c.decode(Double.self, forKey: .carbsG)
        fatG = try c.decode(Double.self, forKey: .fatG)
        tags = try c.decodeIfPresent(Set<FoodTag>.self, forKey: .tags) ?? []
    }

    /// True when this food violates neither the diet style nor any listed allergy.
    public func isCompatible(with preference: DietaryPreference,
                             allergies: Set<FoodAllergen>) -> Bool {
        switch preference {
        case .none:
            break
        case .vegetarian:
            if !tags.isDisjoint(with: [.meat, .poultry, .fish, .shellfish]) { return false }
        case .vegan:
            if !tags.isDisjoint(with: [.meat, .poultry, .fish, .shellfish, .dairy, .egg]) { return false }
        case .pescatarian:
            if !tags.isDisjoint(with: [.meat, .poultry]) { return false }
        }
        for allergen in allergies {
            let excluded: FoodTag
            switch allergen {
            case .dairy: excluded = .dairy
            case .gluten: excluded = .gluten
            case .nuts: excluded = .nuts
            case .eggs: excluded = .egg
            case .soy: excluded = .soy
            case .fish: excluded = .fish
            case .shellfish: excluded = .shellfish
            }
            if tags.contains(excluded) { return false }
        }
        return true
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
