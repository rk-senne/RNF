import SwiftUI

/// Combined settings screen with theme, voice, and health preferences.
struct SettingsView: View {
    var body: some View {
        List {
            ThemeSettingsView()
            VoiceSettingsView()
            HealthSettingsSection()
        }
        .navigationTitle("Settings")
    }
}
