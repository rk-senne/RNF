import Foundation
import Auth
import Combine

@MainActor
final class AppStateManager: ObservableObject {

    @Published private(set) var state: AppState

    private let authService: AuthService
    private let challengeService: ChallengeService
    private let dailyLogService: DailyLogService
    private let analyticsService: AnalyticsService

    init(
        initialState: AppState = .loggedOut,
        supabase: SupabaseService = .shared,
        authService: AuthService? = nil,
        challengeService: ChallengeService = ChallengeService(),
        dailyLogService: DailyLogService = DailyLogService(),
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.state = initialState
        self.authService = authService ?? AuthService(supabase: supabase)
        self.challengeService = challengeService
        self.dailyLogService = dailyLogService
        self.analyticsService = analyticsService
    }

    func resolveLaunchState(date: Date = Date()) async {
        let userId: UUID

        do {
            let session = try await authService.restoreSession()
            userId = session.user.id
            markAuthenticated()
            await analyticsService.trackEvent(
                .appOpened,
                properties: [
                    "user_id": userId.uuidString,
                    "timestamp": Self.analyticsTimestamp(for: date),
                    "device_type": "ios"
                ]
            )
        } catch {
            markLoggedOut()
            return
        }

        do {
            guard try await challengeService.getActiveChallenge(userId: userId) != nil else {
                state = .onboardingNotifications
                return
            }

            if try await dailyLogService.fetchTodayLog(userId: userId, date: date) == nil {
                _ = try await dailyLogService.createDailyLog(userId: userId, date: date)
            }

            state = .dailyProgress
        } catch {
            state = .authenticated
        }
    }

    func markAuthenticated() {
        state = .authenticated
    }

    func markLoggedOut() {
        state = .loggedOut
    }

    func completeNotificationSetup() {
        state = .onboardingCommitment
    }

    func confirmCommitment() {
        state = .challengeActive
    }

    func enterDailyProgress() {
        state = .dailyProgress
    }

    func markDayComplete() {
        state = .dayComplete
    }

    func startNewChallengeDay() {
        state = .challengeActive
    }

    func markChallengeComplete() {
        state = .challengeComplete
    }

    func routeToCommitmentAfterRestart() {
        state = .onboardingCommitment
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

}
