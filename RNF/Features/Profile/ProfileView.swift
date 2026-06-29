import SwiftUI

struct ProfileView: View {
    var body: some View {
        List {
            ThemeSettingsView()
            HealthSettingsSection()
        }
        .navigationTitle("Profile")
    }
}
