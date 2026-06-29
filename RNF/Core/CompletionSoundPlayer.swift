import AVFoundation

// P20-EXP-02d: Plays a completion sound on habit check-off.
enum CompletionSoundPlayer {
    private static var player: AVAudioPlayer?

    static func play() {
        guard UserDefaults.standard.bool(forKey: "rnf_sound_enabled") else { return }
        guard let url = Bundle.main.url(forResource: "completion", withExtension: "caf") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 0.3
        player?.play()
    }
}
