import Foundation

enum AppState: Equatable {
    case loggedOut
    case authenticated
    case onboardingNotifications
    case onboardingCommitment
    case challengeActive
    case dailyProgress
    case dayComplete
    case missedDay
    case challengeComplete
    case offlineFallback
    case guestTryout
}
