import os

enum RNFLogger {
    static let general = Logger(subsystem: "com.rnf.app", category: "general")
    static let auth = Logger(subsystem: "com.rnf.app", category: "auth")
    static let dailyLog = Logger(subsystem: "com.rnf.app", category: "daily_log")
    static let habitCompletion = Logger(subsystem: "com.rnf.app", category: "habit_completion")
    static let challenge = Logger(subsystem: "com.rnf.app", category: "challenge")
    static let sync = Logger(subsystem: "com.rnf.app", category: "sync")
    static let engagement = Logger(subsystem: "com.rnf.app", category: "engagement")
    static let social = Logger(subsystem: "com.rnf.app", category: "social")

    /// General-purpose log method for quick debug messages.
    static func log(_ message: String) {
        general.info("\(message)")
    }
}
