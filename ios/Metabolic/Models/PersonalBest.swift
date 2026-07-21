import Foundation
import SwiftData

/// Best recorded performance for one exercise, updated as the user completes sets in the player.
/// Bodyweight moves track best reps / hold; loaded moves also track best load.
@Model
final class PersonalBest {
    @Attribute(.unique) var exerciseID: String
    var bestReps: Int
    var bestLoadKg: Double
    var bestHoldSeconds: Int
    var updatedAt: Date

    init(exerciseID: String, bestReps: Int = 0, bestLoadKg: Double = 0, bestHoldSeconds: Int = 0) {
        self.exerciseID = exerciseID
        self.bestReps = bestReps
        self.bestLoadKg = bestLoadKg
        self.bestHoldSeconds = bestHoldSeconds
        self.updatedAt = .now
    }

    var hasAnyRecord: Bool {
        bestReps > 0 || bestLoadKg > 0 || bestHoldSeconds > 0
    }
}
