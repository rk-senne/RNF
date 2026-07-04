import Foundation
import HealthKit
import os

// MARK: - P26-APL-18/19/20/21/22: HealthKit Background Delivery & Auto-Complete

/// Monitors HealthKit data via HKObserverQuery for steps, exercise time, and sleep.
/// Auto-completes linked habits when user-configured thresholds are met.
/// Each habit can be independently toggled for auto-tracking.
@MainActor
final class HealthKitAutoTracker: ObservableObject {

    // MARK: - Types

    enum TrackableMetric: String, CaseIterable, Codable {
        case steps
        case exerciseMinutes
        case sleepHours
    }

    struct AutoTrackConfig: Codable, Identifiable {
        let id: UUID
        let habitID: UUID
        let metric: TrackableMetric
        var threshold: Double
        var isEnabled: Bool

        static func steps(habitID: UUID, threshold: Double = 10_000) -> AutoTrackConfig {
            AutoTrackConfig(id: UUID(), habitID: habitID, metric: .steps, threshold: threshold, isEnabled: true)
        }

        static func exerciseMinutes(habitID: UUID, threshold: Double = 30) -> AutoTrackConfig {
            AutoTrackConfig(id: UUID(), habitID: habitID, metric: .exerciseMinutes, threshold: threshold, isEnabled: true)
        }

