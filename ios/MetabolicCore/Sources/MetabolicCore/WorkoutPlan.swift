import Foundation

public enum DayFocus: String, Codable, CaseIterable, Sendable {
    case fullBody, upperBody, lowerBody, push, pull, core, cardio, rest

    public var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        case .upperBody: return "Upper Body"
        case .lowerBody: return "Lower Body"
        case .push: return "Push"
        case .pull: return "Pull"
        case .core: return "Core"
        case .cardio: return "Cardio"
        case .rest: return "Rest"
        }
    }
}

public struct WorkoutItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String              // exercise id
    public var exercise: Exercise
    public var sets: Int
    public var kind: ExerciseKind      // resolved reps/seconds for THIS plan
    public var restSeconds: Int

    public init(id: String, exercise: Exercise, sets: Int, kind: ExerciseKind, restSeconds: Int) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
        self.kind = kind
        self.restSeconds = restSeconds
    }
}

public struct WorkoutPlan: Codable, Equatable, Sendable {
    public var date: Date
    public var focus: DayFocus
    public var title: String
    public var items: [WorkoutItem]
    public var estimatedMinutes: Int

    public init(date: Date, focus: DayFocus, title: String, items: [WorkoutItem], estimatedMinutes: Int) {
        self.date = date
        self.focus = focus
        self.title = title
        self.items = items
        self.estimatedMinutes = estimatedMinutes
    }

    public func estimatedCalories(weightKg: Double) -> Int {
        guard !items.isEmpty, estimatedMinutes > 0 else { return 0 }

        let totalSets = items.reduce(0) { $0 + $1.sets }
        guard totalSets > 0 else { return 0 }

        let weightedMet = items.reduce(0.0) { $0 + $1.exercise.met * Double($1.sets) } / Double(totalSets)
        let activeMinutes = Double(estimatedMinutes) * 0.6

        return Int(CalorieBurnCalculator.kilocalories(met: weightedMet, weightKg: weightKg, minutes: activeMinutes).rounded())
    }
}
