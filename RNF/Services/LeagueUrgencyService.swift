import Foundation

/// Calculates demotion risk for league urgency notifications.
/// Drives mid-week re-engagement by alerting users at risk of demotion.
@MainActor
final class LeagueUrgencyService {

    // MARK: - Types

    enum DemotionRisk: Equatable {
        case safe
        case atRisk(spotsFromSafety: Int)
        case demotionLikely

        var shouldNotify: Bool {
            switch self {
            case .safe: return false
            case .atRisk, .demotionLikely: return true
            }
        }

        var urgencyMessage: String {
            switch self {
            case .safe:
                return "You're safe this week."
            case .atRisk(let spots):
                return "You're \(spots) spot\(spots == 1 ? "" : "s") from demotion. Complete a few more habits to stay."
            case .demotionLikely:
                return "Demotion likely. Any habits completed today will help your position."
            }
        }
    }

    struct WeekRecap: Equatable {
        let finalRank: Int
        let totalMembers: Int
        let tierName: String
        let promoted: Bool
        let demoted: Bool
        let weeklyXP: Int

        var summaryMessage: String {
            if promoted {
                return "🎉 Promoted! You finished #\(finalRank) and moved up to \(tierName)."
            }
            if demoted {
                return "You finished #\(finalRank) of \(totalMembers). You'll start next week in a lower league."
            }
            return "You finished #\(finalRank) of \(totalMembers) in \(tierName). \(weeklyXP) XP this week."
        }
    }

    // MARK: - Constants

    /// Bottom N positions are at risk of demotion
    static let demotionZoneSize = 5

    /// Day of week to send urgency notification (Thursday = 5)
    static let notificationDayOfWeek = 5

    // MARK: - Dependencies

    private let leagueService: LeagueService

    // MARK: - Init

    init(leagueService: LeagueService) {
        self.leagueService = leagueService
    }

    // MARK: - Risk Calculation

    /// Assess demotion risk based on current ranking.
    func assessDemotionRisk(
        currentRank: Int,
        totalMembers: Int,
        currentTier: LeagueService.Tier
    ) -> DemotionRisk {
        // Can't be demoted from lowest tier
        guard currentTier.previous != nil else { return .safe }

        let demotionLine = totalMembers - Self.demotionZoneSize + 1

        if currentRank >= totalMembers - 1 {
            return .demotionLikely
        }

        if currentRank >= demotionLine {
            let spotsFromSafety = currentRank - demotionLine + 1
            return .atRisk(spotsFromSafety: spotsFromSafety)
        }

        return .safe
    }

    /// Check if today is the right day to send urgency notification.
    func shouldSendUrgencyNotification(today: Date = Date()) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: today)
        return weekday == Self.notificationDayOfWeek
    }

    /// Generate the mid-week notification content if at risk.
    func generateUrgencyNotification(
        currentRank: Int,
        totalMembers: Int,
        currentTier: LeagueService.Tier
    ) -> (title: String, body: String)? {
        let risk = assessDemotionRisk(
            currentRank: currentRank,
            totalMembers: totalMembers,
            currentTier: currentTier
        )

        guard risk.shouldNotify else { return nil }

        let title = "League Alert: \(currentTier.rawValue)"
        return (title, risk.urgencyMessage)
    }

    // MARK: - Week Recap

    /// Generate a week recap card after league week resets.
    func generateWeekRecap(
        finalRank: Int,
        totalMembers: Int,
        tierName: String,
        promoted: Bool,
        demoted: Bool,
        weeklyXP: Int
    ) -> WeekRecap {
        WeekRecap(
            finalRank: finalRank,
            totalMembers: totalMembers,
            tierName: tierName,
            promoted: promoted,
            demoted: demoted,
            weeklyXP: weeklyXP
        )
    }
}
