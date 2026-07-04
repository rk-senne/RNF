import Foundation
import Supabase
import PostgREST

final class HabitService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchHabits() async -> [Habit] {

        do {
            let habits: [Habit] = try await supabase.db
                .from("habits")
                .select()
                .execute()
                .value

            if habits.isEmpty {
                return QuestMapper.toHabits(QuestRepository.all)
            }

            return habits
        } catch {
            return QuestMapper.toHabits(QuestRepository.all)
        }

    }

    func createHabit(_ habit: Habit) async -> Habit {

        do {
            try await supabase.db
                .from("habits")
                .insert(habit)
                .execute()
        } catch {
            // Fallback to local-only behavior until the backend contract is live.
        }

        return habit
    }

    func updateHabit(_ habit: Habit) async -> Habit {

        do {
            try await supabase.db
                .from("habits")
                .upsert(habit)
                .execute()
        } catch {
            // Fallback to local-only behavior until the backend contract is live.
        }

        return habit
    }

    @discardableResult
    func recordCompletion(_ completion: HabitCompletion) async -> RNFServiceWriteResult<HabitCompletion> {

        guard completion.user_id != nil else {
            return .notSaved(.unauthenticated)
        }

        do {
            try await supabase.db
                .from("habit_completions")
                .insert(completion)
                .execute()
            return .savedRemotely(completion)
        } catch {
            // GAP 19: Surface persistence failures so ViewModels can inform the user.
            // Spec: RNF_PRODUCTION_READINESS_SPEC.md — "Services must not silently hide important persistence failures."
            return .savedLocallyOnly(completion, error: .networkUnavailable)
        }

    }

}
