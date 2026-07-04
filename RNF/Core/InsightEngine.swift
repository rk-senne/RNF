import Foundation
import os

// MARK: - P25-INT-12/13/14/15/16: Insight Engine

/// Analyzes 28-day data for behavioral patterns.
/// Produces actionable insights: best/worst days, time-of-day correlation,
/// stat growth rates. Uses statistical significance thresholds.
@MainActor
final class InsightEngine {

    // MARK: - Types

    enum InsightType: String, Codable {
        case bestDay = "best_day"
        case worstDay = "worst_day"
        case timeCorrelation = "time_correlation"
        case statGrowthRate = "stat_growth_rate"
        case streakPattern = "streak_pattern"
    }

    struct Insight: Codable, Identifiable {
        let id: UUID
        let type: InsightType
        let title: String
        let description: String
        let confidence: Double  // 0.0 - 1.0
        let generatedAt: Date
    }

    struct DayPerformance: Equatable {
        let dayOfWeek: Int  // 1 = Sunday ... 7 = Saturday
        let dayName: String
        let completionRate: Double
        let sampleCount: Int
    }

    struct TimeCorrelation: Equatable {
        let preferredWindow: String  // e.g. "Morning (6-9 AM)"
        let windowCompletionRate: Double
        let outsideWindowRate: Double
        let isSignificant: Bool
    }

    struct StatGrowthInsight: Equatable {
        let statName: String
        let weeklyGrowthRate: Double
        let projectedMonthly: Double
        let trend: Trend
    }

    enum Trend: String, Codable {
        case accelerating
        case steady
        case decelerating
        case flat
    }

    struct CompletionEntry {
        let date: Date
        let completedCount: Int
        let targetCount: Int
    }

    // MARK: - Constants

    private static let _analysisWindowDays = 28
    private static let minimumSamplesPerDay = 3
    private static let significanceThreshold: Double = 0.15  // 15% difference required

    // MARK: - Dependencies

    private static let logger = Logger(subsystem: "com.rnf.app", category: "insight_engine")

    // MARK: - Cache

    private static let insightsCacheKey = "rnf_insights_cache"

    // MARK: - Init

    init() {}

    // MARK: - Public API

    /// Generates all available insights from 28-day completion data.
    func generateInsights(entries: [CompletionEntry], timestamps: [Date]) -> [Insight] {
        var insights: [Insight] = []

        if let bestWorst = analyzeDayOfWeek(entries: entries) {
            insights.append(contentsOf: bestWorst)
        }

        if let timeInsight = analyzeTimeOfDayCorrelation(timestamps: timestamps) {
            insights.append(timeInsight)
        }

        if let growthInsight = analyzeStatGrowth(entries: entries) {
            insights.append(growthInsight)
        }

        cacheInsights(insights)
        return insights
    }

    /// Finds the best and worst performing days of the week.
    func analyzeDayOfWeek(entries: [CompletionEntry]) -> [Insight]? {
        let calendar = Calendar.current
        let now = Date()

        let recentEntries = entries.filter {
            let daysDiff = calendar.dateComponents([.day], from: $0.date, to: now).day ?? 999
            return daysDiff < Self._analysisWindowDays
        }

        // Group by day of week
        var dayGroups: [Int: [Double]] = [:]
        for entry in recentEntries {
            let weekday = calendar.component(.weekday, from: entry.date)
            let rate = entry.targetCount > 0 ? Double(entry.completedCount) / Double(entry.targetCount) : 0
            dayGroups[weekday, default: []].append(rate)
        }

        // Require minimum samples for each day
        let validDays: [DayPerformance] = dayGroups.compactMap { weekday, rates in
            guard rates.count >= Self.minimumSamplesPerDay else { return nil }
            let avgRate = rates.reduce(0, +) / Double(rates.count)
            return DayPerformance(
                dayOfWeek: weekday,
                dayName: dayNameFor(weekday),
                completionRate: avgRate,
                sampleCount: rates.count
            )
        }

        guard validDays.count >= 5 else { return nil }

        let sorted = validDays.sorted { $0.completionRate > $1.completionRate }
        guard let best = sorted.first, let worst = sorted.last else { return nil }

        // Statistical significance: best must be significantly better than worst
        let difference = best.completionRate - worst.completionRate
        guard difference >= Self.significanceThreshold else { return nil }

        var insights: [Insight] = []

        insights.append(Insight(
            id: UUID(),
            type: .bestDay,
            title: "Best day: \(best.dayName)",
            description: "You complete \(Int(best.completionRate * 100))% of habits on \(best.dayName)s — your strongest day.",
            confidence: min(1.0, difference / 0.3),
            generatedAt: Date()
        ))

        insights.append(Insight(
            id: UUID(),
            type: .worstDay,
            title: "Toughest day: \(worst.dayName)",
            description: "Only \(Int(worst.completionRate * 100))% completion on \(worst.dayName)s. Consider reducing your goal.",
            confidence: min(1.0, difference / 0.3),
            generatedAt: Date()
        ))

        return insights
    }

