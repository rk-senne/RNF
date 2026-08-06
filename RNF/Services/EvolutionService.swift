import Foundation

final class EvolutionService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func evolutionState(for profile: Profile) -> EvolutionState {
        let state = EvolutionSystem.state(for: profile)
        persistLastKnownRank(state.currentTier.rank, userId: profile.id)
        return state
    }

    private func persistLastKnownRank(_ rank: EvolutionRank, userId: UUID) {
        UserDefaults.standard.set(rank.rawValue, forKey: "rnf_evolution_rank_\(userId.uuidString)")
    }

    func lastKnownRank(userId: UUID) -> EvolutionRank? {
        guard let raw = UserDefaults.standard.string(forKey: "rnf_evolution_rank_\(userId.uuidString)") else {
            return nil
        }
        return EvolutionRank(rawValue: raw)
    }

    func currentTier(for profile: Profile) -> EvolutionTier {
        evolutionState(for: profile).currentTier
    }

    func newlyReachedTier(
        previousRank: EvolutionRank,
        profile: Profile
    ) -> EvolutionTier? {

        EvolutionSystem.newlyReachedTier(
            previousRank: previousRank,
            profile: profile
        )
    }

}
