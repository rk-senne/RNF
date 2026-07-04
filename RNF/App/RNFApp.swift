import SwiftUI
import AuthenticationServices

@main
struct RNFApp: App {

    @StateObject var gameState = GameState()
    @StateObject var appStateManager = AppStateManager()
    @AppStorage("rnf_theme_preference") private var themeRaw = ThemePreference.system.rawValue

    private var colorScheme: ColorScheme? {
        ThemePreference(rawValue: themeRaw)?.colorScheme
    }

    var body: some Scene {

        WindowGroup {

            StateRoutingView()
                .environmentObject(gameState)
                .environmentObject(appStateManager)
                .preferredColorScheme(colorScheme)
                .task {
                    await appStateManager.resolveLaunchState()
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: ASAuthorizationAppleIDProvider.credentialRevokedNotification
                )) { _ in
                    // P21-FIX-11: Handle Apple credential revocation
                    handleAppleCredentialRevocation()
                }
        }
    }

    /// Responds to Apple credential revocation by logging out the user.
    private func handleAppleCredentialRevocation() {
        Task {
            let authService = AuthService()
            try? await authService.logout()
            await MainActor.run {
                appStateManager.markLoggedOut()
            }
        }
    }
}
