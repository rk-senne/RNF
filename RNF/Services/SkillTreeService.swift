import Foundation
import Supabase
import PostgREST

final class SkillTreeService {

    private let supabase: SupabaseService
    private let authProvider: AuthProviding

    init(
        supabase: SupabaseService = .shared,
        authProvider: AuthProviding? = nil
    ) {
        self.supabase = supabase
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
    }

    func fetchSkillNodes() async throws -> [SkillTreeNode] {

        try await supabase.client
            .from("skill_nodes")
            .select()
            .execute()
            .value
    }

    func fetchUserUnlocks(userId: UUID) async throws -> [UserSkillUnlock] {

        try await supabase.client
            .from("user_skills")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    func fetchUserUnlocks() async throws -> [UserSkillUnlock] {
        let userId = try await authProvider.requireCurrentUserID()
        return try await fetchUserUnlocks(userId: userId)
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

        return try await supabase.client
            .from("user_skills")
            .insert(unlock)
            .select()
            .single()
            .execute()
            .value
    }

    func unlockNode(
        nodeId: UUID,
        unlockedAt: Date = Date()
    ) async throws -> UserSkillUnlock {
        let userId = try await authProvider.requireCurrentUserID()
        return try await unlockNode(
            userId: userId,
            nodeId: nodeId,
            unlockedAt: unlockedAt
        )
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

    func authenticatedUnlockState(for profile: Profile) async throws -> SkillTreeUnlockState {

        guard !profile.isPlaceholder else {
            return SkillTreeSystem.unlockState(
                profile: profile,
                unlockedSkills: []
            )
        }

        _ = try await authProvider.requireCurrentUserID(matching: profile.id)
        return try await unlockState(for: profile)
    }

    func activePerks(for profile: Profile) async throws -> ActivePerkSummary {

        guard !profile.isPlaceholder else {
            return .empty
        }

        async let skillNodes = fetchSkillNodes()
        async let unlockedSkills = fetchUserUnlocks(userId: profile.id)

        return try await PerkSystem.activePerks(
            skillNodes: skillNodes,
            unlockedSkills: unlockedSkills
        )
    }

    func authenticatedActivePerks(for profile: Profile) async throws -> ActivePerkSummary {

        guard !profile.isPlaceholder else {
            return .empty
        }

        _ = try await authProvider.requireCurrentUserID(matching: profile.id)
        return try await activePerks(for: profile)
    }

}
