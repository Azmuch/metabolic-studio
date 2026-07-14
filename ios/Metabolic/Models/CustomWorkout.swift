import Foundation
import SwiftData
import MetabolicCore

/// Identifiable wrapper so a one-off plan can drive `.fullScreenCover(item:)`, which guarantees the
/// plan is non-nil when the cover renders — `isPresented` + a separate optional can race to a blank
/// screen (the cover presents before the plan is assigned).
struct RunnablePlan: Identifiable {
    let id = UUID()
    let plan: WorkoutPlan
}

/// One configured exercise inside a user-built workout. Stored as JSON on `CustomWorkout` so the
/// whole item list round-trips as a single value (avoids SwiftData relationship overhead).
struct CustomWorkoutItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var exerciseID: String
    var sets: Int
    var isTimed: Bool
    var reps: Int
    var seconds: Int
    var restSeconds: Int

    var kind: ExerciseKind {
        isTimed ? .timed(seconds: seconds) : .reps(reps)
    }

    /// Sensible defaults seeded from the library exercise's own prescription.
    init(exercise: Exercise) {
        self.id = UUID()
        self.exerciseID = exercise.id
        self.sets = 3
        self.restSeconds = 45
        switch exercise.kind {
        case .reps(let n):
            self.isTimed = false
            self.reps = n
            self.seconds = 40
        case .timed(let s):
            self.isTimed = true
            self.reps = 12
            self.seconds = s
        }
    }
}

/// A workout the user assembled themselves. Runs through the same `SessionPlayerView` as a
/// generated plan by mapping its items back onto library exercises.
@Model
final class CustomWorkout {
    var name: String
    var createdAt: Date
    /// JSON-encoded `[CustomWorkoutItem]`.
    var itemsData: Data

    init(name: String, items: [CustomWorkoutItem]) {
        self.name = name
        self.createdAt = .now
        self.itemsData = (try? JSONEncoder().encode(items)) ?? Data()
    }

    var items: [CustomWorkoutItem] {
        get { (try? JSONDecoder().decode([CustomWorkoutItem].self, from: itemsData)) ?? [] }
        set { itemsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var estimatedMinutes: Int {
        let totalSeconds = items.reduce(0) { acc, item in
            let work = item.isTimed ? item.sets * item.seconds : item.sets * item.reps * 3
            return acc + work + item.sets * item.restSeconds
        }
        return max(1, totalSeconds / 60)
    }

    /// Builds a runnable plan, dropping any items whose exercise id no longer exists in the library.
    func plan() -> WorkoutPlan {
        let workoutItems: [WorkoutItem] = items.compactMap { item in
            guard let exercise = ExerciseLibrary.exercise(id: item.exerciseID) else { return nil }
            return WorkoutItem(id: exercise.id, exercise: exercise, sets: item.sets,
                               kind: item.kind, restSeconds: item.restSeconds)
        }
        return WorkoutPlan(date: .now, focus: .fullBody, title: name,
                           items: workoutItems, estimatedMinutes: estimatedMinutes)
    }
}
