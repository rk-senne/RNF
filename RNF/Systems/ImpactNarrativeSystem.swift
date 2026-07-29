import Foundation

/// Pure system mapping milestones to real-world impact narratives.
/// Connects in-app progress to meaningful real-world claims.
/// No dependencies — pure data transformation.
struct ImpactNarrativeSystem {

    // MARK: - Types

    enum Milestone: Equatable {
        case streakDays(Int)
        case habitsCompleted(Int)
        case workoutsCompleted(Int)
        case readingSessionsCompleted(Int)
        case levelReached(Int)

        var id: String {
            switch self {
            case .streakDays(let n): return "streak_\(n)"
            case .habitsCompleted(let n): return "habits_\(n)"
            case .workoutsCompleted(let n): return "workouts_\(n)"
            case .readingSessionsCompleted(let n): return "reading_\(n)"
            case .levelReached(let n): return "level_\(n)"
            }
        }
    }

    struct ImpactMessage {
        let headline: String
        let detail: String
        let shareText: String
    }

    // MARK: - Narrative Generation

    /// Returns an impact message for the given milestone, or nil if no narrative applies.
    static func message(for milestone: Milestone) -> ImpactMessage? {
        switch milestone {
        case .streakDays(let days):
            return streakMessage(days: days)
        case .habitsCompleted(let count):
            return habitsMessage(count: count)
        case .workoutsCompleted(let count):
            return workoutsMessage(count: count)
        case .readingSessionsCompleted(let count):
            return readingMessage(count: count)
        case .levelReached(let level):
            return levelMessage(level: level)
        }
    }

    // MARK: - Streak Narratives

    private static func streakMessage(days: Int) -> ImpactMessage? {
        switch days {
        case 7:
            return ImpactMessage(
                headline: "7 days of discipline",
                detail: "That's a full week of choosing growth over comfort. Most people don't make it past 3.",
                shareText: "I've maintained discipline for 7 straight days 🔥"
            )
        case 14:
            return ImpactMessage(
                headline: "2 weeks of consistency",
                detail: "Research shows it takes 14-21 days to form neural pathways for new habits.",
                shareText: "14 days of consistent action. The habit is forming. ⚡"
            )
        case 30:
            return ImpactMessage(
                headline: "30 days forged",
                detail: "You've invested roughly 30 hours in deliberate self-development this month.",
                shareText: "30 days of discipline. One month of choosing who I want to become. 💎"
            )
        case 60:
            return ImpactMessage(
                headline: "60 days — identity shift",
                detail: "At this point, discipline isn't something you do. It's who you are.",
                shareText: "60 days. This isn't motivation anymore — it's identity. 🗡️"
            )
        case 90:
            return ImpactMessage(
                headline: "90 days — transformation complete",
                detail: "You've invested approximately 90 hours in structured growth. You are not the same person who started.",
                shareText: "90 days of discipline. I finished what I started. 👑"
            )
        default:
            return nil
        }
    }

    // MARK: - Habits Narratives

    private static func habitsMessage(count: Int) -> ImpactMessage? {
        switch count {
        case 50:
            return ImpactMessage(
                headline: "50 habits completed",
                detail: "50 times you chose discipline over inertia. That compounds.",
                shareText: "50 deliberate actions toward the person I'm becoming."
            )
        case 100:
            return ImpactMessage(
                headline: "Century of discipline",
                detail: "100 completed habits. Each one was a vote for your future self.",
                shareText: "100 habits completed. One hundred votes for who I want to be. 🔥"
            )
        case 365:
            return ImpactMessage(
                headline: "365 acts of discipline",
                detail: "You chose growth 365 times. That's more intentional action than most people take in a decade.",
                shareText: "365 habits completed. A year's worth of deliberate growth. 👑"
            )
        case 500:
            return ImpactMessage(
                headline: "500 — relentless",
                detail: "Five hundred completed habits. The compound effect is undeniable now.",
                shareText: "500 habits. Relentless. 💎"
            )
        case 1000:
            return ImpactMessage(
                headline: "1,000 acts of will",
                detail: "One thousand times you showed up. This is what mastery looks like.",
                shareText: "1,000 habits completed. This is who I am now."
            )
        default:
            return nil
        }
    }

