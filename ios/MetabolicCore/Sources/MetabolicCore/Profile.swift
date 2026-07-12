import Foundation

public enum BiologicalSex: String, Codable, CaseIterable, Sendable {
    case male, female
}

public enum FitnessGoal: String, Codable, CaseIterable, Sendable {
    case loseFat, maintain, gainMuscle, improveEndurance, improveMobility

    public var displayName: String {
        switch self {
        case .loseFat: return "Lose Fat"
        case .maintain: return "Maintain"
        case .gainMuscle: return "Gain Muscle"
        case .improveEndurance: return "Improve Endurance"
        case .improveMobility: return "Flexibility & Mobility"
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
        case .none: return "figure.core.training"
        case .dumbbells: return "dumbbell.fill"
        case .resistanceBands: return "figure.flexibility"
        case .kettlebell: return "figure.strengthtraining.functional"
        case .barbell: return "figure.strengthtraining.traditional"
        case .pullUpBar: return "figure.climbing"
        case .bench: return "figure.cross.training"
        case .fullGym: return "building.2.fill"
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

public enum DietaryPreference: String, Codable, CaseIterable, Sendable {
    case none, vegetarian, vegan, pescatarian

    public var displayName: String {
        switch self {
        case .none: return "No Preference"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .pescatarian: return "Pescatarian"
        }
    }
}

public enum FoodAllergen: String, Codable, CaseIterable, Sendable {
    case dairy, gluten, nuts, eggs, soy, fish, shellfish

    public var displayName: String {
        switch self {
        case .dairy: return "Dairy"
        case .gluten: return "Gluten"
        case .nuts: return "Nuts & Peanuts"
        case .eggs: return "Eggs"
        case .soy: return "Soy"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        }
    }
}

/// Which half of the schedule the user chose to pin; the app recommends the other half
/// via `ScheduleRecommender`.
public enum ScheduleAnchor: String, Codable, CaseIterable, Sendable {
    case daysPerWeek, sessionLength

    public var displayName: String {
        switch self {
        case .daysPerWeek: return "Days per Week"
        case .sessionLength: return "Session Length"
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

    // v2 fields — all decode with defaults so v1 persisted profiles keep loading.
    /// Muscle groups the user wants to strengthen / firm up / prioritize.
    public var focusAreas: Set<MuscleGroup>
    /// Free-text body areas (incl. deep muscle/tissue) flagged on the body map.
    public var customFlags: [String]
    /// Adds physical-therapy style warm-up and cooldown blocks to every session.
    public var includeMobilityWork: Bool
    /// Free-text equipment the user owns beyond the standard list (informational).
    public var customEquipment: [String]
    /// Optional user-set macro targets that override the computed ones.
    public var customProteinG: Int?
    public var customCarbsG: Int?
    public var customFatG: Int?
    /// Which schedule dimension the user pinned (the other is recommended).
    public var scheduleAnchor: ScheduleAnchor
    /// Diet style honored by the meal-prep planner.
    public var dietaryPreference: DietaryPreference
    /// Allergens strictly excluded from generated meal plans.
    public var allergies: Set<FoodAllergen>

    public init(age: Int = 30, sex: BiologicalSex = .male, heightCm: Double = 175,
                weightKg: Double = 75, goal: FitnessGoal = .maintain,
                activityLevel: ActivityLevel = .moderate,
                experience: ExperienceLevel = .beginner,
                equipment: Set<Equipment> = [.none], injuries: Set<InjuryFlag> = [],
                workoutDaysPerWeek: Int = 3, sessionMinutes: Int = 30,
                focusAreas: Set<MuscleGroup> = [], customFlags: [String] = [],
                includeMobilityWork: Bool = false, customEquipment: [String] = [],
                customProteinG: Int? = nil, customCarbsG: Int? = nil, customFatG: Int? = nil,
                scheduleAnchor: ScheduleAnchor = .daysPerWeek,
                dietaryPreference: DietaryPreference = .none,
                allergies: Set<FoodAllergen> = []) {
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
        self.focusAreas = focusAreas
        self.customFlags = customFlags
        self.includeMobilityWork = includeMobilityWork
        self.customEquipment = customEquipment
        self.customProteinG = customProteinG
        self.customCarbsG = customCarbsG
        self.customFatG = customFatG
        self.scheduleAnchor = scheduleAnchor
        self.dietaryPreference = dietaryPreference
        self.allergies = allergies
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        age = try c.decode(Int.self, forKey: .age)
        sex = try c.decode(BiologicalSex.self, forKey: .sex)
        heightCm = try c.decode(Double.self, forKey: .heightCm)
        weightKg = try c.decode(Double.self, forKey: .weightKg)
        goal = try c.decode(FitnessGoal.self, forKey: .goal)
        activityLevel = try c.decode(ActivityLevel.self, forKey: .activityLevel)
        experience = try c.decode(ExperienceLevel.self, forKey: .experience)
        equipment = try c.decode(Set<Equipment>.self, forKey: .equipment)
        injuries = try c.decode(Set<InjuryFlag>.self, forKey: .injuries)
        workoutDaysPerWeek = try c.decode(Int.self, forKey: .workoutDaysPerWeek)
        sessionMinutes = try c.decode(Int.self, forKey: .sessionMinutes)
        focusAreas = try c.decodeIfPresent(Set<MuscleGroup>.self, forKey: .focusAreas) ?? []
        customFlags = try c.decodeIfPresent([String].self, forKey: .customFlags) ?? []
        includeMobilityWork = try c.decodeIfPresent(Bool.self, forKey: .includeMobilityWork) ?? false
        customEquipment = try c.decodeIfPresent([String].self, forKey: .customEquipment) ?? []
        customProteinG = try c.decodeIfPresent(Int.self, forKey: .customProteinG)
        customCarbsG = try c.decodeIfPresent(Int.self, forKey: .customCarbsG)
        customFatG = try c.decodeIfPresent(Int.self, forKey: .customFatG)
        scheduleAnchor = try c.decodeIfPresent(ScheduleAnchor.self, forKey: .scheduleAnchor) ?? .daysPerWeek
        dietaryPreference = try c.decodeIfPresent(DietaryPreference.self, forKey: .dietaryPreference) ?? .none
        allergies = try c.decodeIfPresent(Set<FoodAllergen>.self, forKey: .allergies) ?? []
    }

    public static let `default` = FitnessProfile()
}
