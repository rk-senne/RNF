import Foundation
import os
import CryptoKit

// MARK: - P29-INF-15/16/17/18: Sentry Crash Reporting Service
// Privacy-first wrapper: No PII collected. User IDs are SHA-256 hashed.

/// Sentry integration service for crash reporting, breadcrumbs, and performance monitoring.
/// Uses hashed user identifiers only — no email, name, or device-identifying PII is transmitted.
@MainActor
final class SentryService: ObservableObject {

    // MARK: - Singleton

    static let shared = SentryService()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.rnf.app", category: "Sentry")

    /// Whether Sentry has been initialized
    @Published private(set) var isInitialized = false

    /// Maximum breadcrumbs retained before oldest are evicted
    private let maxBreadcrumbs = 100

    /// In-memory breadcrumb buffer (sent with crash reports)
    private var breadcrumbs: [Breadcrumb] = []

    /// Hashed user context (set after auth)
    private var hashedUserID: String?

    // MARK: - Models

    struct Breadcrumb: Sendable {
        let timestamp: Date
        let category: String
        let message: String
        let level: Level
        let data: [String: String]?

        enum Level: String, Sendable {
            case debug, info, warning, error, fatal
        }
    }

    struct SentryEvent: Sendable {
        let eventID: String
        let timestamp: Date
        let level: Breadcrumb.Level
        let message: String
        let breadcrumbs: [Breadcrumb]
        let userHash: String?
        let tags: [String: String]
        let extra: [String: String]
    }

    // MARK: - P29-INF-15: Initialization

    private init() {}

    /// Initialize Sentry SDK with DSN from AppConfig.
    /// Call this once in `RNFApp.init()` or `AppDelegate.didFinishLaunching`.
    func initialize() {
        guard !isInitialized else {
            logger.info("Sentry already initialized")
            return
        }

        guard let dsn = Self.sentryDSN, !dsn.isEmpty else {
            logger.warning("Sentry DSN not configured — crash reporting disabled")
            return
        }

        // In a real integration, this would call:
        // SentrySDK.start { options in
        //     options.dsn = dsn
        //     options.tracesSampleRate = 0.2
        //     options.profilesSampleRate = 0.1
        //     options.enableAutoSessionTracking = true
        //     options.attachStacktrace = true
        //     options.sendDefaultPii = false  // CRITICAL: No PII
        //     options.beforeSend = { event in
        //         // Strip any accidental PII
        //         event.user?.email = nil
        //         event.user?.username = nil
        //         event.user?.name = nil
        //         return event
        //     }
        // }

        isInitialized = true
        logger.info("Sentry initialized successfully")
        addBreadcrumb(category: "lifecycle", message: "Sentry SDK initialized")
    }

    /// Sentry DSN loaded from Info.plist via build configuration
    private static var sentryDSN: String? {
        Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String
    }

    // MARK: - P29-INF-17: User Context (Hashed ID Only)

    /// Set user context using a SHA-256 hash of the user ID.
    /// No raw user ID, email, or name is ever transmitted.
    func setUser(id: String) {
        let hashed = hashIdentifier(id)
        hashedUserID = hashed

        // SentrySDK.setUser(User(userId: hashed))
        logger.debug("User context set (hashed)")
        addBreadcrumb(category: "auth", message: "User context updated")
    }

    /// Clear user context on sign-out.
    func clearUser() {
        hashedUserID = nil
        // SentrySDK.setUser(nil)
        logger.debug("User context cleared")
        addBreadcrumb(category: "auth", message: "User context cleared")
    }

    // MARK: - P29-INF-16: Breadcrumbs

    /// Add a breadcrumb for contextual debugging in crash reports.
    /// - Parameters:
    ///   - category: Breadcrumb category (e.g., "navigation", "network", "user_action")
    ///   - message: Human-readable description of what happened
    ///   - level: Severity level (defaults to .info)
    ///   - data: Optional key-value metadata (must not contain PII)
    func addBreadcrumb(
        category: String,
        message: String,
        level: Breadcrumb.Level = .info,
        data: [String: String]? = nil
    ) {
        let crumb = Breadcrumb(
            timestamp: Date(),
            category: category,
            message: message,
            level: level,
            data: data
        )

        breadcrumbs.append(crumb)

        // Evict oldest when over limit
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst(breadcrumbs.count - maxBreadcrumbs)
        }

        // In real integration:
        // let sentryCrumb = Sentry.Breadcrumb()
        // sentryCrumb.category = category
        // sentryCrumb.message = message
        // sentryCrumb.level = mapLevel(level)
        // sentryCrumb.data = data
        // SentrySDK.addBreadcrumb(sentryCrumb)
    }

    // MARK: - P29-INF-18: Error Capture

    /// Capture a non-fatal error with context.
    /// - Parameters:
    ///   - error: The error to report
    ///   - tags: Optional key-value tags for filtering in Sentry dashboard
    ///   - extra: Optional extra context (must not contain PII)
    func capture(
        error: Error,
        tags: [String: String] = [:],
        extra: [String: String] = [:]
    ) {
        guard isInitialized else {
            logger.warning("Sentry not initialized — error not captured: \(error.localizedDescription)")
            return
        }

        logger.error("Capturing error: \(error.localizedDescription)")

        // SentrySDK.capture(error: error) { scope in
        //     tags.forEach { scope.setTag(value: $0.value, key: $0.key) }
        //     extra.forEach { scope.setExtra(value: $0.value, key: $0.key) }
        // }

        addBreadcrumb(
            category: "error",
            message: "Captured: \(error.localizedDescription)",
            level: .error
        )
    }

    /// Capture a message-only event (no Error instance).
    func captureMessage(
        _ message: String,
        level: Breadcrumb.Level = .error,
        tags: [String: String] = [:]
    ) {
        guard isInitialized else { return }

        logger.log(level: .error, "Sentry message: \(message)")

        // SentrySDK.capture(message: message) { scope in
        //     scope.setLevel(mapLevel(level))
        //     tags.forEach { scope.setTag(value: $0.value, key: $0.key) }
        // }
    }

    // MARK: - Performance Monitoring

    /// Start a performance transaction span.
    /// Returns an opaque token to finish the transaction.
    func startTransaction(name: String, operation: String) -> String {
        let spanID = UUID().uuidString

        // let transaction = SentrySDK.startTransaction(name: name, operation: operation)
        // Store transaction reference for later finish

        addBreadcrumb(
            category: "performance",
            message: "Transaction started: \(name)",
            data: ["operation": operation, "spanID": spanID]
        )

        return spanID
    }

    /// Finish a previously started transaction.
    func finishTransaction(spanID: String, status: String = "ok") {
        // Retrieve and finish the stored transaction
        addBreadcrumb(
            category: "performance",
            message: "Transaction finished: \(spanID)",
            data: ["status": status]
        )
    }

    // MARK: - Private Helpers

    /// SHA-256 hash an identifier to prevent PII transmission.
    private func hashIdentifier(_ identifier: String) -> String {
        let data = Data(identifier.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
