import Foundation

public enum ExerciseKind: Codable, Equatable, Sendable {
    case reps(Int)
    case timed(seconds: Int)

    private enum CodingKeys: String, CodingKey {
        case kind, reps, seconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "reps":
            let reps = try container.decode(Int.self, forKey: .reps)
            self = .reps(reps)
        case "timed":
            let seconds = try container.decode(Int.self, forKey: .seconds)
            self = .timed(seconds: seconds)
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown ExerciseKind '\(kind)'")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .reps(let reps):
            try container.encode("reps", forKey: .kind)
            try container.encode(reps, forKey: .reps)
        case .timed(let seconds):
            try container.encode("timed", forKey: .kind)
            try container.encode(seconds, forKey: .seconds)
        }
    }
}

public enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest, back, shoulders, arms, core, quads, hamstrings, glutes, calves, fullBody, cardio

    public var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .core: return "Core"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .fullBody: return "Full Body"
        case .cardio: return "Cardio"
        }
    }
}

public struct Exercise: Identifiable, Codable, Equatable, Sendable {
    public var id: String            // stable slug, e.g. "squat"
    public var name: String
    public var muscleGroups: [MuscleGroup]
    public var equipment: Set<Equipment>       // [.none] == bodyweight
    public var contraindications: Set<InjuryFlag>
    public var met: Double
    public var kind: ExerciseKind              // default prescription
    public var instructions: [String]          // 3–4 short cues
    public var keyframes: [Pose]               // ≥2; animation loops through them
    public var secondsPerCycle: Double         // one full rep-cycle duration

    public init(id: String, name: String, muscleGroups: [MuscleGroup], equipment: Set<Equipment>,
                contraindications: Set<InjuryFlag>, met: Double, kind: ExerciseKind,
                instructions: [String], keyframes: [Pose], secondsPerCycle: Double) {
        self.id = id
        self.name = name
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.contraindications = contraindications
        self.met = met
        self.kind = kind
        self.instructions = instructions
        self.keyframes = keyframes
        self.secondsPerCycle = secondsPerCycle
    }
}
