import Foundation

final class EvolutionService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func evolutionState(for profile: Profile) -> EvolutionState {

        _ = supabase

        return EvolutionSystem.state(for: profile)
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
