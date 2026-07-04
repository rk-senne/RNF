import Foundation

/// Controls which feature groups are active in the current release.
/// This is the master switch — if a feature group is disabled here,
/// it won't appear in the app regardless of subscription or progression.
///
/// Release phases:
/// - v1.0.0: Core habit loop (auth, habits, challenges, workouts, reading, calendar)
/// - v1.1.0: Engagement (XP depth, quests, skills, achievements, evolution, boss, seasons)
/// - v1.2.0: Social (guilds, leagues, referrals, buddies, micro-challenges)
/// - v1.3.0: Platform (HealthKit, Watch, interactive widgets, app attest)
enum ReleaseGate {

    // MARK: - Current Release Version

    /// Bump this as features ship.
    static let currentRelease: Release = .v1_0_0

    enum Release: Int, Comparable {
        case v1_0_0 = 100
        case v1_1_0 = 110
        case v1_2_0 = 120
        case v1_3_0 = 130

        static func < (lhs: Release, rhs: Release) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Feature Groups

    enum FeatureGroup: CaseIterable {
        // v1.0.0 — Core
        case authentication
        case habitTracking
        case challenges
        case workouts
        case reading
        case calendar
        case forgiveness
        case subscription
        case notifications

        // v1.1.0 — Engagement
        case skillTree
        case achievements
        case evolution
        case bossChallenge
        case seasonalArcs
        case prestige
        case leagues
        case forgeTokens
        case microChallenges
        case adaptiveDifficulty
        case insights

        // v1.2.0 — Social
        case guilds
        case referrals
        case buddySystem
        case socialChallenges
        case contentModeration

        // v1.3.0 — Platform
        case healthKitIntegration
        case appleWatch
        case interactiveWidgets
        case appAttest
        case siriShortcuts

        var minimumRelease: Release {
            switch self {
            // Core — v1.0.0
            case .authentication, .habitTracking, .challenges,
                 .workouts, .reading, .calendar, .forgiveness,
                 .subscription, .notifications:
                return .v1_0_0

            // Engagement — v1.1.0
            case .skillTree, .achievements, .evolution,
                 .bossChallenge, .seasonalArcs, .prestige,
                 .leagues, .forgeTokens, .microChallenges,
                 .adaptiveDifficulty, .insights:
                return .v1_1_0

            // Social — v1.2.0
            case .guilds, .referrals, .buddySystem,
                 .socialChallenges, .contentModeration:
                return .v1_2_0

            // Platform — v1.3.0
            case .healthKitIntegration, .appleWatch,
                 .interactiveWidgets, .appAttest, .siriShortcuts:
                return .v1_3_0
            }
        }
    }

    // MARK: - Gate Checks

    /// Returns true if the feature group is enabled in the current release.
    static func isEnabled(_ group: FeatureGroup) -> Bool {
        group.minimumRelease <= currentRelease
    }

    /// Returns all feature groups enabled in the current release.
    static var enabledGroups: [FeatureGroup] {
        FeatureGroup.allCases.filter { isEnabled($0) }
    }

    /// Returns all feature groups NOT yet enabled.
    static var disabledGroups: [FeatureGroup] {
        FeatureGroup.allCases.filter { !isEnabled($0) }
    }
}
