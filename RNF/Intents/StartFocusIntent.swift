import AppIntents
import Foundation
import os

// MARK: - P26-APL-02: Start Focus Session Intent

/// Starts a timed focus session via Siri or Shortcuts.
/// Opens the app to display the focus timer UI.
struct StartFocusIntent: AppIntent {

    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Begin a timed focus session in RNF")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Duration (minutes)", default: 25, controlStyle: .stepper)
    var durationMinutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Start focus session for \(\.$durationMinutes) minutes")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.rnf.app", category: "intents")

        // Validate duration
        let clampedDuration = min(max(durationMinutes, 5), 120)
        if clampedDuration != durationMinutes {
            logger.info("StartFocusIntent: Clamped duration from \(durationMinutes) to \(clampedDuration)")
        }

        // Write focus request to shared UserDefaults so the app picks it up on launch
        let defaults = UserDefaults(suiteName: RNFWidgetData.appGroupID)
        let focusRequest = FocusIntentRequest(
            durationSeconds: clampedDuration * 60,
            requestedAt: Date()
        )

        if let encoded = try? JSONEncoder().encode(focusRequest) {
            defaults?.set(encoded, forKey: FocusIntentRequest.userDefaultsKey)
        }

        logger.info("StartFocusIntent: Requesting \(clampedDuration) min focus session")

        let sessionType = Self.sessionTypeName(for: clampedDuration)
        return .result(dialog: "Starting \(sessionType) for \(clampedDuration) minutes. Let's go! 🎯")
    }

    // MARK: - Helpers

    private static func sessionTypeName(for minutes: Int) -> String {
        switch minutes {
        case ..<20: return "Quick Focus"
        case 20..<35: return "Standard Session"
        case 35..<50: return "Deep Session"
        default: return "Flow State"
        }
    }
}

// MARK: - Focus Intent Request (Shared Data)

/// Written to App Group UserDefaults when a focus session is requested via intent.
/// The app reads and clears this on launch to start the timer automatically.
struct FocusIntentRequest: Codable {

    let durationSeconds: Int
    let requestedAt: Date

    static let userDefaultsKey = "rnf_focus_intent_request"

    /// Returns true if the request is still valid (within 5 minutes of creation).
    var isValid: Bool {
        Date().timeIntervalSince(requestedAt) < 300
    }
}
