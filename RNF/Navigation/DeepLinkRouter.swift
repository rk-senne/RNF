import Foundation
import SwiftUI
import os

// MARK: - P26-APL-34/35/36/37: Deep Link Router

/// Parses `rnf://` URL scheme into navigation destinations.
/// Supports onOpenURL handler integration and widget deep link URLs.
@MainActor
final class DeepLinkRouter: ObservableObject {

    // MARK: - Destination

    enum Destination: Equatable {
        // Core tabs
        case home
        case workouts
        case reading
        case ascension
        case profile

        // Specific features
        case habit(id: UUID)
        case challenge(id: String)
        case quest(id: UUID)
        case workout(id: UUID)
        case focusSession(type: String?)
        case boss(id: String?)
        case guild(id: String?)
        case leaderboard(id: String?)

        // Onboarding / Auth
        case login
        case signup

        // Settings & Management
        case settings
        case subscription
        case healthSettings
        case notifications

        // Social
        case social
        case inviteFriend(referralCode: String?)
        case microChallenge(id: String?)

        // Journey & Progress
        case journey
        case skillTree
        case achievements
        case evolution

        // Widget-triggered
        case dailyProgress
        case streakDetail
        case quickComplete(habitID: UUID)
    }

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.rnf.app", category: "DeepLink")

    @Published var pendingDestination: Destination?
    @Published var selectedTab: Int = 0

    // MARK: - P26-APL-34: URL Parsing

    /// Parses a `rnf://` URL into a navigation destination.
    /// - Parameter url: The incoming URL (e.g., `rnf://habit/uuid` or `rnf://workouts`)
    /// - Returns: The parsed Destination, or nil if the URL is invalid.
    func parse(url: URL) -> Destination? {
        guard url.scheme == "rnf" else {
            logger.warning("Unsupported URL scheme: \(url.scheme ?? "nil")")
            return nil
        }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        logger.info("Parsing deep link: \(url.absoluteString)")

        switch host {
        // Core navigation
        case "home", "":
            return .home
        case "workouts":
            if let first = pathComponents.first, let id = UUID(uuidString: first) {
                return .workout(id: id)
            }
            return .workouts
        case "reading", "read":
            return .reading
        case "ascension":
            return .ascension
        case "profile":
            return .profile

        // Habits
        case "habit":
            if let first = pathComponents.first, let id = UUID(uuidString: first) {
                return .habit(id: id)
            }
            return .home
        case "quick-complete":
            if let first = pathComponents.first, let id = UUID(uuidString: first) {
                return .quickComplete(habitID: id)
            }
            return .home

        // Challenge
        case "challenge":
            let id = pathComponents.first
            return .challenge(id: id ?? "")

        // Quest
        case "quest":
            if let first = pathComponents.first, let id = UUID(uuidString: first) {
                return .quest(id: id)
            }
            return .home

        // Focus
        case "focus":
            let type = pathComponents.first ?? queryParam("type", in: queryItems)
            return .focusSession(type: type)

        // Boss
        case "boss":
            return .boss(id: pathComponents.first)

        // Social
        case "social":
            return .social
        case "guild":
            return .guild(id: pathComponents.first)
        case "leaderboard":
            return .leaderboard(id: pathComponents.first)
        case "invite":
            let code = pathComponents.first ?? queryParam("code", in: queryItems)
            return .inviteFriend(referralCode: code)
        case "micro-challenge":
            return .microChallenge(id: pathComponents.first)

        // Auth
        case "login":
            return .login
        case "signup":
            return .signup

        // Settings
        case "settings":
            return .settings
        case "subscription":
            return .subscription
        case "health-settings":
            return .healthSettings
        case "notifications":
            return .notifications

        // Journey & Progress
        case "journey":
            return .journey
        case "skill-tree":
            return .skillTree
        case "achievements":
            return .achievements
        case "evolution":
            return .evolution

        // Widget shortcuts
        case "daily-progress":
            return .dailyProgress
        case "streak":
            return .streakDetail

        default:
            logger.warning("Unknown deep link host: \(host)")
            return nil
        }
    }

    // MARK: - P26-APL-35: Handle Incoming URL

    /// Handles an incoming URL by parsing and routing to the appropriate destination.
    /// Call this from `.onOpenURL` in your root view.
    func handleURL(_ url: URL) {
        guard let destination = parse(url: url) else {
            logger.warning("Could not parse URL: \(url.absoluteString)")
            return
        }

        // Update selected tab based on destination
        selectedTab = tabIndex(for: destination)
        pendingDestination = destination
        logger.info("Routed to: \(String(describing: destination))")
    }

    /// Clears the pending destination after navigation has been performed.
    func clearPendingDestination() {
        pendingDestination = nil
    }

    // MARK: - P26-APL-36: Widget URL Construction

    /// Constructs deep link URLs for widget tap actions.
    static func widgetURL(for action: WidgetAction) -> URL {
        switch action {
        case .openHome:
            return URL(string: "rnf://home")!
        case .openDailyProgress:
            return URL(string: "rnf://daily-progress")!
        case .openStreak:
            return URL(string: "rnf://streak")!
        case .openHabit(let id):
            return URL(string: "rnf://habit/\(id.uuidString)")!
        case .quickComplete(let id):
            return URL(string: "rnf://quick-complete/\(id.uuidString)")!
        case .openWorkouts:
            return URL(string: "rnf://workouts")!
        case .openFocus(let type):
            if let type {
                return URL(string: "rnf://focus/\(type)")!
            }
            return URL(string: "rnf://focus")!
        case .openProfile:
            return URL(string: "rnf://profile")!
        case .openLeaderboard(let id):
            if let id {
                return URL(string: "rnf://leaderboard/\(id)")!
            }
            return URL(string: "rnf://leaderboard")!
        }
    }

    /// P26-APL-37: Widget action types for URL construction.
    enum WidgetAction {
        case openHome
        case openDailyProgress
        case openStreak
        case openHabit(id: UUID)
        case quickComplete(id: UUID)
        case openWorkouts
        case openFocus(type: String?)
        case openProfile
        case openLeaderboard(id: String?)
    }

    // MARK: - Private Helpers

    private func tabIndex(for destination: Destination) -> Int {
        switch destination {
        case .home, .habit, .quest, .challenge, .dailyProgress, .streakDetail, .quickComplete:
            return 0
        case .workouts, .workout, .boss:
            return 1
        case .reading:
            return 2
        case .ascension, .journey, .skillTree, .evolution:
            return 3
        case .profile, .settings, .subscription, .healthSettings, .notifications, .achievements:
            return 4
        case .social, .guild, .leaderboard, .inviteFriend, .microChallenge:
            return 4
        case .focusSession:
            return 0
        case .login, .signup:
            return 0
        }
    }

    private func queryParam(_ name: String, in items: [URLQueryItem]) -> String? {
        items.first(where: { $0.name == name })?.value
    }
}

// MARK: - SwiftUI View Modifier for Deep Link Handling

struct DeepLinkHandlerModifier: ViewModifier {
    @EnvironmentObject var router: DeepLinkRouter

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                router.handleURL(url)
            }
    }
}

extension View {
    /// P26-APL-35: Adds deep link URL handling to any view.
    func handleDeepLinks() -> some View {
        modifier(DeepLinkHandlerModifier())
    }
}
