import Foundation

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

    /// The resolved family members offered as variations of `id` (including itself, easiest →
    /// hardest). Empty when the exercise stands alone.
    public static func variations(of id: String) -> [Exercise] {
        guard let family = family(containing: id) else { return [] }
        return family.compactMap(ExerciseLibrary.exercise(id:))
    }
}
