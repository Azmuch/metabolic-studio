import Foundation

public enum StreakCalculator {

    /// Consecutive-day streak counting back from `today`. A day counts when it appears in
    /// `loggedDays` (any time of day — inputs are normalized to startOfDay). Today not being
    /// logged yet doesn't break the run: the streak then counts back from yesterday.
    public static func currentStreak(loggedDays: Set<Date>, today: Date, calendar: Calendar) -> Int {
        let normalized = Set(loggedDays.map { calendar.startOfDay(for: $0) })
        var day = calendar.startOfDay(for: today)

        if !normalized.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while normalized.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }
}
