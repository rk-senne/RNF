import AVFoundation

enum ForgeVoice {
    private static var player: AVAudioPlayer?

    static var isEnabled: Bool {
        UserDefaults.standard.string(forKey: "rnf_forge_voice") != nil &&
        UserDefaults.standard.string(forKey: "rnf_forge_voice") != "off"
    }

    static func speak(_ clipName: String) {
        guard isEnabled else { return }
        guard AVAudioSession.sharedInstance().outputVolume > 0 else { return }
        guard withinDailyLimit() else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { return }

        guard let url = Bundle.main.url(forResource: clipName, withExtension: "caf") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 0.75
        player?.play()
    }

    static func speakBypassingLimit(_ clipName: String) {
        guard isEnabled else { return }
        guard AVAudioSession.sharedInstance().outputVolume > 0 else { return }
        guard let url = Bundle.main.url(forResource: clipName, withExtension: "caf") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 0.75
        player?.play()
    }

    private static func withinDailyLimit() -> Bool {
        let key = "rnf_voice_\(todayKey())"
        let count = UserDefaults.standard.integer(forKey: key)
        guard count < 2 else { return false }
        UserDefaults.standard.set(count + 1, forKey: key)
        return true
    }

    private static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
