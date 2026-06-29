import os

enum RNFLogger {
    static let auth = Logger(subsystem: "com.rnf.app", category: "auth")
    static let dailyLog = Logger(subsystem: "com.rnf.app", category: "daily_log")
    static let habitCompletion = Logger(subsystem: "com.rnf.app", category: "habit_completion")
    static let challenge = Logger(subsystem: "com.rnf.app", category: "challenge")
    static let sync = Logger(subsystem: "com.rnf.app", category: "sync")
}
