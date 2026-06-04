import Foundation
import OSLog

enum RNFLogger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "RNF"

    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let dailyLog = Logger(subsystem: subsystem, category: "DailyLog")
    static let habitCompletion = Logger(subsystem: subsystem, category: "HabitCompletion")
    static let challenge = Logger(subsystem: subsystem, category: "Challenge")
    static let sync = Logger(subsystem: subsystem, category: "Sync")

    static func errorCategory(_ error: Error) -> String {
        if let serviceError = error as? RNFServiceError {
            return String(describing: serviceError)
        }

        return String(describing: type(of: error))
    }

}
