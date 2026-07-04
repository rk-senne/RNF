import SwiftUI

/// Voice setting section for Profile — Off / System / Oracle.
/// Speaks "Activated" as confirmation when a voice option is selected.
struct VoiceSettingsView: View {
    @AppStorage("rnf_forge_voice") private var voiceRaw = "off"

    private var selection: Binding<ForgeVoiceMode> {
        Binding(
            get: { ForgeVoiceMode(rawValue: voiceRaw) ?? .off },
            set: { newValue in
                let previous = voiceRaw
                voiceRaw = newValue.rawValue
                if newValue != .off && previous != newValue.rawValue {
                    ForgeVoice.speakBypassingLimit("Activated")
                } else if newValue == .off {
                    ForgeVoice.stop()
                }
            }
        )
    }

    var body: some View {
        Section("Forge Voice") {
            Picker("Voice", selection: selection) {
                Text("Off").tag(ForgeVoiceMode.off)
                Text("System").tag(ForgeVoiceMode.system)
                Text("Oracle").tag(ForgeVoiceMode.oracle)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Forge Voice selection")
            .accessibilityHint("Choose Off to disable, System for default voice, or Oracle for enhanced voice")
        }
    }
}

/// Voice mode options stored in UserDefaults.
enum ForgeVoiceMode: String, CaseIterable {
    case off
    case system
    case oracle
}
