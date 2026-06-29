import StoreKit
import UIKit

@MainActor
final class RatingPromptService {

    private static let lastPromptKey = "rnf_last_rating_prompt_date"
    private static let cooldownDays = 90

    static func requestIfEligible(streak: Int, totalHabits: Int, daysSinceInstall: Int) {
        guard daysSinceInstall >= 3 else { return }
        guard streak == 7 || streak == 30 || totalHabits == 50 else { return }
        guard !isInCooldown() else { return }

        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            AppStore.requestReview(in: scene)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastPromptKey)
        }
    }

    private static func isInCooldown() -> Bool {
        let last = UserDefaults.standard.double(forKey: lastPromptKey)
        guard last > 0 else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: last), to: Date()).day ?? 0
        return days < cooldownDays
    }
}
