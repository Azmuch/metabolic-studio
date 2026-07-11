import SwiftUI
import HealthKit
import MetabolicCore

/// Thin wrapper around HealthKit: requests authorization for meal/water/weight/workout writes
/// plus step/weight/activity reads, then exposes simple save/read helpers. Every method is a
/// safe no-op when HealthKit is unavailable or unauthorized.
@Observable
final class HealthKitService {
    private let store = HKHealthStore()

    private static let grantedKey = "mt.health.granted"

    var isAuthorized: Bool {
        didSet { UserDefaults.standard.set(isAuthorized, forKey: Self.grantedKey) }
    }

    init() {
        isAuthorized = UserDefaults.standard.bool(forKey: Self.grantedKey)
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let shareTypes: Set<HKSampleType> = [
            quantityType(.dietaryEnergyConsumed),
            quantityType(.dietaryProtein),
            quantityType(.dietaryCarbohydrates),
            quantityType(.dietaryFatTotal),
            quantityType(.dietaryWater),
            quantityType(.bodyMass),
            HKObjectType.workoutType(),
        ]
        let readTypes: Set<HKObjectType> = shareTypes.union([
            quantityType(.stepCount),
            quantityType(.activeEnergyBurned),
            quantityType(.restingHeartRate),
            quantityType(.heartRate),
        ])

        let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            store.requestAuthorization(toShare: shareTypes, read: readTypes) { success, _ in
                continuation.resume(returning: success)
            }
        }
        if granted {
            isAuthorized = true
        }
    }

    // MARK: - Writes

    func saveMeal(_ entry: FoodEntry) async {
        guard isAuthorized else { return }

        var samples: [HKQuantitySample] = [
            HKQuantitySample(
                type: quantityType(.dietaryEnergyConsumed),
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: entry.calories),
                start: entry.date, end: entry.date,
                metadata: [HKMetadataKeyFoodType: entry.name]
            ),
        ]

        let gram = HKUnit.gram()
        if entry.proteinG > 0 {
            samples.append(HKQuantitySample(
                type: quantityType(.dietaryProtein),
                quantity: HKQuantity(unit: gram, doubleValue: entry.proteinG),
                start: entry.date, end: entry.date,
                metadata: [HKMetadataKeyFoodType: entry.name]
            ))
        }
        if entry.carbsG > 0 {
            samples.append(HKQuantitySample(
                type: quantityType(.dietaryCarbohydrates),
                quantity: HKQuantity(unit: gram, doubleValue: entry.carbsG),
                start: entry.date, end: entry.date,
                metadata: [HKMetadataKeyFoodType: entry.name]
            ))
        }
        if entry.fatG > 0 {
            samples.append(HKQuantitySample(
                type: quantityType(.dietaryFatTotal),
                quantity: HKQuantity(unit: gram, doubleValue: entry.fatG),
                start: entry.date, end: entry.date,
                metadata: [HKMetadataKeyFoodType: entry.name]
            ))
        }

        try? await store.save(samples)
    }

    func saveWater(ml: Int, date: Date) async {
        guard isAuthorized else { return }
        let sample = HKQuantitySample(
            type: quantityType(.dietaryWater),
            quantity: HKQuantity(unit: .liter(), doubleValue: Double(ml) / 1000),
            start: date, end: date
        )
        try? await store.save(sample)
    }

    func saveWorkout(_ log: WorkoutLog) async {
        guard isAuthorized else { return }

        let activityType: HKWorkoutActivityType = log.focus == .cardio ? .running : .traditionalStrengthTraining
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        let endDate = log.date.addingTimeInterval(Double(log.minutes) * 60)

        let began = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            builder.beginCollection(withStart: log.date) { success, _ in
                continuation.resume(returning: success)
            }
        }
        guard began else { return }

        let energySample = HKQuantitySample(
            type: quantityType(.activeEnergyBurned),
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: Double(log.calories)),
            start: log.date, end: endDate
        )
        _ = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            builder.add([energySample]) { success, _ in
                continuation.resume(returning: success)
            }
        }

        let ended = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            builder.endCollection(withEnd: endDate) { success, _ in
                continuation.resume(returning: success)
            }
        }
        guard ended else { return }

        _ = await withCheckedContinuation { (continuation: CheckedContinuation<HKWorkout?, Never>) in
            builder.finishWorkout { workout, _ in
                continuation.resume(returning: workout)
            }
        }
    }

    // MARK: - Reads

    func readLatestWeight() async -> Double? {
        guard isAuthorized else { return nil }
        let type = quantityType(.bodyMass)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]

        let sample = await withCheckedContinuation { (continuation: CheckedContinuation<HKQuantitySample?, Never>) in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: sort) { _, samples, _ in
                continuation.resume(returning: samples?.first as? HKQuantitySample)
            }
            store.execute(query)
        }
        guard let sample else { return nil }
        return sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
    }

    func readTodaySteps() async -> Int? {
        guard isAuthorized else { return nil }
        let type = quantityType(.stepCount)
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        let sum = await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: .count()))
            }
            store.execute(query)
        }
        guard let sum else { return nil }
        return Int(sum.rounded())
    }

    /// Most recent resting heart rate sample, in beats per minute. `nil` when unauthorized,
    /// unavailable, or no sample has ever been recorded.
    func readRestingHeartRate() async -> Double? {
        guard isAuthorized else { return nil }
        let type = quantityType(.restingHeartRate)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]

        let sample = await withCheckedContinuation { (continuation: CheckedContinuation<HKQuantitySample?, Never>) in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: sort) { _, samples, _ in
                continuation.resume(returning: samples?.first as? HKQuantitySample)
            }
            store.execute(query)
        }
        guard let sample else { return nil }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return sample.quantity.doubleValue(for: unit)
    }

    // MARK: - Helpers

    private func quantityType(_ identifier: HKQuantityTypeIdentifier) -> HKQuantityType {
        HKObjectType.quantityType(forIdentifier: identifier)!
    }
}
