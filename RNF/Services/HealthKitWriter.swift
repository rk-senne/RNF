import Foundation
import HealthKit
import os

// MARK: - P26-APL-23/24/25: HealthKit Write — Workouts & Mindful Sessions

/// Writes RNF workout completions as HKWorkout and focus sessions as HKCategoryType.mindfulSession.
/// Requires explicit user opt-in before writing any data to HealthKit.
@MainActor
final class HealthKitWriter: ObservableObject {

    // MARK: - Types

    enum WriteError: Error, LocalizedError {
        case healthKitUnavailable
        case authorizationDenied
        case userOptInRequired
        case invalidDuration
        case writeFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .healthKitUnavailable: return "HealthKit is not available on this device."
            case .authorizationDenied: return "HealthKit write permission was denied."
            case .userOptInRequired: return "User must opt in to HealthKit writing."
            case .invalidDuration: return "Workout duration must be positive."
            case .writeFailed(let error): return "Failed to save to HealthKit: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: "com.rnf.app", category: "HealthKitWriter")

    /// P26-APL-25: User must explicitly opt in before any writes occur.
    @Published var hasUserOptedIn: Bool {
        didSet { UserDefaults.standard.set(hasUserOptedIn, forKey: Self.optInKey) }
    }

    @Published private(set) var isAuthorized = false

    private static let optInKey = "rnf_healthkit_write_opted_in"

    private let writeTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()
        types.insert(HKWorkoutType.workoutType())
        if let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        return types
    }()

    // MARK: - Init

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        self.hasUserOptedIn = UserDefaults.standard.bool(forKey: Self.optInKey)
    }

    // MARK: - Authorization

    /// Requests write authorization for workouts and mindful sessions.
    /// Should be called after user opts in via the prompt.
    func requestWriteAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw WriteError.healthKitUnavailable
        }

        try await healthStore.requestAuthorization(toShare: writeTypes, read: [])
        isAuthorized = true
        logger.info("HealthKit write authorization granted")
    }

    /// P26-APL-25: Shows opt-in prompt. Call this before enabling writes.
    func promptOptIn() async throws {
        try await requestWriteAuthorization()
        hasUserOptedIn = true
        logger.info("User opted in to HealthKit writing")
    }

    /// Revoke opt-in (user disables in settings).
    func revokeOptIn() {
        hasUserOptedIn = false
        logger.info("User revoked HealthKit write opt-in")
    }

    // MARK: - P26-APL-23: Save RNF Workout as HKWorkout

    /// Saves an RNF workout session as an HKWorkout in Apple Health.
    /// - Parameters:
    ///   - activityType: The HKWorkoutActivityType (e.g., .functionalStrengthTraining)
    ///   - startDate: Workout start time
    ///   - endDate: Workout end time
    ///   - activeEnergyBurned: Optional active calories burned (kcal)
    ///   - metadata: Optional metadata dictionary
    /// - Returns: The saved HKWorkout instance
    @discardableResult
    func saveWorkout(
        activityType: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        activeEnergyBurned: Double? = nil,
        metadata: [String: Any]? = nil
    ) async throws -> HKWorkout {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw WriteError.healthKitUnavailable
        }
        guard hasUserOptedIn else {
            throw WriteError.userOptInRequired
        }
        guard endDate > startDate else {
            throw WriteError.invalidDuration
        }

        let energyQuantity: HKQuantity? = activeEnergyBurned.map {
            HKQuantity(unit: .kilocalorie(), doubleValue: $0)
        }

        var workoutMetadata: [String: Any] = metadata ?? [:]
        workoutMetadata[HKMetadataKeyWasUserEntered] = false
        workoutMetadata["RNFSource"] = "RNF App"

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())

        do {
            try await builder.beginCollection(at: startDate)

            // Add energy burned sample if provided
            if let energy = energyQuantity {
                let energySample = HKQuantitySample(
                    type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    quantity: energy,
                    start: startDate,
                    end: endDate
                )
                try await builder.addSamples([energySample])
            }

            try await builder.endCollection(at: endDate)
            try await builder.addMetadata(workoutMetadata)

            guard let workout = try await builder.finishWorkout() else {
                throw WriteError.writeFailed(underlying: NSError(domain: "RNF", code: -1, userInfo: [NSLocalizedDescriptionKey: "Workout builder returned nil"]))
            }

            logger.info("Saved HKWorkout: \(activityType.rawValue), duration: \(endDate.timeIntervalSince(startDate))s")
            return workout
        } catch let error as WriteError {
            throw error
        } catch {
            logger.error("Failed to save workout: \(error.localizedDescription)")
            throw WriteError.writeFailed(underlying: error)
        }
    }

    /// Convenience: Save an RNF workout session model.
    @discardableResult
    func saveRNFWorkout(
        durationSeconds: Int,
        startDate: Date,
        workoutType: String = "Strength"
    ) async throws -> HKWorkout {
        let endDate = startDate.addingTimeInterval(Double(durationSeconds))
        let activityType = mapWorkoutType(workoutType)

        return try await saveWorkout(
            activityType: activityType,
            startDate: startDate,
            endDate: endDate,
            metadata: ["RNFWorkoutType": workoutType]
        )
    }

    // MARK: - P26-APL-24: Save Focus Session as Mindful Session

    /// Saves an RNF focus session as an HKCategoryType.mindfulSession.
    /// - Parameters:
    ///   - startDate: Session start time
    ///   - endDate: Session end time
    ///   - sessionType: Optional description of the focus type (meditation, deep work, etc.)
    func saveFocusSession(
        startDate: Date,
        endDate: Date,
        sessionType: String? = nil
    ) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw WriteError.healthKitUnavailable
        }
        guard hasUserOptedIn else {
            throw WriteError.userOptInRequired
        }
        guard endDate > startDate else {
            throw WriteError.invalidDuration
        }
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            throw WriteError.healthKitUnavailable
        }

        var metadata: [String: Any] = [
            HKMetadataKeyWasUserEntered: false,
            "RNFSource": "RNF App"
        ]
        if let sessionType {
            metadata["RNFFocusType"] = sessionType
        }

        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate,
            metadata: metadata
        )

        do {
            try await healthStore.save(sample)
            let durationMinutes = Int(endDate.timeIntervalSince(startDate) / 60)
            logger.info("Saved mindful session: \(durationMinutes) min, type: \(sessionType ?? "general")")
        } catch {
            logger.error("Failed to save mindful session: \(error.localizedDescription)")
            throw WriteError.writeFailed(underlying: error)
        }
    }

    /// Convenience: Save from a focus timer completion.
    func saveFocusCompletion(durationSeconds: Int, startDate: Date, type: String? = nil) async throws {
        let endDate = startDate.addingTimeInterval(Double(durationSeconds))
        try await saveFocusSession(startDate: startDate, endDate: endDate, sessionType: type)
    }

    // MARK: - Private Helpers

    private func mapWorkoutType(_ type: String) -> HKWorkoutActivityType {
        switch type.lowercased() {
        case "running", "run": return .running
        case "walking", "walk": return .walking
        case "cycling", "cycle", "bike": return .cycling
        case "yoga": return .yoga
        case "hiit": return .highIntensityIntervalTraining
        case "strength", "lifting", "weights": return .functionalStrengthTraining
        case "swimming", "swim": return .swimming
        case "boxing": return .boxing
        default: return .functionalStrengthTraining
        }
    }
}
