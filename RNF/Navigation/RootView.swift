import SwiftUI

struct RootView: View {

    var body: some View {

        TabView {

            ContentView()
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle")
                }

            AscensionView()
                .tabItem {
                    Label("Ascension", systemImage: "flame.fill")
                }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

}
