import SwiftUI

@main
struct RNFApp: App {

    @StateObject var gameState = GameState()

    var body: some Scene {

        WindowGroup {

            RootView()
                .environmentObject(gameState)

        }

    }

}
