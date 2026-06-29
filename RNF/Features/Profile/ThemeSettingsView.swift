import SwiftUI

struct ThemeSettingsView: View {
    @AppStorage("rnf_theme_preference") private var themeRaw = ThemePreference.system.rawValue

    private var selection: Binding<ThemePreference> {
        Binding(
            get: { ThemePreference(rawValue: themeRaw) ?? .system },
            set: { themeRaw = $0.rawValue }
        )
    }

    var body: some View {
        Section("Theme") {
            Picker("Appearance", selection: selection) {
                Text("Light").tag(ThemePreference.light)
                Text("Dark").tag(ThemePreference.dark)
                Text("System").tag(ThemePreference.system)
            }
            .pickerStyle(.segmented)
        }
    }
}
