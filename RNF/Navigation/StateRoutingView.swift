import SwiftUI
import Auth

/// GAP 1: Routes navigation based on AppStateManager's published state.
/// Spec: RNF_STATE_MACHINE.md — Views react to state.
struct StateRoutingView: View {

    @EnvironmentObject var appStateManager: AppStateManager

    var body: some View {
        switch appStateManager.state {
        case .loggedOut:
            LoginView(
                onLogin: { _ in
                    appStateManager.markAuthenticated()
                    Task { await appStateManager.resolveLaunchState() }
                },
                onGuestTryout: {
                    appStateManager.startGuestTryout()
                }
            )

        case .authenticated:
            SplashView()

        case .onboardingNotifications:
            NotificationSetupView(onContinue: {
                appStateManager.completeNotificationSetup()
            })

        case .onboardingCommitment:
            CommitmentView(onBegin: {
                appStateManager.confirmCommitment()
            })

        case .challengeActive:
            RootView()
                .onAppear { appStateManager.enterDailyProgress() }

        case .dailyProgress, .dayComplete:
            RootView()

        case .missedDay:
            MissedDayView()

        case .challengeComplete:
            ChallengeCompletionView()

        case .offlineFallback:
            RootView()

        case .guestTryout:
            RootView()
        }
    }
}
