import Foundation
import Supabase
import PostgREST

final class SkillTreeService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchSkillNodes() async throws -> [SkillTreeNode] {

        try await supabase.db
            .from("skill_nodes")
            .select()
            .execute()
            .value
    }

    func fetchUserUnlocks(userId: UUID) async throws -> [UserSkillUnlock] {

        try await supabase.db
            .from("user_skills")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    func unlockNode(
        userId: UUID,
        nodeId: UUID,
        unlockedAt: Date = Date()
    ) async throws -> UserSkillUnlock {

        let unlock = UserSkillUnlock(
            id: UUID(),
            user_id: userId,
            skill_node_id: nodeId,
            unlocked_at: unlockedAt
        )

        return try await supabase.db
            .from("user_skills")
            .insert(unlock)
            .select()
            .single()
            .execute()
            .value
    }

    func unlockState(for profile: Profile) async throws -> SkillTreeUnlockState {

        guard !profile.isPlaceholder else {
            return SkillTreeSystem.unlockState(
                profile: profile,
                unlockedSkills: []
            )
        }

        let unlockedSkills = try await fetchUserUnlocks(userId: profile.id)

        return SkillTreeSystem.unlockState(
            profile: profile,
            unlockedSkills: unlockedSkills
        )
    }

    func activePerks(for profile: Profile) async throws -> ActivePerkSummary {

        guard !profile.isPlaceholder else {
            return .empty
        }

        // Chaos #10: Check subscription status — perks require active subscription
        let isSubscribed = await hasActiveSubscription(userId: profile.id)
        guard isSubscribed else {
            return .empty
        }

        async let skillNodes = fetchSkillNodes()
        async let unlockedSkills = fetchUserUnlocks(userId: profile.id)

        return try await PerkSystem.activePerks(
            skillNodes: skillNodes,
            unlockedSkills: unlockedSkills
        )
    }

    private func hasActiveSubscription(userId: UUID) async -> Bool {
        struct SubRow: Decodable { let status: String }
        do {
            let rows: [SubRow] = try await supabase.db
                .from("subscriptions")
                .select("status")
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: "active")
                .limit(1)
                .execute()
                .value
            return !rows.isEmpty
        } catch {
            // If we can't verify, deny perks (fail-safe)
            return false
        }
    }

}
