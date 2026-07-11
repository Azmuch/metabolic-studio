import SwiftUI
import SwiftData
import MetabolicCore

/// Origin of a logged food entry.
enum FoodEntrySource: String, Codable, CaseIterable {
    case manual, search, photo, barcode
}

@Model
final class FoodEntry {
    var date: Date
    var mealTypeRaw: String
    var name: String
    var brand: String?
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var grams: Double?
    var sourceRaw: String

    init(
        date: Date,
        mealType: MealType,
        name: String,
        brand: String? = nil,
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        grams: Double? = nil,
        source: FoodEntrySource
    ) {
        self.date = date
        self.mealTypeRaw = mealType.rawValue
        self.name = name
        self.brand = brand
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.grams = grams
        self.sourceRaw = source.rawValue
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snack }
        set { mealTypeRaw = newValue.rawValue }
    }

    var source: FoodEntrySource {
        get { FoodEntrySource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}

@Model
final class WaterEntry {
    var date: Date
    var amountML: Int

    init(date: Date, amountML: Int) {
        self.date = date
        self.amountML = amountML
    }
}

@Model
final class WorkoutLog {
    var date: Date
    var title: String
    var focusRaw: String
    var minutes: Int
    var calories: Int
    var completedExerciseIDs: [String]
    /// Total lifted volume (Σ sets × reps × load in kg) for hypertrophy tracking.
    var totalVolumeKg: Double = 0

    init(
        date: Date,
        title: String,
        focus: DayFocus,
        minutes: Int,
        calories: Int,
        completedExerciseIDs: [String] = [],
        totalVolumeKg: Double = 0
    ) {
        self.date = date
        self.title = title
        self.focusRaw = focus.rawValue
        self.minutes = minutes
        self.calories = calories
        self.completedExerciseIDs = completedExerciseIDs
        self.totalVolumeKg = totalVolumeKg
    }

    var focus: DayFocus {
        get { DayFocus(rawValue: focusRaw) ?? .fullBody }
        set { focusRaw = newValue.rawValue }
    }
}

@Model
final class WeightEntry {
    var date: Date
    var weightKg: Double

    init(date: Date, weightKg: Double) {
        self.date = date
        self.weightKg = weightKg
    }
}

@Model
final class ScanRecord {
    var date: Date
    var barcode: String
    var name: String
    var brand: String?
    var scoreValue: Int
    var ratingRaw: String
    var imageURLString: String?

    init(
        date: Date,
        barcode: String,
        name: String,
        brand: String? = nil,
        scoreValue: Int,
        rating: ScoreRating,
        imageURLString: String? = nil
    ) {
        self.date = date
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.scoreValue = scoreValue
        self.ratingRaw = rating.rawValue
        self.imageURLString = imageURLString
    }

    var rating: ScoreRating {
        get { ScoreRating(rawValue: ratingRaw) ?? .poor }
        set { ratingRaw = newValue.rawValue }
    }
}
