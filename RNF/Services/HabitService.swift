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
            let habits: [Habit] = try await supabase.client
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
            try await supabase.client
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
            try await supabase.client
                .from("habits")
                .upsert(habit)
                .execute()
        } catch {
            // Fallback to local-only behavior until the backend contract is live.
        }

        return habit
    }

    func recordCompletion(_ completion: HabitCompletion) async {

        guard completion.user_id != nil else {
            return
        }

        do {
            try await supabase.client
                .from("habit_completions")
                .insert(completion)
                .execute()
        } catch {
            // Local state stays consistent even if the backend call fails.
        }

    }

}
