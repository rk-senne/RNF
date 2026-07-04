import Foundation
import os

/// Handles full account deletion with cascade across all user tables and storage cleanup.
@MainActor
final class AccountDeletionService: ObservableObject {

    private let logger = Logger(subsystem: "com.rnf.app", category: "AccountDeletion")

    enum DeletionError: Error, LocalizedError {
        case notAuthenticated
        case serviceUnavailable
        case gracePeriodActive(expiresAt: Date)
        case deletionFailed(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "User not authenticated"
            case .serviceUnavailable: return "Service unavailable"
            case .gracePeriodActive(let date): return "Deletion scheduled for \(date)"
            case .deletionFailed(let reason): return "Deletion failed: \(reason)"
            }
        }
    }

    private static let gracePeriodDays = 7
    private static let scheduledDeletionKey = "rnf_scheduled_deletion_date"

    /// Schedule account deletion with 7-day grace period.
    func scheduleDeletion(userId: UUID) async throws -> Date {
        guard SupabaseService.shared.isConfigured else {
            throw DeletionError.serviceUnavailable
        }

        let deletionDate = Calendar.current.date(byAdding: .day, value: Self.gracePeriodDays, to: Date())!
        UserDefaults.standard.set(deletionDate.timeIntervalSince1970, forKey: Self.scheduledDeletionKey)

        logger.info("Account deletion scheduled for \(deletionDate) (user: \(userId.uuidString.prefix(8)))")
        return deletionDate
    }

    /// Cancel a scheduled deletion within the grace period.
    func cancelDeletion() {
        UserDefaults.standard.removeObject(forKey: Self.scheduledDeletionKey)
        logger.info("Account deletion cancelled")
    }

    /// Check if there's an active scheduled deletion.
    var scheduledDeletionDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: Self.scheduledDeletionKey)
        guard timestamp > 0 else { return nil }
        let date = Date(timeIntervalSince1970: timestamp)
        return date > Date() ? date : nil
    }

    /// Execute the cascade delete via Supabase RPC.
    func executeDelete(userId: UUID) async throws {
        guard SupabaseService.shared.isConfigured,
              let client = SupabaseService.shared.client else {
            throw DeletionError.serviceUnavailable
        }

        // Check grace period has expired
        if let scheduled = scheduledDeletionDate, scheduled > Date() {
            throw DeletionError.gracePeriodActive(expiresAt: scheduled)
        }

        do {
            // Call server-side RPC for cascade delete
            try await client.rpc("delete_user_account", params: ["target_user_id": userId.uuidString]).execute()

            // Clear local data
            clearLocalData()

            logger.info("Account deletion executed for user: \(userId.uuidString.prefix(8))")
        } catch {
            logger.error("Account deletion failed: \(error.localizedDescription)")
            throw DeletionError.deletionFailed(error.localizedDescription)
        }
    }

    /// Clear all local caches and UserDefaults data.
    private func clearLocalData() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        UserDefaults.standard.removePersistentDomain(forName: domain)

        // Clear shared App Group data
        if let groupDefaults = UserDefaults(suiteName: "group.com.rnf.shared") {
            let groupDomain = "group.com.rnf.shared"
            groupDefaults.removePersistentDomain(forName: groupDomain)
        }
    }
}
