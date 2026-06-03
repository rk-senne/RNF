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
                WorkoutListView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .tabItem {
                Label("Workouts", systemImage: "figure.strengthtraining.traditional")
            }

            NavigationStack {
                ReadView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .tabItem {
                Label("Read", systemImage: "book.closed.fill")
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