    // MARK: - Workout Narratives

    private static func workoutsMessage(count: Int) -> ImpactMessage? {
        switch count {
        case 10:
            return ImpactMessage(
                headline: "10 workouts logged",
                detail: "Your body is adapting. The hardest part — starting — is behind you.",
                shareText: "10 workouts in. The momentum is building. 💪"
            )
        case 30:
            return ImpactMessage(
                headline: "30 workouts",
                detail: "Roughly 15 hours of movement dedicated to your physical strength.",
                shareText: "30 workouts. I'm investing in my body. 🏋️"
            )
        case 100:
            return ImpactMessage(
                headline: "100 workouts",
                detail: "Over 50 hours of deliberate physical training. Your body thanks you.",
                shareText: "100 workouts completed. The discipline is physical now. ⚡"
            )
        default:
            return nil
        }
    }

    // MARK: - Reading Narratives

    private static func readingMessage(count: Int) -> ImpactMessage? {
        switch count {
        case 10:
            return ImpactMessage(
                headline: "10 reading sessions",
                detail: "That's roughly 2-3 chapters of focused learning. Knowledge compounds.",
                shareText: "10 reading sessions. Feeding the mind. 📖"
            )
        case 30:
            return ImpactMessage(
                headline: "30 reading sessions",
                detail: "At this pace, you'll read 12+ books this year. Most adults read fewer than 4.",
                shareText: "30 reading sessions. Outpacing 90% of adults. 📚"
            )
        default:
            return nil
        }
    }

    // MARK: - Level Narratives

    private static func levelMessage(level: Int) -> ImpactMessage? {
        switch level {
        case 5:
            return ImpactMessage(
                headline: "Level 5 — Awakened",
                detail: "You've proven this isn't a phase. The foundation is set.",
                shareText: "Level 5. The foundation is solid. 🌱"
            )
        case 10:
            return ImpactMessage(
                headline: "Level 10 — Ascendant",
                detail: "Double digits. Your character is taking shape through real action.",
                shareText: "Level 10. Real progress, built through real action. ⚡"
            )
        case 20:
            return ImpactMessage(
                headline: "Level 20 — Apex",
                detail: "Few make it this far. Your discipline is exceptional.",
                shareText: "Level 20. Apex reached. Most never get here. 💎"
            )
        default:
            return nil
        }
    }

    // MARK: - Bulk Check

    /// Given current stats, returns all milestones that have impact messages.
    /// Useful for checking which milestones were just crossed.
    static func checkMilestones(
        streakDays: Int,
        totalHabits: Int,
        totalWorkouts: Int,
        totalReading: Int,
        level: Int
    ) -> [Milestone] {
        var triggered: [Milestone] = []

        let streakMilestones = [7, 14, 30, 60, 90]
        if streakMilestones.contains(streakDays) {
            triggered.append(.streakDays(streakDays))
        }

        let habitMilestones = [50, 100, 365, 500, 1000]
        if habitMilestones.contains(totalHabits) {
            triggered.append(.habitsCompleted(totalHabits))
        }

        let workoutMilestones = [10, 30, 100]
        if workoutMilestones.contains(totalWorkouts) {
            triggered.append(.workoutsCompleted(totalWorkouts))
        }

        let readingMilestones = [10, 30]
        if readingMilestones.contains(totalReading) {
            triggered.append(.readingSessionsCompleted(totalReading))
        }

        let levelMilestones = [5, 10, 20]
        if levelMilestones.contains(level) {
            triggered.append(.levelReached(level))
        }

        return triggered
    }
}
