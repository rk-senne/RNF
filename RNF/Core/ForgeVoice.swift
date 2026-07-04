import AVFoundation

/// Forge Voice — text-to-speech utility using AVSpeechSynthesizer.
/// Speaks motivational phrases at key moments with a calm, measured tone.
/// Daily limit of 2 utterances to avoid annoyance.
enum ForgeVoice {

    // MARK: - Configuration

    private static let speechRate: Float = 0.42
    private static let speechPitch: Float = 0.85
    private static let dailyLimit: Int = 2
    private static let defaultLanguage = "en-US"

    // MARK: - Synthesizer

    private static let synthesizer = AVSpeechSynthesizer()

    // MARK: - Public API

    /// Whether voice is enabled (Off/System/Oracle stored in UserDefaults).
    static var isEnabled: Bool {
        let value = UserDefaults.standard.string(forKey: "rnf_forge_voice")
        return value != nil && value != "off"
    }

    /// Speak a text phrase, respecting daily limit and enabled state.
    static func speak(_ text: String) {
        guard isEnabled else { return }
        guard !text.isEmpty else { return }
        guard withinDailyLimit() else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.voice = selectedVoice()
        utterance.volume = 0.8

        configureAudioSession()
        synthesizer.speak(utterance)
    }

    /// Speak without consuming daily limit (used for settings confirmation).
    static func speakBypassingLimit(_ text: String) {
        guard isEnabled else { return }
        guard !text.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.voice = selectedVoice()
        utterance.volume = 0.8

        configureAudioSession()
        synthesizer.speak(utterance)
    }

    /// Stop any ongoing speech immediately.
    static func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Returns number of utterances used today.
    static var todayUsageCount: Int {
        UserDefaults.standard.integer(forKey: dailyKey())
    }

    /// Resets today's usage count (used for testing).
    static func resetDailyUsage() {
        UserDefaults.standard.removeObject(forKey: dailyKey())
    }

    // MARK: - Private

    private static func withinDailyLimit() -> Bool {
        let key = dailyKey()
        let count = UserDefaults.standard.integer(forKey: key)
        guard count < dailyLimit else { return false }
        UserDefaults.standard.set(count + 1, forKey: key)
        return true
    }

    private static func dailyKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "rnf_voice_\(formatter.string(from: Date()))"
    }

    private static func selectedVoice() -> AVSpeechSynthesisVoice? {
        let preference = UserDefaults.standard.string(forKey: "rnf_forge_voice") ?? "system"
        switch preference {
        case "oracle":
            // Prefer enhanced voice if available
            return AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.en-US.Samantha")
                ?? AVSpeechSynthesisVoice(language: defaultLanguage)
        default:
            return AVSpeechSynthesisVoice(language: defaultLanguage)
        }
    }

    private static func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Silently fail — voice is non-critical
        }
    }
}
