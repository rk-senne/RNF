import Foundation

struct DailyQuestPlan {

    let habits: [Habit]
    let dailyGoal: Int

}

final class QuestService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func generateDailyHabits(for profile: Profile) -> DailyQuestPlan {

        _ = supabase

        let generated = QuestGenerator.generateDailyQuests(
            profile: profile,
            quests: QuestRepository.all
        )

        let quests = [generated.main].compactMap { $0 } + generated.side
        let effectiveLevel = max(profile.level, XPSystem.levelState(for: profile.xp_total).level)

        return DailyQuestPlan(
            habits: QuestMapper.toHabits(quests),
            dailyGoal: QuestDifficultySystem.questsPerDay(for: effectiveLevel)
        )

    }

    func updateQuestProgress(for profile: Profile) -> DailyQuestPlan {
        generateDailyHabits(for: profile)
    }

}
