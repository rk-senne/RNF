import AppIntents
import Foundation
import os

// MARK: - P26-APL-03: Start Workout Intent

/// Starts a workout session via Siri or Shortcuts.
/// Opens the app to display the workout timer UI.
struct StartWorkoutIntent: AppIntent {

    static var title: LocalizedStringResource = "Start Workout"
    static var description = IntentDescription("Begin tracking a workout session in RNF")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Workout Type", default: .quickChallenge)
    var workoutType: WorkoutTypeAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$workoutType) workout")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.rnf.app", category: "intents")

        // Write workout request to shared UserDefaults so the app picks it up on launch
        let defaults = UserDefaults(suiteName: RNFWidgetData.appGroupID)
        let workoutRequest = WorkoutIntentRequest(
            workoutType: workoutType.rawValue,
            requestedAt: Date()
        )

        if let encoded = try? JSONEncoder().encode(workoutRequest) {
            defaults?.set(encoded, forKey: WorkoutIntentRequest.userDefaultsKey)
        }

        logger.info("StartWorkoutIntent: Requesting \(workoutType.rawValue) workout")

        return .result(dialog: "Starting \(workoutType.localizedName) workout. Let's crush it! 🏋️")
    }
}

// MARK: - Workout Type App Enum

/// AppEnum representing available workout types for Siri parameter resolution.
enum WorkoutTypeAppEnum: String, AppEnum {

    case quickChallenge = "quick_challenge"
    case timed = "timed"
    case hiit = "hiit"
    case strength = "strength"
    case cardio = "cardio"
    case flexibility = "flexibility"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Workout Type")
    }

    static var caseDisplayRepresentations: [WorkoutTypeAppEnum: DisplayRepresentation] {
        [
            .quickChallenge: DisplayRepresentation(title: "Quick Challenge", subtitle: "Short burst workout"),
            .timed: DisplayRepresentation(title: "Timed", subtitle: "Fixed duration session"),
            .hiit: DisplayRepresentation(title: "HIIT", subtitle: "High intensity intervals"),
            .strength: DisplayRepresentation(title: "Strength", subtitle: "Weight training"),
            .cardio: DisplayRepresentation(title: "Cardio", subtitle: "Cardiovascular exercise"),
            .flexibility: DisplayRepresentation(title: "Flexibility", subtitle: "Stretching & mobility")
        ]
    }

    var localizedName: String {
        switch self {
        case .quickChallenge: return "Quick Challenge"
        case .timed: return "Timed"
        case .hiit: return "HIIT"
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .flexibility: return "Flexibility"
        }
    }
}

// MARK: - Workout Intent Request (Shared Data)

/// Written to App Group UserDefaults when a workout is requested via intent.
/// The app reads and clears this on launch to navigate to the workout screen.
struct WorkoutIntentRequest: Codable {

    let workoutType: String
    let requestedAt: Date

    static let userDefaultsKey = "rnf_workout_intent_request"

    /// Returns true if the request is still valid (within 5 minutes of creation).
    var isValid: Bool {
        Date().timeIntervalSince(requestedAt) < 300
    }
}
