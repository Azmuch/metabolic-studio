import Foundation

/// A snapshot of training history used to evaluate achievements.
struct AchievementStats {
    var totalWorkouts: Int
    var currentStreakDays: Int
    var totalMinutes: Int
    var distinctExercises: Int
    var personalBests: Int
    var earlyBird: Bool     // trained before 7am
    var nightOwl: Bool      // trained at/after 9pm

    static func compute(logs: [WorkoutLog], personalBests: [PersonalBest]) -> AchievementStats {
        let calendar = Calendar.current
        let distinct = Set(logs.flatMap { $0.completedExerciseIDs }).count
        let prCount = personalBests.filter { $0.hasAnyRecord }.count
        let earlyBird = logs.contains { calendar.component(.hour, from: $0.date) < 7 }
        let nightOwl = logs.contains { calendar.component(.hour, from: $0.date) >= 21 }
        return AchievementStats(
            totalWorkouts: logs.count,
            currentStreakDays: currentStreak(logs: logs, calendar: calendar),
            totalMinutes: logs.reduce(0) { $0 + $1.minutes },
            distinctExercises: distinct,
            personalBests: prCount,
            earlyBird: earlyBird,
            nightOwl: nightOwl
        )
    }

    private static func currentStreak(logs: [WorkoutLog], calendar: Calendar) -> Int {
        let days = Set(logs.map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var day = calendar.startOfDay(for: .now)
        if !days.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while days.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }
}

/// A badge the user can unlock by training. `isEarned` is evaluated against `AchievementStats`.
struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let isEarned: (AchievementStats) -> Bool

    static let all: [Achievement] = [
        Achievement(id: "first", title: "First Steps", detail: "Complete a workout",
                    symbol: "figure.walk", isEarned: { $0.totalWorkouts >= 1 }),
        Achievement(id: "five", title: "Getting Consistent", detail: "5 workouts",
                    symbol: "flame.fill", isEarned: { $0.totalWorkouts >= 5 }),
        Achievement(id: "twentyfive", title: "Committed", detail: "25 workouts",
                    symbol: "medal.fill", isEarned: { $0.totalWorkouts >= 25 }),
        Achievement(id: "hundred", title: "Centurion", detail: "100 workouts",
                    symbol: "crown.fill", isEarned: { $0.totalWorkouts >= 100 }),
        Achievement(id: "streak7", title: "Week Warrior", detail: "7-day streak",
                    symbol: "calendar", isEarned: { $0.currentStreakDays >= 7 }),
        Achievement(id: "streak30", title: "Unstoppable", detail: "30-day streak",
                    symbol: "bolt.fill", isEarned: { $0.currentStreakDays >= 30 }),
        Achievement(id: "minutes500", title: "Time Under Tension", detail: "500 minutes trained",
                    symbol: "clock.fill", isEarned: { $0.totalMinutes >= 500 }),
        Achievement(id: "explorer", title: "Explorer", detail: "10 different exercises",
                    symbol: "map.fill", isEarned: { $0.distinctExercises >= 10 }),
        Achievement(id: "pr1", title: "Record Breaker", detail: "Set a personal best",
                    symbol: "trophy.fill", isEarned: { $0.personalBests >= 1 }),
        Achievement(id: "pr10", title: "Peak Performer", detail: "10 personal bests",
                    symbol: "chart.line.uptrend.xyaxis", isEarned: { $0.personalBests >= 10 }),
        Achievement(id: "earlybird", title: "Early Bird", detail: "Train before 7am",
                    symbol: "sunrise.fill", isEarned: { $0.earlyBird }),
        Achievement(id: "nightowl", title: "Night Owl", detail: "Train after 9pm",
                    symbol: "moon.stars.fill", isEarned: { $0.nightOwl }),
    ]
}
