import Foundation

final class MasteryPathService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchActivePath(userId: UUID) async throws -> MasteryPath? {
        let paths: [MasteryPath] = try await supabase.db
            .from("mastery_paths")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        return paths.first
    }

    func selectPath(userId: UUID, pathType: MasteryPath.PathType) async throws -> MasteryPath {
        let path = MasteryPath(
            id: UUID(), user_id: userId, pathType: pathType,
            tier: 1, xpInPath: 0, started_at: nil
        )
        let created: MasteryPath = try await supabase.db
            .from("mastery_paths")
            .insert(path)
            .select()
            .single()
            .execute()
            .value
        return created
    }

    func addXP(pathId: UUID, xp: Int) async throws -> MasteryPath {
        let current: MasteryPath = try await supabase.db
            .from("mastery_paths")
            .select()
            .eq("id", value: pathId.uuidString)
            .single()
            .execute()
            .value

        let newXP = current.xpInPath + xp
        let newTier = MasteryPathService.tierForXP(newXP)

        struct Update: Encodable {
            let xp_in_path: Int
            let tier: Int
        }

        let updated: MasteryPath = try await supabase.db
            .from("mastery_paths")
            .update(Update(xp_in_path: newXP, tier: newTier))
            .eq("id", value: pathId.uuidString)
            .select()
            .single()
            .execute()
            .value
        return updated
    }

    static func tierForXP(_ xp: Int) -> Int {
        let thresholds = MasteryPath.tierThresholds
        for i in stride(from: thresholds.count - 1, through: 0, by: -1) {
            if xp >= thresholds[i] { return min(i + 1, 3) }
        }
        return 1
    }
}
