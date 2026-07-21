import SwiftUI
import MetabolicCore

/// Builds a single combined CSV export (foods, workouts, weights) for the Pro data-export
/// feature. Writes to the temp directory and returns the file URL for `ShareLink`.
enum CSVExporter {
    static func export(foods: [FoodEntry], workouts: [WorkoutLog], weights: [WeightEntry]) -> URL? {
        var lines: [String] = []

        lines.append("# Foods")
        lines.append("date,meal,name,brand,calories,protein_g,carbs_g,fat_g,grams,source")
        for food in foods.sorted(by: { $0.date < $1.date }) {
            lines.append([
                iso(food.date),
                food.mealType.rawValue,
                escape(food.name),
                escape(food.brand ?? ""),
                number(food.calories),
                number(food.proteinG),
                number(food.carbsG),
                number(food.fatG),
                food.grams.map(number) ?? "",
                food.source.rawValue,
            ].joined(separator: ","))
        }

        lines.append("")
        lines.append("# Workouts")
        lines.append("date,title,focus,minutes,calories,completed_exercises")
        for workout in workouts.sorted(by: { $0.date < $1.date }) {
            lines.append([
                iso(workout.date),
                escape(workout.title),
                workout.focus.rawValue,
                String(workout.minutes),
                String(workout.calories),
                escape(workout.completedExerciseIDs.joined(separator: ";")),
            ].joined(separator: ","))
        }

        lines.append("")
        lines.append("# Weights")
        lines.append("date,weight_kg")
        for weight in weights.sorted(by: { $0.date < $1.date }) {
            lines.append([iso(weight.date), number(weight.weightKg)].joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("metabolic-export.csv")

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static let isoFormatter = ISO8601DateFormatter()

    private static func iso(_ date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static func number(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else { return field }
        let doubled = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"" + doubled + "\""
    }
}
