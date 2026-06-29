import SwiftUI

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

        }

    }

}
