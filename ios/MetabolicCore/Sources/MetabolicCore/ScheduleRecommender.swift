import Foundation

/// Recommends training frequency and session length from the fitness profile.
/// The user pins ONE dimension (`FitnessProfile.scheduleAnchor`); the app recommends
/// the other so weekly training volume stays appropriate for their level and goal.
public enum ScheduleRecommender {

    /// Baseline recommendation when nothing is pinned.
    public static func recommendation(for p: FitnessProfile) -> (days: Int, minutes: Int) {
        var days: Int
        var minutes: Int

        switch p.experience {
        case .beginner: (days, minutes) = (3, 30)
        case .intermediate: (days, minutes) = (4, 45)
        case .advanced: (days, minutes) = (5, 60)
        }

        switch p.goal {
        case .loseFat: days += 1
        case .gainMuscle: minutes += 15
        case .improveEndurance: days += 1
        case .improveMobility: minutes -= 10   // shorter, ideally more frequent sessions
        case .maintain: break
        }

        if p.age >= 60 { minutes -= 10 }
        if p.activityLevel == .veryActive { days -= 1 }   // heavy daily workload already

        return (clampDays(days), clampMinutes(minutes))
    }

    /// User pinned days-per-week → recommend session length that preserves the
    /// profile's weekly training volume.
    public static func recommendedMinutes(forDays days: Int, profile p: FitnessProfile) -> Int {
        let base = recommendation(for: p)
        let weekly = Double(base.days * base.minutes)
        return clampMinutes(Int(weekly / Double(clampDays(days))))
    }

    /// User pinned session length → recommend days-per-week that preserves the
    /// profile's weekly training volume.
    public static func recommendedDays(forMinutes minutes: Int, profile p: FitnessProfile) -> Int {
        let base = recommendation(for: p)
        let weekly = Double(base.days * base.minutes)
        let clamped = Double(max(15, min(90, minutes)))
        return clampDays(Int((weekly / clamped).rounded()))
    }

    private static func clampDays(_ value: Int) -> Int {
        min(max(value, 2), 6)
    }

    /// Snap to the session-length chips offered in the UI.
    private static func clampMinutes(_ value: Int) -> Int {
        let options = [15, 30, 45, 60, 75, 90]
        return options.min { abs($0 - value) < abs($1 - value) } ?? 30
    }
}