        static func sleepHours(habitID: UUID, threshold: Double = 7) -> AutoTrackConfig {
            AutoTrackConfig(id: UUID(), habitID: habitID, metric: .sleepHours, threshold: threshold, isEnabled: true)
        }
    }

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: "com.rnf.app", category: "HealthKitAutoTracker")

    @Published private(set) var configurations: [AutoTrackConfig] = []
    @Published private(set) var todaySteps: Double = 0
    @Published private(set) var todayExerciseMinutes: Double = 0
    @Published private(set) var todaySleepHours: Double = 0

    private var observerQueries: [HKObserverQuery] = []
    private var completionHandler: ((UUID) async -> Void)?

    private static let configKey = "rnf_healthkit_auto_track_configs"

    // MARK: - Init

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        loadConfigurations()
    }

    // MARK: - Public API

    /// Sets the callback invoked when a habit auto-completes.
    func onHabitAutoComplete(_ handler: @escaping (UUID) async -> Void) {
        self.completionHandler = handler
    }

    /// P26-APL-21: User toggle per habit — enable or disable tracking for a specific config.
    func setEnabled(_ enabled: Bool, for configID: UUID) {
        guard let index = configurations.firstIndex(where: { $0.id == configID }) else { return }
        configurations[index].isEnabled = enabled
        saveConfigurations()
        logger.info("Auto-track config \(configID.uuidString) enabled: \(enabled)")
    }

    /// P26-APL-22: Update threshold for a given config.
    func updateThreshold(_ threshold: Double, for configID: UUID) {
        guard let index = configurations.firstIndex(where: { $0.id == configID }) else { return }
        configurations[index].threshold = threshold
        saveConfigurations()
        logger.info("Auto-track config \(configID.uuidString) threshold: \(threshold)")
    }

    /// Add a new auto-track configuration.
    func addConfiguration(_ config: AutoTrackConfig) {
        configurations.append(config)
        saveConfigurations()
    }

    /// Remove a configuration.
    func removeConfiguration(id: UUID) {
        configurations.removeAll { $0.id == id }
        saveConfigurations()
    }

    // MARK: - P26-APL-18: Request Authorization & Setup Observers

    func requestAuthorizationAndStart() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.warning("HealthKit not available on this device")
            return
        }

        var readTypes = Set<HKObjectType>()
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { readTypes.insert(steps) }
        if let exercise = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) { readTypes.insert(exercise) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { readTypes.insert(sleep) }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        setupObserverQueries()
        logger.info("HealthKit auto-tracker authorization granted and observers set up")
    }

    /// P26-APL-19: Enable background delivery for each metric.
    func enableBackgroundDelivery() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            try await healthStore.enableBackgroundDelivery(for: steps, frequency: .hourly)
        }
        if let exercise = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
            try await healthStore.enableBackgroundDelivery(for: exercise, frequency: .hourly)
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            try await healthStore.enableBackgroundDelivery(for: sleep, frequency: .hourly)
        }

        logger.info("HealthKit background delivery enabled for steps, exercise, sleep")
    }

    // MARK: - P26-APL-20: Threshold Evaluation

    /// Evaluates current metrics against configured thresholds and auto-completes habits.
    func evaluateThresholds() async {
        await refreshCurrentMetrics()

        for config in configurations where config.isEnabled {
            let currentValue: Double
            switch config.metric {
            case .steps:
                currentValue = todaySteps
            case .exerciseMinutes:
                currentValue = todayExerciseMinutes
            case .sleepHours:
                currentValue = todaySleepHours
            }

            if currentValue >= config.threshold {
                // Check we haven't already completed today
                let completedKey = completionKey(for: config.habitID)
                let lastCompleted = UserDefaults.standard.string(forKey: completedKey)
                let todayString = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))

                if lastCompleted != todayString {
                    UserDefaults.standard.set(todayString, forKey: completedKey)
                    logger.info("Auto-completing habit \(config.habitID.uuidString) — \(config.metric.rawValue) threshold met: \(currentValue) >= \(config.threshold)")
                    await completionHandler?(config.habitID)
                }
            }
        }
    }

    /// Returns whether a given metric threshold is currently met.
    func isThresholdMet(for metric: TrackableMetric, threshold: Double) -> Bool {
        switch metric {
        case .steps: return todaySteps >= threshold
        case .exerciseMinutes: return todayExerciseMinutes >= threshold
        case .sleepHours: return todaySleepHours >= threshold
        }
    }

    // MARK: - Metric Fetching

    func refreshCurrentMetrics() async {
        todaySteps = await fetchTodayCumulativeValue(for: .stepCount, unit: .count())
        todayExerciseMinutes = await fetchTodayCumulativeValue(for: .appleExerciseTime, unit: .minute())
        todaySleepHours = await fetchTodaySleepHours()
    }

    // MARK: - Private

    private func setupObserverQueries() {
        stopObserverQueries()

        // Steps observer
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
                if let error {
                    self?.logger.error("Steps observer error: \(error.localizedDescription)")
                    completionHandler()
                    return
                }
                Task { @MainActor [weak self] in
                    await self?.evaluateThresholds()
                    completionHandler()
                }
            }
            healthStore.execute(query)
            observerQueries.append(query)
        }

        // Exercise observer
        if let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
            let query = HKObserverQuery(sampleType: exerciseType, predicate: nil) { [weak self] _, completionHandler, error in
                if let error {
                    self?.logger.error("Exercise observer error: \(error.localizedDescription)")
                    completionHandler()
                    return
                }
                Task { @MainActor [weak self] in
                    await self?.evaluateThresholds()
                    completionHandler()
                }
            }
            healthStore.execute(query)
            observerQueries.append(query)
        }

        // Sleep observer
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completionHandler, error in
                if let error {
                    self?.logger.error("Sleep observer error: \(error.localizedDescription)")
                    completionHandler()
                    return
                }
                Task { @MainActor [weak self] in
                    await self?.evaluateThresholds()
                    completionHandler()
                }
            }
            healthStore.execute(query)
            observerQueries.append(query)
        }
    }

    private func stopObserverQueries() {
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
    }

    private func fetchTodayCumulativeValue(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if error != nil {
                    continuation.resume(returning: 0)
                    return
                }
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchTodaySleepHours() async -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: 0)
                    return
                }
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                // Only count asleep states (not inBed)
                let asleepSamples = samples.filter { sample in
                    sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                }
                let totalSeconds = asleepSamples.reduce(0.0) { sum, sample in
                    sum + sample.endDate.timeIntervalSince(sample.startDate)
                }
                continuation.resume(returning: totalSeconds / 3600.0)
            }
            healthStore.execute(query)
        }
    }

    private func completionKey(for habitID: UUID) -> String {
        "rnf_auto_complete_\(habitID.uuidString)"
    }

    // MARK: - Persistence

    private func loadConfigurations() {
        guard let data = UserDefaults.standard.data(forKey: Self.configKey),
              let decoded = try? JSONDecoder().decode([AutoTrackConfig].self, from: data) else {
            return
        }
        configurations = decoded
    }

    private func saveConfigurations() {
        guard let data = try? JSONEncoder().encode(configurations) else { return }
        UserDefaults.standard.set(data, forKey: Self.configKey)
    }
}
