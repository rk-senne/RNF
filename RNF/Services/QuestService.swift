import Foundation

struct DailyQuestPlan {

    let habits: [Habit]
    let dailyGoal: Int

}

struct WeeklyQuestPlan {

    let habit: Habit?

}

struct DynamicQuestPlan {

    let daily: DailyQuestPlan
    let weekly: WeeklyQuestPlan

}

final class QuestService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func generateDailyHabits(for profile: Profile) -> DailyQuestPlan {

        generateQuestPlan(for: profile).daily

    }

    func generateQuestPlan(for profile: Profile) -> DynamicQuestPlan {

        _ = supabase

        let dailyQuestDefinitions = QuestRepository.all.filter { quest in
            quest.cadence == .daily
        }

        let generated = QuestGenerator.generateDailyQuests(
            profile: profile,
            quests: dailyQuestDefinitions
        )

        let quests = [generated.main].compactMap { $0 } + generated.side
        let weeklyQuest = QuestGenerator.selectWeeklyHabitUnlock(
            profile: profile,
            quests: QuestRepository.all
        )
        let effectiveLevel = max(profile.level, XPSystem.levelState(for: profile.xp_total).level)

        return DynamicQuestPlan(
            daily: DailyQuestPlan(
                habits: QuestMapper.toHabits(quests),
                dailyGoal: QuestDifficultySystem.questsPerDay(for: effectiveLevel)
            ),
            weekly: WeeklyQuestPlan(
                habit: weeklyQuest.map { QuestMapper.toHabit($0) }
            )
        )

    }

    func updateQuestProgress(for profile: Profile) -> DailyQuestPlan {
        generateDailyHabits(for: profile)
    }

}
