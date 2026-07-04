import Foundation

// P24-GRO-14: Content moderation service
// Client-side profanity filter + server-side report submission

@MainActor
final class ContentModerationService: ObservableObject {

    // MARK: - Types

    enum ReportReason: String, Codable, CaseIterable {
        case harassment = "Harassment"
        case spam = "Spam"
        case inappropriate = "Inappropriate Content"
        case impersonation = "Impersonation"
        case other = "Other"
    }

    struct Report: Codable, Identifiable {
        let id: UUID
        let reporter_id: UUID
        let reported_user_id: UUID
        let reason: ReportReason
        let details: String?
        let content_reference: String?
        let created_at: Date

        init(reporterID: UUID, reportedUserID: UUID, reason: ReportReason, details: String?, contentReference: String?) {
            self.id = UUID()
            self.reporter_id = reporterID
            self.reported_user_id = reportedUserID
            self.reason = reason
            self.details = details
            self.content_reference = contentReference
            self.created_at = Date()
        }
    }

    enum ModerationResult {
        case clean
        case filtered(String)
        case blocked
    }

    // MARK: - Published State

    @Published private(set) var blockedUsers: Set<UUID> = []

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private let userDefaults: UserDefaults

    // MARK: - Keys

    private static let blockedKey = "rnf_blocked_users"

    // MARK: - Profanity Word List

    private static let profanityList: Set<String> = [
        "ass", "asshole", "bastard", "bitch", "bullshit",
        "crap", "cunt", "damn", "dick", "douchebag",
        "fag", "fuck", "fucking", "goddamn", "hell",
        "idiot", "jerk", "moron", "nigger", "piss",
        "prick", "pussy", "retard", "shit", "slut",
        "stfu", "twat", "whore", "wanker", "wtf"
    ]

    // MARK: - Init

    init(supabase: SupabaseService = .shared, userDefaults: UserDefaults = .standard) {
        self.supabase = supabase
        self.userDefaults = userDefaults
        loadBlockedUsers()
    }

    // MARK: - Profanity Filter

    /// Check text for profanity. Returns filtered version if needed.
    func moderate(text: String) -> ModerationResult {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        let foundProfanity = words.filter { Self.profanityList.contains($0) }

        guard !foundProfanity.isEmpty else { return .clean }

        // Replace profanity with asterisks
        var filtered = text
        for word in foundProfanity {
            let replacement = String(repeating: "*", count: word.count)
            filtered = filtered.replacingOccurrences(
                of: word,
                with: replacement,
                options: [.caseInsensitive]
            )
        }

        return .filtered(filtered)
    }

    /// Quick check if text contains profanity
    func containsProfanity(_ text: String) -> Bool {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return words.contains(where: { Self.profanityList.contains($0) })
    }

    // MARK: - Report Submission

    /// Submit a report against a user
    func submitReport(
        reporterID: UUID,
        reportedUserID: UUID,
        reason: ReportReason,
        details: String? = nil,
        contentReference: String? = nil
    ) async -> RNFServiceWriteResult<Report> {
        let report = Report(
            reporterID: reporterID,
            reportedUserID: reportedUserID,
            reason: reason,
            details: details,
            contentReference: contentReference
        )

        guard let client = supabase.client else {
            return .savedLocallyOnly(report, error: .networkUnavailable)
        }

        do {
            let created: Report = try await client
                .from("moderation_reports")
                .insert(report)
                .select()
                .single()
                .execute()
                .value
            return .savedRemotely(created)
        } catch {
            RNFLogger.auth.error("ContentModerationService: submitReport failed — \(error.localizedDescription)")
            return .savedLocallyOnly(report, error: .unknown)
        }
    }

    // MARK: - Block User

    /// Block a user locally (hides their content from feed)
    func blockUser(_ userID: UUID) {
        blockedUsers.insert(userID)
        saveBlockedUsers()

        // Sync to remote
        if let client = supabase.client {
            Task {
                do {
                    struct BlockRecord: Encodable {
                        let blocked_user_id: String
                        let created_at: String
                    }
                    let formatter = ISO8601DateFormatter()
                    try await client
                        .from("user_blocks")
                        .insert(BlockRecord(
                            blocked_user_id: userID.uuidString,
                            created_at: formatter.string(from: Date())
                        ))
                        .execute()
                } catch {
                    RNFLogger.auth.error("ContentModerationService: blockUser sync failed — \(error.localizedDescription)")
                }
            }
        }
    }

    /// Unblock a user
    func unblockUser(_ userID: UUID) {
        blockedUsers.remove(userID)
        saveBlockedUsers()

        if let client = supabase.client {
            Task {
                do {
                    try await client
                        .from("user_blocks")
                        .delete()
                        .eq("blocked_user_id", value: userID.uuidString)
                        .execute()
                } catch {
                    RNFLogger.auth.error("ContentModerationService: unblockUser sync failed — \(error.localizedDescription)")
                }
            }
        }
    }

    /// Check if a user is blocked
    func isBlocked(_ userID: UUID) -> Bool {
        blockedUsers.contains(userID)
    }

    // MARK: - Local Persistence

    private func loadBlockedUsers() {
        if let data = userDefaults.data(forKey: Self.blockedKey),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            blockedUsers = ids
        }
    }

    private func saveBlockedUsers() {
        if let data = try? JSONEncoder().encode(blockedUsers) {
            userDefaults.set(data, forKey: Self.blockedKey)
        }
    }
}
