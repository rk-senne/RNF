import SwiftUI

@MainActor
final class NotificationManager: ObservableObject {

    enum Toast: Equatable {
        case xpGain(Int)
        case statGain(String, Int)
        case discovery(String, Int) // P20-EXP-14c: name, XP
    }

    enum Celebration: Equatable {
        case levelUp(Int)
        case missionComplete
        case badgeUnlocked(String)
        case tierUp(String) // P20-EXP-05d
    }

    @Published var currentToast: Toast?
    @Published var currentCelebration: Celebration?

    func showToast(_ toast: Toast) {
        currentToast = toast
        // P20-VOX-03: Voice trigger on discovery
        if case .discovery(let name, _) = toast {
            ForgeVoice.speak("Discovery unlocked. \(name).")
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if currentToast == toast { currentToast = nil }
        }
    }

    func showCelebration(_ celebration: Celebration) {
        currentCelebration = celebration
        // P20-VOX-03: Voice triggers for celebrations
        switch celebration {
        case .levelUp(let level):
            ForgeVoice.speak("Level \(level). Your discipline grows.")
        case .missionComplete:
            break // No voice for daily complete to avoid overuse
        case .badgeUnlocked(let badge):
            ForgeVoice.speak("\(badge) unlocked.")
        case .tierUp(let tier):
            ForgeVoice.speak("Streak tier: \(tier). The forge burns brighter.")
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if currentCelebration == celebration { currentCelebration = nil }
        }
    }

    func dismissCelebration() {
        currentCelebration = nil
    }
}
