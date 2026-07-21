import Foundation

public enum WorkoutPlanGenerator {

    /// Weekly split, Monday-first (exactly 7 entries). `workoutDaysPerWeek` is clamped to 2...6.
    public static func weeklySplit(for p: FitnessProfile) -> [DayFocus] {
        let days = min(max(p.workoutDaysPerWeek, 2), 6)
        switch days {
        case 2:
            return [.fullBody, .rest, .rest, .fullBody, .rest, .rest, .rest]
        case 3:
            if p.experience == .beginner {
                return [.fullBody, .rest, .fullBody, .rest, .fullBody, .rest, .rest]
            }
            return [.push, .rest, .pull, .rest, .lowerBody, .rest, .rest]
        case 4:
            return [.upperBody, .lowerBody, .rest, .upperBody, .lowerBody, .rest, .rest]
        case 5:
            return [.push, .pull, .rest, .lowerBody, .upperBody, .core, .rest]
        default:
            return [.push, .pull, .lowerBody, .push, .pull, .lowerBody, .rest]
        }
    }

    /// Deterministic for a given (profile, calendar day): seeded by a stable profile hash
    /// XOR the yyyymmdd key, so today's plan never shuffles under the user's feet.
    public static func plan(for p: FitnessProfile, date: Date, calendar: Calendar) -> WorkoutPlan {
        let split = weeklySplit(for: p)
        let focus = split[mondayIndexedWeekday(of: date, calendar: calendar)]

        guard focus != .rest else {
            return WorkoutPlan(date: date, focus: .rest, title: "Rest & Recover", items: [], estimatedMinutes: 0)
        }

        let available = ExerciseLibrary.available(equipment: p.equipment, injuries: p.injuries)
        let pool = available.filter { $0.category == .strength && matches(focus: focus, exercise: $0) }

        guard !pool.isEmpty else {
            return WorkoutPlan(date: date, focus: focus, title: "Mobility & Recovery", items: [], estimatedMinutes: 0)
        }

        var rng = SeededRandom(seed: StableHash.fnv1a(canonicalKey(for: p)) ^ dayKey(for: date, calendar: calendar))

        var count = max(3, min(8, p.sessionMinutes / 8))
        switch p.experience {
        case .beginner: count -= 1
        case .intermediate: break
        case .advanced: count += 1
        }
        count = min(max(3, min(8, count)), pool.count)

        // Focus areas get priority: up to half the slots fill from focus-matching moves first.
        var selected: [Exercise] = []
        if !p.focusAreas.isEmpty {
            var focusCandidates = pool.filter { !p.focusAreas.isDisjoint(with: $0.muscleGroups) }
            let focusSlots = min((count + 1) / 2, focusCandidates.count)
            while selected.count < focusSlots, !focusCandidates.isEmpty {
                selected.append(focusCandidates.remove(at: rng.int(in: 0...(focusCandidates.count - 1))))
            }
        }
        var candidates = pool.filter { candidate in !selected.contains { $0.id == candidate.id } }
        while selected.count < count, !candidates.isEmpty {
            selected.append(candidates.remove(at: rng.int(in: 0...(candidates.count - 1))))
        }

        // Compound movements first, core/cardio finishers last; id as a stable tiebreaker.
        selected.sort { lhs, rhs in
            let (l, r) = (sortKey(for: lhs), sortKey(for: rhs))
            if l != r { return l < r }
            return lhs.id < rhs.id
        }

        let repRange: ClosedRange<Int>
        let restSeconds: Int
        switch p.goal {
        case .loseFat: (repRange, restSeconds) = (12...15, 45)
        case .maintain: (repRange, restSeconds) = (10...12, 60)
        case .gainMuscle: (repRange, restSeconds) = (8...12, 90)
        case .improveEndurance: (repRange, restSeconds) = (15...20, 40)
        case .improveMobility: (repRange, restSeconds) = (12...15, 45)
        }
        let timedRange: ClosedRange<Int> =
            (p.goal == .loseFat || p.goal == .improveEndurance) ? 40...60 : 30...45
        let sets = p.experience == .advanced ? 4 : 3

        var workSecondsTotal = 0
        let items: [WorkoutItem] = selected.map { exercise in
            let resolved: ExerciseKind
            let workSeconds: Int
            switch exercise.kind {
            case .reps:
                let reps = rng.int(in: repRange)
                resolved = .reps(reps)
                workSeconds = reps * 3
            case .timed:
                let seconds = rng.int(in: timedRange)
                resolved = .timed(seconds: seconds)
                workSeconds = seconds
            }
            workSecondsTotal += sets * (workSeconds + restSeconds)
            return WorkoutItem(id: exercise.id, exercise: exercise, sets: sets,
                               kind: resolved, restSeconds: restSeconds)
        }

        // PT-style warm-up and cooldown blocks (opt-in, always on for the mobility goal).
        var allItems = items
        if p.includeMobilityWork || p.goal == .improveMobility {
            let mobilityPool = available.filter { $0.category == .mobility }
            let warmup = pickMobility(2, from: mobilityPool, excluding: [], rng: &rng)
            let cooldown = pickMobility(2, from: mobilityPool,
                                        excluding: Set(warmup.map(\.id)), rng: &rng)
            let asBlockItem: (Exercise) -> WorkoutItem = { exercise in
                WorkoutItem(id: exercise.id, exercise: exercise, sets: 1,
                            kind: .timed(seconds: 35), restSeconds: 15)
            }
            allItems = warmup.map(asBlockItem) + allItems + cooldown.map(asBlockItem)
            workSecondsTotal += (warmup.count + cooldown.count) * 50
        }

        let minutes = 5 + Int((Double(workSecondsTotal) / 60).rounded())
        let flavors = ["Builder", "Circuit", "Session", "Burner"]
        let title = "\(focus.displayName) \(rng.pick(flavors) ?? "Session")"

        return WorkoutPlan(date: date, focus: focus, title: title, items: allItems, estimatedMinutes: minutes)
    }

