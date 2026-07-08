import Foundation

public enum BiologicalSex: String, Codable, CaseIterable, Sendable {
    case male, female
}

public enum FitnessGoal: String, Codable, CaseIterable, Sendable {
    case loseFat, maintain, gainMuscle, improveEndurance

    public var displayName: String {
        switch self {
        case .loseFat: return "Lose Fat"
        case .maintain: return "Maintain"
        case .gainMuscle: return "Gain Muscle"
        case .improveEndurance: return "Improve Endurance"
        }
    }
}

public enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary, light, moderate, active, veryActive

    public var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        }
    }

    public var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

public enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case beginner, intermediate, advanced

    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

public enum Equipment: String, Codable, CaseIterable, Sendable {
    case none, dumbbells, resistanceBands, kettlebell, barbell, pullUpBar, bench, fullGym

    public var displayName: String {
        switch self {
        case .none: return "No Equipment"
        case .dumbbells: return "Dumbbells"
        case .resistanceBands: return "Resistance Bands"
        case .kettlebell: return "Kettlebell"
        case .barbell: return "Barbell"
        case .pullUpBar: return "Pull-Up Bar"
        case .bench: return "Bench"
        case .fullGym: return "Full Gym"
        }
    }

    public var symbolName: String {
        switch self {
        case .none: return "figure.strengthtraining.functional"
        case .dumbbells: return "dumbbell"
        case .resistanceBands: return "figure.flexibility"
        case .kettlebell: return "figure.strengthtraining.traditional"
        case .barbell: return "figure.strengthtraining.traditional"
        case .pullUpBar: return "figure.pullups"
        case .bench: return "chair"
        case .fullGym: return "building.2"
        }
    }
}

public enum InjuryFlag: String, Codable, CaseIterable, Sendable {
    case knee, lowerBack, shoulder, wrist, ankle, hip, neck, limitedMobility

    public var displayName: String {
        switch self {
        case .knee: return "Knee"
        case .lowerBack: return "Lower Back"
        case .shoulder: return "Shoulder"
        case .wrist: return "Wrist"
        case .ankle: return "Ankle"
        case .hip: return "Hip"
        case .neck: return "Neck"
        case .limitedMobility: return "Limited Mobility"
        }
    }
}

public struct FitnessProfile: Codable, Equatable, Sendable {
    public var age: Int
    public var sex: BiologicalSex
    public var heightCm: Double
    public var weightKg: Double
    public var goal: FitnessGoal
    public var activityLevel: ActivityLevel
    public var experience: ExperienceLevel
    public var equipment: Set<Equipment>
    public var injuries: Set<InjuryFlag>
    public var workoutDaysPerWeek: Int   // 2...6
    public var sessionMinutes: Int       // 15...90

    public init(age: Int = 30, sex: BiologicalSex = .male, heightCm: Double = 175,
                weightKg: Double = 75, goal: FitnessGoal = .maintain,
                activityLevel: ActivityLevel = .moderate,
                experience: ExperienceLevel = .beginner,
                equipment: Set<Equipment> = [.none], injuries: Set<InjuryFlag> = [],
                workoutDaysPerWeek: Int = 3, sessionMinutes: Int = 30) {
        self.age = age
        self.sex = sex
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.goal = goal
        self.activityLevel = activityLevel
        self.experience = experience
        self.equipment = equipment
        self.injuries = injuries
        self.workoutDaysPerWeek = workoutDaysPerWeek
        self.sessionMinutes = sessionMinutes
    }

    public static let `default` = FitnessProfile()
}
