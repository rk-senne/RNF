import SwiftUI

@main
struct RNFApp: App {

    @StateObject var gameState = GameState()
    @StateObject var appStateManager = AppStateManager()

    var body: some Scene {

        WindowGroup {

            AppShellView(appStateManager: appStateManager)
                .environmentObject(gameState)

        }

    }

}
