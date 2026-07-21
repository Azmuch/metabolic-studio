import Foundation
import MetabolicCore

/// Canned AI meal-photo analysis used when no Anthropic API key is stored but demo mode is
/// on, so the AI flow can be explored end-to-end without a live network call.
enum DemoMealAnalysis {
    static let sample = MealPhotoAnalysis(
        items: [
            AnalyzedFoodItem(
                name: "Grilled Chicken Breast",
                portionDescription: "1 medium breast",
                estimatedGrams: 150,
                calories: 248,
                proteinG: 46.5,
                carbsG: 0,
                fatG: 5.4,
                confidence: 0.92
            ),
            AnalyzedFoodItem(
                name: "Brown Rice",
                portionDescription: "1 cup, cooked",
                estimatedGrams: 180,
                calories: 199,
                proteinG: 4.6,
                carbsG: 41.3,
                fatG: 1.6,
                confidence: 0.85
            ),
            AnalyzedFoodItem(
                name: "Roasted Broccoli",
                portionDescription: "1 cup",
                estimatedGrams: 90,
                calories: 31,
                proteinG: 2.5,
                carbsG: 6,
                fatG: 0.3,
                confidence: 0.78
            ),
            AnalyzedFoodItem(
                name: "Olive Oil Drizzle",
                portionDescription: "2 tsp",
                estimatedGrams: 10,
                calories: 88,
                proteinG: 0,
                carbsG: 0,
                fatG: 10,
                confidence: 0.6
            ),
        ],
        notes: "Estimated visually from a single photo — actual values may vary with hidden sauces, oils, or dressings."
    )
}