    private static func pickMobility(_ count: Int, from pool: [Exercise],
                                     excluding: Set<String>,
                                     rng: inout SeededRandom) -> [Exercise] {
        var candidates = pool.filter { !excluding.contains($0.id) }
        var picked: [Exercise] = []
        while picked.count < count, !candidates.isEmpty {
            picked.append(candidates.remove(at: rng.int(in: 0...(candidates.count - 1))))
        }
        return picked
    }

    // MARK: - Internals

    /// Monday = 0 ... Sunday = 6, independent of the calendar's firstWeekday setting.
    static func mondayIndexedWeekday(of date: Date, calendar: Calendar) -> Int {
        // Gregorian .weekday: Sunday = 1 ... Saturday = 7.
        (calendar.component(.weekday, from: date) + 5) % 7
    }

    static func dayKey(for date: Date, calendar: Calendar) -> UInt64 {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return UInt64((c.year ?? 0) * 10_000 + (c.month ?? 0) * 100 + (c.day ?? 0))
    }

    static func canonicalKey(for p: FitnessProfile) -> String {
        let equipment = p.equipment.map(\.rawValue).sorted().joined(separator: ",")
        let injuries = p.injuries.map(\.rawValue).sorted().joined(separator: ",")
        return [
            "\(p.age)", p.sex.rawValue, "\(p.heightCm)", "\(p.weightKg)",
            p.goal.rawValue, p.activityLevel.rawValue, p.experience.rawValue,
            equipment, injuries, "\(p.workoutDaysPerWeek)", "\(p.sessionMinutes)",
        ].joined(separator: "|")
    }

    static func matches(focus: DayFocus, exercise: Exercise) -> Bool {
        let groups = Set(exercise.muscleGroups)
        switch focus {
        case .fullBody:
            return true
        case .upperBody:
            return !groups.isDisjoint(with: [.chest, .back, .shoulders, .arms])
        case .lowerBody:
            return !groups.isDisjoint(with: [.quads, .hamstrings, .glutes, .calves])
        case .push:
            return !groups.isDisjoint(with: [.chest, .shoulders])
        case .pull:
            return !groups.isDisjoint(with: [.back, .arms])
        case .core:
            return groups.contains(.core)
        case .cardio:
            return !groups.isDisjoint(with: [.cardio, .fullBody])
        case .rest:
            return false
        }
    }

    /// 0 = compound strength, 1 = isolation, 2 = core/cardio finisher.
    private static func sortKey(for exercise: Exercise) -> Int {
        let groups = Set(exercise.muscleGroups)
        if !groups.isDisjoint(with: [.cardio]) || groups == [.core] { return 2 }
        return exercise.muscleGroups.count >= 2 ? 0 : 1
    }
}
