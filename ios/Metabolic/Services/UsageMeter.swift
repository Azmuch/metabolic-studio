import Foundation

/// UserDefaults-backed usage counters for the free/Plus tier limits described in SPEC §7:
/// barcode scans per day and AI meal-photo analyses per month. Each counter carries its own
/// period stamp and silently resets whenever the stored period no longer matches "now".
enum UsageMeter {
    private enum Keys {
        static let scansCount = "mt.usage.scans.count"
        static let scansDay = "mt.usage.scans.day"
        static let aiCount = "mt.usage.ai.count"
        static let aiMonth = "mt.usage.ai.month"
    }

    static func scansToday() -> Int {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: Keys.scansDay) == todayString() else { return 0 }
        return defaults.integer(forKey: Keys.scansCount)
    }

    static func recordScan() {
        let defaults = UserDefaults.standard
        let today = todayString()
        if defaults.string(forKey: Keys.scansDay) != today {
            defaults.set(today, forKey: Keys.scansDay)
            defaults.set(0, forKey: Keys.scansCount)
        }
        defaults.set(defaults.integer(forKey: Keys.scansCount) + 1, forKey: Keys.scansCount)
    }

    static func aiAnalysesThisMonth() -> Int {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: Keys.aiMonth) == monthString() else { return 0 }
        return defaults.integer(forKey: Keys.aiCount)
    }

    static func recordAIAnalysis() {
        let defaults = UserDefaults.standard
        let month = monthString()
        if defaults.string(forKey: Keys.aiMonth) != month {
            defaults.set(month, forKey: Keys.aiMonth)
            defaults.set(0, forKey: Keys.aiCount)
        }
        defaults.set(defaults.integer(forKey: Keys.aiCount) + 1, forKey: Keys.aiCount)
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        return formatter.string(from: .now)
    }

    private static func monthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        return formatter.string(from: .now)
    }
}
