import SwiftUI

struct RootView: View {

    var body: some View {

        TabView {

            NavigationStack {
                ContentView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .tabItem {
                Label("Habits", systemImage: "checkmark.circle")
            }

            NavigationStack {
                AscensionView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .tabItem {
                Label("Ascension", systemImage: "flame.fill")
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color(.systemBackground)
                .ignoresSafeArea()
        )
        .toolbarBackground(Color(.systemBackground), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

}
