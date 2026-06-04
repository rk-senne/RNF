import SwiftUI

enum AppShellRoute: Equatable {
    case auth
    case notifications
    case commitment
    case challengeComplete
    case mainTabs

    init(appState: AppState) {
        switch appState {
        case .loggedOut:
            self = .auth
        case .onboardingNotifications:
            self = .notifications
        case .onboardingCommitment:
            self = .commitment
        case .challengeComplete:
            self = .challengeComplete
        case .authenticated,
             .challengeActive,
             .dailyProgress,
             .dayComplete:
            self = .mainTabs
        }
    }
}

struct AppShellView: View {

    @ObservedObject private var appStateManager: AppStateManager
    @State private var didResolveLaunchState = false

    init(appStateManager: AppStateManager) {
        self.appStateManager = appStateManager
    }

    var body: some View {
        Group {
            switch AppShellRoute(appState: appStateManager.state) {
            case .auth:
                AuthFlowView(appStateManager: appStateManager)
            case .notifications:
                NavigationStack {
                    NotificationSetupView(
                        onContinue: appStateManager.completeNotificationSetup
                    )
                }
            case .commitment:
                NavigationStack {
                    CommitmentView(
                        onBegin: appStateManager.confirmCommitment
                    )
                }
            case .challengeComplete:
                NavigationStack {
                    ChallengeCompletionView { _ in
                        appStateManager.startNewChallengeDay()
                    }
                }
            case .mainTabs:
                RootView()
            }
        }
        .task {
            guard !didResolveLaunchState else {
                return
            }

            didResolveLaunchState = true
            await appStateManager.resolveLaunchState()
        }
    }

}

private struct AuthFlowView: View {

    @ObservedObject var appStateManager: AppStateManager
    @State private var isShowingSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isShowingSignUp {
                    SignUpView { result in
                        handleSignUp(result)
                    }
                } else {
                    LoginView { _ in
                        resolveLaunchState()
                    }
                }

                Button(isShowingSignUp ? "Sign In" : "Create Account") {
                    isShowingSignUp.toggle()
                }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func handleSignUp(_ result: SignUpResult) {
        guard result.session != nil else {
            isShowingSignUp = false
            return
        }

        resolveLaunchState()
    }

    private func resolveLaunchState() {
        Task {
            await appStateManager.resolveLaunchState()
        }
    }

}
