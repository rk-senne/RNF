import Foundation
import os

// MARK: - P25-INT-02/03/04/05: Adaptive Timing Service

/// Computes optimal completion times from historical data.
/// Supports weekday/weekend split and drift detection.
@MainActor
final class AdaptiveTimingService {

    // MARK: - Types

    struct TimingProfile: Codable, Equatable {
        let weekdayMedian: TimeInterval  // seconds from midnight
        let weekendMedian: TimeInterval  // seconds from midnight
        let sampleCount: Int
        let computedAt: Date
    }

    struct DriftResult: Equatable {
        let hasDrifted: Bool
        let shiftMinutes: Double  // positive = later, negative = earlier
        let recentMedian: TimeInterval
        let baselineMedian: TimeInterval
    }

    // MARK: - Constants

    private static let minimumDaysRequired = 14
    private static let driftWindowDays = 7
    private static let driftThresholdMinutes: Double = 30.0

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private static let logger = Logger(subsystem: "com.rnf.app", category: "adaptive_timing")

    // MARK: - Cache

    private static let cacheKey = "rnf_adaptive_timing_profile"

    // MARK: - Init

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    // MARK: - Public API

    /// Computes the timing profile from completion timestamps.
    /// Requires at least 14 days of data to produce meaningful results.
    func computeTimingProfile(timestamps: [Date]) -> TimingProfile? {
        let calendar = Calendar.current

        // Group by date to count distinct days
        let daySet = Set(timestamps.map { calendar.startOfDay(for: $0) })
        guard daySet.count >= Self.minimumDaysRequired else {
            Self.logger.info("Insufficient data: \(daySet.count) days (need \(Self.minimumDaysRequired))")
            return nil
        }

        let weekdayTimes = timestamps
            .filter { !calendar.isDateInWeekend($0) }
            .map { secondsSinceMidnight($0) }

        let weekendTimes = timestamps
            .filter { calendar.isDateInWeekend($0) }
            .map { secondsSinceMidnight($0) }

        let weekdayMedian = median(weekdayTimes) ?? median(timestamps.map { secondsSinceMidnight($0) }) ?? 0
        let weekendMedian = median(weekendTimes) ?? median(timestamps.map { secondsSinceMidnight($0) }) ?? 0

        let profile = TimingProfile(
            weekdayMedian: weekdayMedian,
            weekendMedian: weekendMedian,
            sampleCount: timestamps.count,
            computedAt: Date()
        )

        cacheProfile(profile)
        return profile
    }

    /// Returns the recommended completion time for today based on cached profile.
    func recommendedTimeForToday() -> TimeInterval? {
        guard let profile = cachedProfile() else { return nil }

        let calendar = Calendar.current
        let isWeekend = calendar.isDateInWeekend(Date())

        return isWeekend ? profile.weekendMedian : profile.weekdayMedian
    }

    /// Detects drift: whether the user's recent completion time has shifted
    /// 30+ minutes from the baseline over the past 7 days.
    func detectDrift(timestamps: [Date]) -> DriftResult {
        let calendar = Calendar.current
        let now = Date()

        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -Self.driftWindowDays, to: now) else {
            return DriftResult(hasDrifted: false, shiftMinutes: 0, recentMedian: 0, baselineMedian: 0)
        }

        let recentTimestamps = timestamps.filter { $0 >= sevenDaysAgo }
        let olderTimestamps = timestamps.filter { $0 < sevenDaysAgo }

        guard recentTimestamps.count >= 3, olderTimestamps.count >= Self.minimumDaysRequired else {
            return DriftResult(hasDrifted: false, shiftMinutes: 0, recentMedian: 0, baselineMedian: 0)
        }

        let recentTimes = recentTimestamps.map { secondsSinceMidnight($0) }
        let olderTimes = olderTimestamps.map { secondsSinceMidnight($0) }

        guard let recentMedian = median(recentTimes),
              let baselineMedian = median(olderTimes) else {
            return DriftResult(hasDrifted: false, shiftMinutes: 0, recentMedian: 0, baselineMedian: 0)
        }

        let shiftMinutes = (recentMedian - baselineMedian) / 60.0
        let hasDrifted = abs(shiftMinutes) >= Self.driftThresholdMinutes

        if hasDrifted {
            Self.logger.info("Timing drift detected: \(String(format: "%.1f", shiftMinutes)) minutes shift")
        }

        return DriftResult(
            hasDrifted: hasDrifted,
            shiftMinutes: shiftMinutes,
            recentMedian: recentMedian,
            baselineMedian: baselineMedian
        )
    }

    /// Re-adapts the profile when drift is detected. Returns the updated profile.
    func reAdaptIfNeeded(timestamps: [Date]) -> TimingProfile? {
        let drift = detectDrift(timestamps: timestamps)

        guard drift.hasDrifted else { return cachedProfile() }

        Self.logger.info("Re-adapting timing profile due to drift")
        return computeTimingProfile(timestamps: timestamps)
    }

    /// Formats a time-of-day interval as a human-readable string (e.g., "7:30 AM").
    func formatTimeOfDay(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let period = hours >= 12 ? "PM" : "AM"
        let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        return String(format: "%d:%02d %@", displayHour, minutes, period)
    }

    // MARK: - Caching

    func cachedProfile() -> TimingProfile? {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return nil }
        return try? JSONDecoder().decode(TimingProfile.self, from: data)
    }

    private func cacheProfile(_ profile: TimingProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }

    // MARK: - Private Helpers

    private func secondsSinceMidnight(_ date: Date) -> TimeInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return date.timeIntervalSince(startOfDay)
    }

    private func median(_ values: [TimeInterval]) -> TimeInterval? {
        Self.computeMedian(values)
    }

    // MARK: - Static Testable APIs

    /// Computes the median of an array of time values (in minutes since midnight).
    /// Returns nil for empty arrays.
    static func computeMedian(_ values: [TimeInterval]) -> TimeInterval? {
        guard !values.isEmpty else { return nil }

        let sorted = values.sorted()
        let count = sorted.count

        if count.isMultiple(of: 2) {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
        } else {
            return sorted[count / 2]
        }
    }

    /// Detects whether the shift between two medians exceeds the threshold.
    /// Uses absolute value comparison — drift in either direction counts.
    static func isDriftDetected(previousMedian: TimeInterval, currentMedian: TimeInterval, thresholdMinutes: Double) -> Bool {
        let shiftMinutes = abs(currentMedian - previousMedian)
        return shiftMinutes > thresholdMinutes
    }

    /// Computes the adaptive notification time: median - 5 minutes.
    static func notificationTime(forMedian median: TimeInterval) -> TimeInterval {
        median - 5.0
    }

    /// Filters out timestamps between 00:00 and 04:00 (outlier catch-ups).
    /// Values are in minutes since midnight.
    static func filterOutliers(_ timestamps: [TimeInterval]) -> [TimeInterval] {
        timestamps.filter { $0 >= 240.0 } // 4 * 60 = 240 minutes = 04:00
    }

    /// Checks if the data meets the minimum sample threshold.
    static func meetsMinimumThreshold(_ timestamps: [TimeInterval], minimum: Int) -> Bool {
        timestamps.count >= minimum
    }
}
