import Foundation

final class AchievementService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchUnlocked(userId: UUID) async throws -> [String] {
        struct Row: Decodable { let achievement_id: String }
        let rows: [Row] = try await supabase.db
            .from("user_achievements")
            .select("achievement_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return rows.map(\.achievement_id)
    }

    func unlock(userId: UUID, achievementId: String) async throws {
        struct Insert: Encodable {
            let user_id: UUID
            let achievement_id: String
        }
        try await supabase.db
            .from("user_achievements")
            .insert(Insert(user_id: userId, achievement_id: achievementId))
            .execute()
    }

    func evaluate(profile: Profile, stats: UserStats) -> [Achievement] {
        let all = Achievement.all
        return all.filter { achievement in
            switch achievement.category {
            case .streak: return profile.streak >= achievement.requirement
            case .level: return profile.level >= achievement.requirement
            case .habits: return stats.totalHabitsCompleted >= achievement.requirement
            case .workouts: return stats.totalWorkouts >= achievement.requirement
            case .reading: return stats.totalReadings >= achievement.requirement
            case .boss: return stats.bossesDefeated >= achievement.requirement
            case .social: return false
            }
        }
    }

    struct UserStats {
        let totalHabitsCompleted: Int
        let totalWorkouts: Int
        let totalReadings: Int
        let bossesDefeated: Int
    }
}
