import Foundation

/// Pure calculation struct for projecting future progress based on current pace.
/// No dependencies — takes historical data and returns projections.
struct ProgressForecast {

    // MARK: - Types

    enum ForecastRisk: String {
        case onTrack = "On Track"
        case slipping = "Slipping"
        case atRisk = "At Risk"

        var emoji: String {
            switch self {
            case .onTrack: return "✅"
            case .slipping: return "⚠️"
            case .atRisk: return "🔴"
            }
        }
    }

    struct Projection {
        /// Average habits completed per day (7-day rolling)
        let currentPace: Double
        /// Projected date to reach next level
        let projectedNextLevelDate: Date?
        /// Current risk assessment
        let riskLevel: ForecastRisk
        /// Projected streak tier at current pace (30 days from now)
        let projectedStreakTier: String
        /// Days until next streak tier milestone
        let daysToNextTier: Int?
        /// Pace trend: positive = improving, negative = declining
        let paceTrend: Double
    }

    // MARK: - Calculation

    /// Calculate a projection from daily log history.
    /// - Parameters:
    ///   - recentLogs: Last 14 days of daily logs (newest first)
    ///   - currentLevel: User's current level
    ///   - currentXP: User's total XP
    ///   - currentStreak: User's current streak
    /// - Returns: A Projection with pace, risk, and forecasts
    static func calculate(
        recentLogs: [DailyLog],
        currentLevel: Int,
        currentXP: Int,
        currentStreak: Int
    ) -> Projection {

        let pace7Day = calculatePace(logs: recentLogs, window: 7)
        let pace14Day = calculatePace(logs: recentLogs, window: 14)

        let trend = pace7Day - pace14Day // positive = improving

        let riskLevel = assessRisk(pace7Day: pace7Day, trend: trend)

        let projectedLevelDate = projectNextLevelDate(
            currentXP: currentXP,
            currentLevel: currentLevel,
            dailyPace: pace7Day
        )

        let projectedTier = projectStreakTier(currentStreak: currentStreak, daysAhead: 30)
        let daysToNext = daysToNextStreakTier(currentStreak: currentStreak)

        return Projection(
            currentPace: pace7Day,
            projectedNextLevelDate: projectedLevelDate,
            riskLevel: riskLevel,
            projectedStreakTier: projectedTier,
            daysToNextTier: daysToNext,
            paceTrend: trend
        )
    }

    // MARK: - Pace Calculation

    /// Average habits completed per day over the given window.
    static func calculatePace(logs: [DailyLog], window: Int) -> Double {
        let relevant = Array(logs.prefix(window))
        guard !relevant.isEmpty else { return 0.0 }

        let total = relevant.reduce(0) { $0 + $1.habits_completed }
        return Double(total) / Double(relevant.count)
    }

    // MARK: - Risk Assessment

    static func assessRisk(pace7Day: Double, trend: Double) -> ForecastRisk {
        // At risk: pace dropped below 1 habit/day
        if pace7Day < 1.0 {
            return .atRisk
        }

        // Slipping: declining trend (more than 0.5 habits/day drop)
        if trend < -0.5 {
            return .slipping
        }

        return .onTrack
    }

    // MARK: - Level Projection

    /// Project when the next level will be reached based on daily XP pace.
    static func projectNextLevelDate(
        currentXP: Int,
        currentLevel: Int,
        dailyPace: Double
    ) -> Date? {
        // XP per habit completion (base 10)
        let avgXPPerHabit = 13.0 // accounts for crits and multipliers
        let dailyXP = dailyPace * avgXPPerHabit

        guard dailyXP > 0 else { return nil }

        // XP needed for next level (simplified: 200 * level)
        let xpForNextLevel = 200 * (currentLevel + 1)
        let currentLevelXP = 200 * currentLevel
        let xpIntoLevel = currentXP - currentLevelXP
        let xpNeeded = max(0, xpForNextLevel - currentLevelXP - xpIntoLevel)

        guard xpNeeded > 0 else { return Date() }

        let daysNeeded = Int(ceil(Double(xpNeeded) / dailyXP))
        return Calendar.current.date(byAdding: .day, value: daysNeeded, to: Date())
    }

    // MARK: - Streak Tier Projection

    /// What streak tier the user will be in after `daysAhead` days at current pace.
    static func projectStreakTier(currentStreak: Int, daysAhead: Int) -> String {
        let projectedStreak = currentStreak + daysAhead
        return StreakTierSystem.tier(for: projectedStreak).rawValue
    }

    /// Days until the next streak tier milestone.
    static func daysToNextStreakTier(currentStreak: Int) -> Int? {
        let milestones = [7, 14, 30, 60, 90]
        for milestone in milestones {
            if currentStreak < milestone {
                return milestone - currentStreak
            }
        }
        return nil // Already at highest
    }
}
