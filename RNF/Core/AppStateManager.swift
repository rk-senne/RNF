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
                    "timestamp": Self.analyticsTimestamp(for: date),
                    "device_type": "ios"
                ]
            )
        } catch {
            if !NetworkMonitor.shared.isConnected {
                state = .offlineFallback
            } else {
                markLoggedOut()
            }
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

            // GAP 2: Check yesterday's log for missed-day forgiveness prompt
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
            if let yesterdayLog = try? await dailyLogService.fetchTodayLog(userId: userId, date: yesterday),
               yesterdayLog.status == .missed,
               !yesterdayLog.forgiveness_used {
                state = .missedDay
                return
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

    func startGuestTryout() {
        state = .guestTryout
    }

    func promoteGuestToAuthenticated() {
        state = .onboardingNotifications
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

    /// GAP 2: Transition to missedDay when end-of-day evaluation detects incomplete goals.
    func markDayMissed() {
        state = .missedDay
    }

    /// After forgiveness is used or dismissed from missedDay, return to daily progress.
    func resolveAfterMissedDay() {
        state = .dailyProgress
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
        AnalyticsTimestamp.string(for: date)
    }

}
