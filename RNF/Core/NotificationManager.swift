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
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if currentToast == toast { currentToast = nil }
        }
    }

    func showCelebration(_ celebration: Celebration) {
        currentCelebration = celebration
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if currentCelebration == celebration { currentCelebration = nil }
        }
    }

    func dismissCelebration() {
        currentCelebration = nil
    }
}
