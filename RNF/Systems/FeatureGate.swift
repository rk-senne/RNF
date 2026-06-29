import Foundation

/// Determines which features are available based on user progression.
/// Phase 3 features are gated — they only appear when the user is ready.
enum FeatureGate {

    enum Feature: String, CaseIterable {
        case bossChallenge
        case achievements
        case masteryPaths
        case advancedTitles
        case guilds
        case leaderboards
        case socialChallenges
    }

    struct Requirements {
        let minLevel: Int
        let minStreak: Int
        let requiresChallengeComplete: Bool
    }

    static func requirements(for feature: Feature) -> Requirements {
        switch feature {
        case .bossChallenge:
            return Requirements(minLevel: 10, minStreak: 14, requiresChallengeComplete: false)
        case .achievements:
            return Requirements(minLevel: 5, minStreak: 7, requiresChallengeComplete: false)
        case .masteryPaths:
            return Requirements(minLevel: 15, minStreak: 30, requiresChallengeComplete: true)
        case .advancedTitles:
            return Requirements(minLevel: 10, minStreak: 30, requiresChallengeComplete: true)
        case .guilds:
            return Requirements(minLevel: 5, minStreak: 7, requiresChallengeComplete: false)
        case .leaderboards:
            return Requirements(minLevel: 3, minStreak: 3, requiresChallengeComplete: false)
        case .socialChallenges:
            return Requirements(minLevel: 7, minStreak: 14, requiresChallengeComplete: false)
        }
    }

    static func isUnlocked(
        _ feature: Feature,
        level: Int,
        streak: Int,
        hasCompletedChallenge: Bool
    ) -> Bool {
        let reqs = requirements(for: feature)
        if level < reqs.minLevel { return false }
        if streak < reqs.minStreak { return false }
        if reqs.requiresChallengeComplete && !hasCompletedChallenge { return false }
        return true
    }

    static func unlockedFeatures(
        level: Int,
        streak: Int,
        hasCompletedChallenge: Bool
    ) -> Set<Feature> {
        Set(Feature.allCases.filter {
            isUnlocked($0, level: level, streak: streak, hasCompletedChallenge: hasCompletedChallenge)
        })
    }
}
