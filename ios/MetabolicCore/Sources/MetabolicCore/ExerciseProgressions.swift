import Foundation

/// An exercise's fixed difficulty classification within its movement family.
public enum ProgressionTier: String, Codable, Sendable {
    case beginner, intermediate, advanced

    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    /// Compact badge text for chips.
    public var shortName: String {
        switch self {
        case .beginner: return "BEG"
        case .intermediate: return "INT"
        case .advanced: return "ADV"
        }
    }
}

/// Difficulty-ordered movement families ("progressions"). Exercises in one family train the same
/// movement pattern at different demands, so the UI can offer regressions/progressions of a
/// selected exercise and map a level preset onto the right sibling. Ids not listed stand alone.
public enum ExerciseProgressions {

    /// Each family is ordered easiest → hardest; weighted variants sit at the harder end of
    /// their bodyweight pattern so progressions naturally graduate onto load.
    public static let families: [[String]] = [
        // Push pattern (graduates onto weighted overhead pressing)
        ["kneePushUp", "pushUp", "dbShoulderPress"],
        // Squat pattern
        ["boxSquat", "squat", "gobletSquat", "frontSquat"],
        // Single-leg / lunge pattern
        ["reverseLunge", "lunge", "walkingLunge", "bulgarianSplitSquat"],
        // Hip hinge (bridge graduates onto loaded hinging and power)
        ["gluteBridge", "dbRomanianDeadlift", "kbSwing"],
        // Plank line
        ["kneePlank", "plank", "sidePlank"],
        // Hollow-body core line
        ["deadBug", "hollowHold", "vUp", "candlestick", "lSit"],
        // Horizontal/vertical pull
        ["bandRow", "dbRow", "pullUp"],
        // Shoulder isolation → compound press
        ["lateralRaise", "dbShoulderPress"],
        // Quad isometric holds
        ["wallSit", "deepSquatHold"],
    ]

    /// The family containing `id` (ordered easiest → hardest), or `nil` when it stands alone.
    public static func family(containing id: String) -> [String]? {
        families.first { $0.contains(id) }
    }

    /// Fixed, absolute difficulty tier per exercise — L-Sit is Advanced everywhere it appears,
    /// regardless of the user's level preference or which sibling they opened. Tiers can repeat
    /// within a family (two beginners, two advanced) and some families skip a tier.
    public static let tiers: [String: ProgressionTier] = [
        // Push
        "kneePushUp": .beginner, "pushUp": .intermediate, "dbShoulderPress": .advanced,
        // Squat
        "boxSquat": .beginner, "squat": .beginner, "gobletSquat": .intermediate, "frontSquat": .advanced,
        // Lunge / single-leg
        "reverseLunge": .beginner, "lunge": .intermediate, "walkingLunge": .intermediate,
        "bulgarianSplitSquat": .advanced,
        // Hip hinge
        "gluteBridge": .beginner, "dbRomanianDeadlift": .intermediate, "kbSwing": .advanced,
        // Plank line
        "kneePlank": .beginner, "plank": .intermediate, "sidePlank": .advanced,
        // Hollow-body core
        "deadBug": .beginner, "hollowHold": .intermediate, "vUp": .intermediate,
        "candlestick": .advanced, "lSit": .advanced,
        // Pull
        "bandRow": .beginner, "dbRow": .intermediate, "pullUp": .advanced,
        // Shoulders
        "lateralRaise": .beginner,
        // Quad holds
        "wallSit": .beginner, "deepSquatHold": .intermediate,
    ]

    public static func tier(of id: String) -> ProgressionTier? {
        tiers[id]
    }

    /// The family's member at `tier` (first match in easiest→hardest order). When a family has
    /// no member at that exact tier, falls back to the nearest sensible end: easiest for
    /// beginner, hardest for advanced, the middle for intermediate.
    public static func member(of family: [String], tier: ProgressionTier) -> String? {
        guard !family.isEmpty else { return nil }
        if let exact = family.first(where: { tiers[$0] == tier }) { return exact }
        switch tier {
        case .beginner: return family.first
        case .intermediate: return family[(family.count - 1) / 2]
        case .advanced: return family.last
        }
    }

    /// The resolved family members offered as variations of `id` (including itself, easiest →
    /// hardest). Empty when the exercise stands alone.
    public static func variations(of id: String) -> [Exercise] {
        guard let family = family(containing: id) else { return [] }
        return family.compactMap(ExerciseLibrary.exercise(id:))
    }
}