    /// Analyzes time-of-day correlation with completion success.
    func analyzeTimeOfDayCorrelation(timestamps: [Date]) -> Insight? {
        guard timestamps.count >= 14 else { return nil }

        let calendar = Calendar.current

        // Define time windows
        let windows: [(name: String, range: ClosedRange<Int>)] = [
            ("Early morning (5-7 AM)", 5...6),
            ("Morning (7-10 AM)", 7...9),
            ("Midday (10 AM-1 PM)", 10...12),
            ("Afternoon (1-5 PM)", 13...16),
            ("Evening (5-9 PM)", 17...20),
            ("Night (9 PM-12 AM)", 21...23)
        ]

        var windowCounts: [(name: String, count: Int)] = []
        for window in windows {
            let count = timestamps.filter { ts in
                let hour = calendar.component(.hour, from: ts)
                return window.range.contains(hour)
            }.count
            windowCounts.append((name: window.name, count: count))
        }

        guard let preferred = windowCounts.max(by: { $0.count < $1.count }),
              preferred.count > 0 else {
            return nil
        }

        let totalCount = timestamps.count
        let preferredRate = Double(preferred.count) / Double(totalCount)
        let outsideRate = Double(totalCount - preferred.count) / Double(max(1, totalCount))

        // Only report if significantly concentrated in one window
        guard preferredRate >= 0.35 else { return nil }

        return Insight(
            id: UUID(),
            type: .timeCorrelation,
            title: "Peak time: \(preferred.name)",
            description: "\(Int(preferredRate * 100))% of your completions happen during \(preferred.name.lowercased()). This is your sweet spot.",
            confidence: min(1.0, preferredRate / 0.5),
            generatedAt: Date()
        )
    }

    /// Analyzes stat growth rate over the 28-day window.
    func analyzeStatGrowth(entries: [CompletionEntry]) -> Insight? {
        let calendar = Calendar.current
        let now = Date()

        let sorted = entries
            .filter { calendar.dateComponents([.day], from: $0.date, to: now).day ?? 999 < Self._analysisWindowDays }
            .sorted { $0.date < $1.date }

        guard sorted.count >= 14 else { return nil }

        // Split into first half and second half
        let midpoint = sorted.count / 2
        let firstHalf = Array(sorted[..<midpoint])
        let secondHalf = Array(sorted[midpoint...])

        let firstRate = averageCompletionRate(firstHalf)
        let secondRate = averageCompletionRate(secondHalf)

        let growthRate = secondRate - firstRate
        let weeklyGrowthRate = growthRate / 2.0  // Approximate weekly delta

        let trend: Trend
        if growthRate > 0.05 {
            trend = .accelerating
        } else if growthRate > 0.01 {
            trend = .steady
        } else if growthRate < -0.05 {
            trend = .decelerating
        } else {
            trend = .flat
        }

        // Only generate insight if change is significant
        guard abs(growthRate) >= Self.significanceThreshold else { return nil }

        let direction = growthRate > 0 ? "up" : "down"
        let pctChange = Int(abs(growthRate) * 100)

        return Insight(
            id: UUID(),
            type: .statGrowthRate,
            title: "Habit rate trending \(direction)",
            description: "Your completion rate is \(direction) \(pctChange)% over 4 weeks. Trend: \(trend.rawValue).",
            confidence: min(1.0, abs(growthRate) / 0.25),
            generatedAt: Date()
        )
    }

    /// Returns cached insights if available.
    func cachedInsights() -> [Insight]? {
        guard let data = UserDefaults.standard.data(forKey: Self.insightsCacheKey) else { return nil }
        return try? JSONDecoder().decode([Insight].self, from: data)
    }

    // MARK: - Private Helpers

