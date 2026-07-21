import Foundation
import UniformTypeIdentifiers
import MetabolicCore

/// Backend-free workout sharing. A shared workout is a small versioned JSON document sent as a
/// file through the system share sheet (Messages, Mail, AirDrop, Files) alongside a
/// human-readable text summary; the receiver imports it from My Workouts via the file picker.
/// Exercises travel as library ids with the sender's prescription — ids the receiving app
/// doesn't know (older version) are skipped on import rather than failing the whole workout.
enum WorkoutShare {

    struct Payload: Codable {
        var version: Int = 1
        var name: String
        var items: [CustomWorkoutItem]
    }

    static let fileExtension = "metabolicworkout"

    /// Types the importer accepts: our own extension plus plain JSON (so a renamed or
    /// forwarded file still opens).
    static var importTypes: [UTType] {
        var types: [UTType] = [.json]
        if let custom = UTType(filenameExtension: fileExtension) { types.append(custom) }
        return types
    }

    /// Writes the workout to a temp file for `ShareLink`; the file name becomes the
    /// attachment name the recipient sees.
    static func exportURL(for workout: CustomWorkout) -> URL? {
        let payload = Payload(name: workout.name, items: workout.items)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload) else { return nil }
        let safeName = workout.name
            .components(separatedBy: CharacterSet(charactersIn: "/\\:"))
            .joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName).\(fileExtension)")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Human-readable companion text — useful on its own for someone without the app.
    static func shareText(for workout: CustomWorkout) -> String {
        var lines = ["\(workout.name) — a Metabolic workout", ""]
        for item in workout.items {
            guard let exercise = ExerciseLibrary.exercise(id: item.exerciseID) else { continue }
            let target = item.isTimed ? "\(item.seconds)s hold" : "\(item.reps) reps"
            lines.append("• \(exercise.name) — \(item.sets) × \(target), rest \(item.restSeconds)s")
        }
        lines.append("")
        lines.append("Open the attached file with Metabolic to import it.")
        return lines.joined(separator: "\n")
    }

    /// Decodes an incoming share into a fresh, unsaved `CustomWorkout`. Returns `nil` when the
    /// file isn't a workout or none of its exercises exist in this app version.
    static func importWorkout(from url: URL) -> CustomWorkout? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
        let known = payload.items.filter { ExerciseLibrary.exercise(id: $0.exerciseID) != nil }
        guard !known.isEmpty else { return nil }
        return CustomWorkout(name: payload.name, items: known)
    }
}
