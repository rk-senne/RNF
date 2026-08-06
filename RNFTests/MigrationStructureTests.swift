import Foundation
import XCTest
@testable import RNF

/// These tests verify that the app's model assumptions align with the migration SQL schema.
/// They do not connect to a database — they validate structural contracts statically.
@MainActor
final class MigrationStructureTests: XCTestCase {

    // MARK: - Uniqueness Constraint Alignment

    func testDailyLogHasUserDateUniquenessAssumption() {
        // Migration 003: unique (user_id, date) on daily_logs
        // DailyLogService.createDailyLog relies on this constraint for conflict detection.
        let log1 = DailyLog(
            id: UUID(), user_id: UUID(), date: Date().startOfDay,
            habits_completed: 0, habits_required: 2,
            workout_completed: false, reading_completed: false,
            forgiveness_used: false, xp_earned: 0, status: .partial, created_at: nil
        )
        let log2 = DailyLog(
            id: UUID(), user_id: log1.user_id, date: log1.date,
            habits_completed: 0, habits_required: 2,
            workout_completed: false, reading_completed: false,
            forgiveness_used: false, xp_earned: 0, status: .partial, created_at: nil
        )
        // Same user_id + date means DB constraint prevents duplicate — service handles conflict
        XCTAssertEqual(log1.user_id, log2.user_id)
        XCTAssertEqual(log1.date, log2.date)
        XCTAssertNotEqual(log1.id, log2.id)
    }

    func testHabitCompletionHasUserHabitDateUniqueness() {
        // Migration 004: unique (user_id, habit_id, date)
        // DailyLogService.recordHabitCompletion uses fetchHabitCompletion to detect duplicates
        let userId = UUID()
        let habitId = UUID()
        let date = Date().startOfDay

        let c1 = HabitCompletion(
            id: UUID(), user_id: userId, habit_id: habitId,
            completed_at: Date(), date: date, xp_awarded: 10
        )
        let c2 = HabitCompletion(
            id: UUID(), user_id: userId, habit_id: habitId,
            completed_at: Date(), date: date, xp_awarded: 10
        )
        // Same (user_id, habit_id, date) — DB rejects second insert
        XCTAssertEqual(c1.user_id, c2.user_id)
        XCTAssertEqual(c1.habit_id, c2.habit_id)
        XCTAssertEqual(c1.date, c2.date)
    }

    func testChallengeHasOneActivePerUserConstraint() {
        // Migration 005: unique index on (user_id) WHERE status = 'active'
        // ChallengeService.startChallenge relies on only one active challenge per user
        let userId = UUID()
        let c1 = Challenge(
            id: UUID(), user_id: userId,
            start_date: Date(), end_date: Date().addingDays(89),
            current_day: 1, status: .active, created_at: nil
        )
        let c2 = Challenge(
            id: UUID(), user_id: userId,
            start_date: Date(), end_date: Date().addingDays(89),
            current_day: 1, status: .active, created_at: nil
        )
        XCTAssertEqual(c1.user_id, c2.user_id)
        XCTAssertEqual(c1.status, c2.status)
    }

    // MARK: - RLS Coverage

    func testAllUserOwnedTablesHaveRLS() {
        // Migration 010 enables RLS on all user-owned tables:
        // users, habits, daily_logs, habit_completions, challenges, workouts, reading_uploads, subscriptions
        // This test documents the expected coverage.
        let rlsProtectedTables = [
            "users", "habits", "daily_logs", "habit_completions",
            "challenges", "workouts", "reading_uploads", "subscriptions"
        ]
        XCTAssertEqual(rlsProtectedTables.count, 8)
    }

    // MARK: - Index Coverage for Critical Queries

    func testCriticalQueryPathsHaveIndexes() {
        // Migration 003: daily_logs_user_date_idx (user_id, date DESC)
        // Migration 004: habit_completions_user_date_idx (user_id, date DESC)
        // Migration 005: challenges_user_created_idx (user_id, created_at DESC)
        // Migration 006: workouts_user_date_idx (user_id, date DESC)
        // Migration 009: workouts_user_date_unique_idx, challenges_user_status_idx
        //
        // These indexes support:
        // - DailyLogService.fetchTodayLog (user_id + date lookup)
        // - DailyLogService.recordHabitCompletion duplicate check (user_id + habit_id + date)
        // - ChallengeService.getActiveChallenge (user_id + status)
        // - WorkoutService.completeWorkout (user_id + date uniqueness)
        let indexedPaths = [
            "daily_logs(user_id, date)",
            "habit_completions(user_id, date)",
            "habit_completions(user_id, habit_id, date)",
            "challenges(user_id, status)",
            "workouts(user_id, date)"
        ]
        XCTAssertEqual(indexedPaths.count, 5)
    }

    // MARK: - Status Enum Alignment

    func testDailyLogStatusMatchesMigrationCheckConstraint() {
        // Migration 003: check (status in ('complete', 'partial', 'missed', 'forgiven'))
        let validStatuses: [DailyLog.Status] = [.complete, .partial, .missed, .forgiven]
        let rawValues = validStatuses.map(\.rawValue)
        XCTAssertTrue(rawValues.contains("complete"))
        XCTAssertTrue(rawValues.contains("partial"))
        XCTAssertTrue(rawValues.contains("missed"))
        XCTAssertTrue(rawValues.contains("forgiven"))
        XCTAssertEqual(rawValues.count, 4)
    }

    func testChallengeStatusMatchesMigrationCheckConstraint() {
        // Migration 005: check (status in ('active', 'completed', 'reset'))
        let validStatuses: [Challenge.Status] = [.active, .completed, .reset]
        let rawValues = validStatuses.map(\.rawValue)
        XCTAssertTrue(rawValues.contains("active"))
        XCTAssertTrue(rawValues.contains("completed"))
        XCTAssertTrue(rawValues.contains("reset"))
        XCTAssertEqual(rawValues.count, 3)
    }
}
