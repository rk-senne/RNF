import Foundation

final class BossService {

    private let supabase: SupabaseService
    private let authProvider: AuthProviding

    init(supabase: SupabaseService = .shared, authProvider: AuthProviding? = nil) {
        self.supabase = supabase
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
    }

    func activeBoss(userId: UUID) async throws -> Boss? {
        let bosses: [Boss] = try await supabase.db
            .from("bosses")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: Boss.Status.active.rawValue)
            .limit(1)
            .execute()
            .value
        return bosses.first
    }

    func spawnBoss(userId: UUID, type: Boss.BossType, level: Int) async throws -> Boss {
        var boss = Boss.create(type: type, level: level)
        boss.user_id = userId
        let created: Boss = try await supabase.db
            .from("bosses")
            .insert(boss)
            .select()
            .single()
            .execute()
            .value
        return created
    }

    func dealDamage(bossId: UUID, damage: Int) async throws -> Boss {
        // HIGH-3: Clamp damage to prevent client-side abuse
        let clampedDamage = max(0, min(damage, 50))

        let boss: Boss = try await supabase.db
            .from("bosses")
            .select()
            .eq("id", value: bossId.uuidString)
            .single()
            .execute()
            .value

        // Chaos #4: Guard against dealing damage to already-defeated boss
        guard boss.status == .active else {
            return boss
        }

        let newHP = max(boss.currentHP - clampedDamage, 0)
        let newStatus: Boss.Status = newHP <= 0 ? .defeated : .active

        struct BossUpdate: Encodable {
            let current_hp: Int
            let status: Boss.Status
            let defeated_at: Date?
        }

        // Only update if boss is still active (prevents double-defeat XP)
        let updated: Boss = try await supabase.db
            .from("bosses")
            .update(BossUpdate(current_hp: newHP, status: newStatus, defeated_at: newHP <= 0 ? Date() : nil))
            .eq("id", value: bossId.uuidString)
            .eq("status", value: Boss.Status.active.rawValue)
            .select()
            .single()
            .execute()
            .value
        return updated
    }
}