    private func averageCompletionRate(_ entries: [CompletionEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        let rates = entries.map { e -> Double in
            guard e.targetCount > 0 else { return 0 }
            return Double(e.completedCount) / Double(e.targetCount)
        }
        return rates.reduce(0, +) / Double(rates.count)
    }

    private func dayNameFor(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.weekdaySymbols[weekday - 1]
    }

    private func cacheInsights(_ insights: [Insight]) {
        guard let data = try? JSONEncoder().encode(insights) else { return }
        UserDefaults.standard.set(data, forKey: Self.insightsCacheKey)
    }

    // MARK: - Static Testable APIs

    /// Analysis window in days.
    static let analysisWindowDays = 28

    /// Minimum variance between best and worst day to surface day-of-week insight.
    static let minimumDayVariance: Double = 0.15

    /// Minimum difference between AM/PM outcomes to surface time pattern insight.
    static let minimumTimePatternDifference: Double = 0.25

    /// Insight types for static test API.
    enum StaticInsightType: Equatable {
        case bestDay
        case worstDay
        case timePattern
        case statFocus
        case consistency
    }

    /// A pattern result for testing.
    struct PatternResult: Equatable {
        let type: StaticInsightType
        let dayOfWeek: Int?
        let habitName: String?
        let relatedStat: String?

        init(type: StaticInsightType, dayOfWeek: Int? = nil, habitName: String? = nil, relatedStat: String? = nil) {
            self.type = type
            self.dayOfWeek = dayOfWeek
            self.habitName = habitName
            self.relatedStat = relatedStat
        }
    }

    /// Time pattern data for testing.
    struct TimePatternData {
        let amCompletionRate: Double
        let pmCompletionRate: Double
    }

    /// Habit streak data for testing.
    struct HabitStreak {
        let habitName: String
        let currentStreak: Int
    }

    /// Scored insight for selection testing.
    struct ScoredInsight: Equatable {
        let type: StaticInsightType
        let score: Double
    }

    /// Detects best/worst day patterns from daily completion rates.
    static func detectPatterns(completionsByDay: [Int: Double]) -> [PatternResult] {
        guard completionsByDay.count >= 5 else { return [] }

        let average = completionsByDay.values.reduce(0, +) / Double(completionsByDay.count)

        var results: [PatternResult] = []

        // Best day: ≥90% AND ≥20% higher than average
        if let bestEntry = completionsByDay.max(by: { $0.value < $1.value }),
           bestEntry.value >= 0.90,
           (bestEntry.value - average) >= 0.20 {
            // Check variance
            let worst = completionsByDay.values.min() ?? 0
            if (bestEntry.value - worst) >= minimumDayVariance {
                results.append(PatternResult(type: .bestDay, dayOfWeek: bestEntry.key))
            }
        }

        // Worst day: ≤50% AND ≥20% lower than average
        if let worstEntry = completionsByDay.min(by: { $0.value < $1.value }),
           worstEntry.value <= 0.50,
           (average - worstEntry.value) >= 0.20 {
            let best = completionsByDay.values.max() ?? 0
            if (best - worstEntry.value) >= minimumDayVariance {
                results.append(PatternResult(type: .worstDay, dayOfWeek: worstEntry.key))
            }
        }

        return results
    }

    /// Detects time-of-day patterns from AM/PM completion rates.
    static func detectTimePatterns(data: TimePatternData) -> [PatternResult] {
        let difference = abs(data.amCompletionRate - data.pmCompletionRate)
        guard difference >= minimumTimePatternDifference else { return [] }
        return [PatternResult(type: .timePattern)]
    }

    /// Detects stat focus when one stat grew ≥30% more than others.
    static func detectStatFocus(growthRates: [String: Double]) -> [PatternResult] {
        guard growthRates.count >= 2 else { return [] }

        let sorted = growthRates.sorted { $0.value > $1.value }
        guard let best = sorted.first, sorted.count >= 2 else { return [] }

        let secondBest = sorted[1].value
        let advantage = best.value - secondBest

        guard advantage >= 0.30 else { return [] }

        return [PatternResult(type: .statFocus, relatedStat: best.key)]
    }

    /// Detects consistency patterns for habits with streaks ≥ 14 days.
    static func detectConsistency(streaks: [HabitStreak]) -> [PatternResult] {
        guard let best = streaks.max(by: { $0.currentStreak < $1.currentStreak }),
              best.currentStreak >= 14 else {
            return []
        }
        return [PatternResult(type: .consistency, habitName: best.habitName)]
    }

    /// Computes the novelty factor for an insight.
    /// - Parameters:
    ///   - insightType: The type of insight.
    ///   - shownWeeksAgo: How many weeks ago this insight was last shown (nil = never).
    /// - Returns: A factor from 0.0 to 1.0.
    static func noveltyFactor(insightType: StaticInsightType, shownWeeksAgo: Int?) -> Double {
        guard let weeksAgo = shownWeeksAgo else { return 1.0 }
        if weeksAgo <= 1 { return 0.0 }
        if weeksAgo <= 4 { return 0.3 }
        return 1.0
    }

    /// Selects top insights from candidates that meet the minimum score.
    static func selectTopInsights(candidates: [ScoredInsight], maxCount: Int, minimumScore: Double) -> [ScoredInsight] {
        candidates
            .filter { $0.score >= minimumScore }
            .sorted { $0.score > $1.score }
            .prefix(maxCount)
            .map { $0 }
    }
}
