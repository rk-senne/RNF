import Foundation

// P24-GRO-17: Notification content rotation system
// 20+ message variants per notification type to prevent fatigue

struct NotificationContentRotator {

    // MARK: - Types

    enum NotificationType: String, CaseIterable {
        case morning
        case evening
        case streakAtRisk
        case comeback
    }

    struct NotificationContent {
        let title: String
        let body: String
    }

    // MARK: - Selection Logic

    /// Get a deterministic-yet-varied notification for today.
    /// Uses day-of-year to rotate through variants without repetition.
    static func content(
        for type: NotificationType,
        userName: String? = nil,
        streak: Int = 0,
        dayOfYear: Int? = nil
    ) -> NotificationContent {
        let variants = messages(for: type)
        let day = dayOfYear ?? (Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1)
        let index = day % variants.count
        var content = variants[index]

        // Personalize if name available
        if let name = userName {
            content = NotificationContent(
                title: content.title.replacingOccurrences(of: "{name}", with: name),
                body: content.body.replacingOccurrences(of: "{name}", with: name)
            )
        } else {
            content = NotificationContent(
                title: content.title.replacingOccurrences(of: "{name}", with: "warrior"),
                body: content.body.replacingOccurrences(of: "{name}", with: "warrior")
            )
        }

        // Inject streak count
        let streakStr = "\(streak)"
        content = NotificationContent(
            title: content.title.replacingOccurrences(of: "{streak}", with: streakStr),
            body: content.body.replacingOccurrences(of: "{streak}", with: streakStr)
        )

        return content
    }

    /// Get a random variant (for testing or non-deterministic use)
    static func randomContent(for type: NotificationType) -> NotificationContent {
        let variants = messages(for: type)
        return variants.randomElement() ?? variants[0]
    }

    // MARK: - Message Variants

    static func messages(for type: NotificationType) -> [NotificationContent] {
        switch type {
        case .morning: return morningMessages
        case .evening: return eveningMessages
        case .streakAtRisk: return streakAtRiskMessages
        case .comeback: return comebackMessages
        }
    }

    // MARK: - Morning Messages (22 variants)

    private static let morningMessages: [NotificationContent] = [
        .init(title: "The Forge awaits", body: "Your disciplines are ready. Start strong today."),
        .init(title: "Rise, {name}", body: "Another day to prove what you're made of."),
        .init(title: "Morning check-in", body: "Your streak is at {streak} days. Keep it alive."),
        .init(title: "New day. New fire.", body: "The Forge burns brightest in the morning."),
        .init(title: "Good morning", body: "Yesterday's effort built today's foundation."),
        .init(title: "Dawn breaks", body: "Your habits await. One completion at a time."),
        .init(title: "The grind begins", body: "No shortcuts. Just you and the work."),
        .init(title: "Time to move", body: "Your body and mind are ready. Feed the fire."),
        .init(title: "Another sunrise", body: "{streak} days of discipline. Don't stop now."),
        .init(title: "Wake up, {name}", body: "The forge doesn't heat itself."),
        .init(title: "A new page", body: "Write today's chapter with action, not intention."),
        .init(title: "First light", body: "Start before you feel ready. That's the edge."),
        .init(title: "Your mission awaits", body: "Today's disciplines are loaded. Execute."),
        .init(title: "Steel sharpens steel", body: "Open the app. Complete one habit. Momentum follows."),
        .init(title: "No excuses today", body: "The only workout you regret is the one you skip."),
        .init(title: "Consistency > intensity", body: "Show up. That's 90% of the battle."),
        .init(title: "Builder mode: ON", body: "Your future self is counting on today."),
        .init(title: "Small actions compound", body: "One habit now. Two later. The rest follows."),
        .init(title: "The fire remembers", body: "Your streak knows you'll show up. Prove it right."),
        .init(title: "Discipline is freedom", body: "Do the hard things first. Ease follows."),
        .init(title: "Forge your day", body: "What you do in the first hour shapes the rest."),
        .init(title: "Ready?", body: "Your disciplines don't complete themselves. Let's go.")
    ]

    // MARK: - Evening Messages (22 variants)

    private static let eveningMessages: [NotificationContent] = [
        .init(title: "Day's end check", body: "Did you finish what you started? Close the loops."),
        .init(title: "Almost midnight", body: "Your streak resets at dawn. Complete now or lose it."),
        .init(title: "Final push", body: "A few minutes is all it takes to stay on track."),
        .init(title: "Don't sleep on it", body: "One unchecked habit can break a {streak}-day streak."),
        .init(title: "Evening report", body: "The forge cools. Did you give it enough fuel today?"),
        .init(title: "Closing time", body: "Lock in today's progress before rest takes over."),
        .init(title: "Last call, {name}", body: "Your habits are waiting. Finish what matters."),
        .init(title: "The day isn't done", body: "You have time. Use it before the reset."),
        .init(title: "Reflection hour", body: "How many disciplines did you complete? Close the gaps."),
        .init(title: "Night falls", body: "Tomorrow's momentum starts with tonight's completion."),
        .init(title: "Before you rest", body: "One more habit. That's all. You've got this."),
        .init(title: "End strong", body: "The best finish the day as strong as they start it."),
        .init(title: "Don't break the chain", body: "{streak} days. Don't let tonight be the break."),
        .init(title: "Wind down right", body: "Complete your evening rituals. Sleep will come easier."),
        .init(title: "Time check", body: "Hours left, not days. Finish your disciplines now."),
        .init(title: "The forge asks", body: "Did you earn tomorrow's streak? Check your progress."),
        .init(title: "Almost there", body: "A 5-minute effort keeps a {streak}-day streak alive."),
        .init(title: "Night shift", body: "Late completions still count. Don't give up on today."),
        .init(title: "Wrap it up", body: "Your future self wakes up proud — if you finish now."),
        .init(title: "Sunset discipline", body: "The day ends how you choose. Choose completion."),
        .init(title: "One more rep", body: "Your streak doesn't care what time it is. Just do it."),
        .init(title: "Lights out soon", body: "Tick off what's left. Then rest with pride.")
    ]

    // MARK: - Streak At Risk Messages (22 variants)

    private static let streakAtRiskMessages: [NotificationContent] = [
        .init(title: "⚠️ Streak at risk", body: "Your {streak}-day streak ends tonight if you don't act."),
        .init(title: "Don't let it die", body: "{streak} days of work. Gone in one night of neglect."),
        .init(title: "URGENT: Streak warning", body: "You haven't completed any habits today. Time is running out."),
        .init(title: "The fire is fading", body: "Your streak ember is cooling. Feed it before midnight."),
        .init(title: "🔥 → 💨", body: "{streak} days strong… unless you skip today."),
        .init(title: "Red alert, {name}", body: "Zero completions today. Your streak won't survive the night."),
        .init(title: "This is the moment", body: "Heroes are made in the moments they almost quit."),
        .init(title: "3 minutes", body: "That's all it takes to save a {streak}-day streak."),
        .init(title: "You'll regret this", body: "Tomorrow's you will be angry. Save the streak now."),
        .init(title: "One. Just one.", body: "Complete one habit. That's enough to keep the fire alive."),
        .init(title: "Streak emergency", body: "Your longest streak is at risk. Act now or start over."),
        .init(title: "The chain breaks tonight", body: "Unless you open the app and complete one discipline."),
        .init(title: "Don't reset to zero", body: "{streak} days earned. 0 days is where you'll be tomorrow."),
        .init(title: "Final warning", body: "Your streak has hours left. Not days. Hours."),
        .init(title: "Fight for it", body: "Everything you built is on the line. One habit saves it."),
        .init(title: "📉 Incoming", body: "Your stats are about to take a hit. Prevent it now."),
        .init(title: "The forge is cold", body: "No activity today. The fire dies without fuel."),
        .init(title: "You didn't come this far", body: "…to only come this far. Complete one habit. NOW."),
        .init(title: "Accountability check", body: "Is today the day you break? Or the day you didn't?"),
        .init(title: "Clock is ticking", body: "Streak death in hours. One completion = survival."),
        .init(title: "Worth protecting", body: "A {streak}-day streak is rare. Don't throw it away."),
        .init(title: "Emergency forge alert", body: "Critical: No disciplines completed. Streak in danger.")
    ]

    // MARK: - Comeback Messages (22 variants)

    private static let comebackMessages: [NotificationContent] = [
        .init(title: "We missed you", body: "The forge has been cold. Ready to reignite?"),
        .init(title: "Welcome back, {name}", body: "Every master has taken a break. The key is coming back."),
        .init(title: "It's not too late", body: "Your journey didn't end — it paused. Resume now."),
        .init(title: "The forge remembers", body: "Your progress is still here. Pick up where you left off."),
        .init(title: "Fresh start", body: "New streak, same fire. Day 1 again — and that's okay."),
        .init(title: "Restart the engine", body: "One habit. That's all it takes to begin again."),
        .init(title: "No judgment here", body: "Life happens. What matters is you're back."),
        .init(title: "Ready when you are", body: "Your disciplines haven't changed. Your willingness has."),
        .init(title: "The comeback", body: "Every great story has a comeback arc. This is yours."),
        .init(title: "Day 1 energy", body: "Remember why you started? That reason still exists."),
        .init(title: "Dormant, not dead", body: "Your habits are waiting. Reactivate the forge."),
        .init(title: "Still here", body: "We kept your setup. Just tap and start."),
        .init(title: "Rebuilding is noble", body: "Starting over isn't failure — quitting forever is."),
        .init(title: "One tap away", body: "Your next streak starts with a single completion."),
        .init(title: "The world moved on", body: "But your growth doesn't have to. Come back stronger."),
        .init(title: "Forge reboot", body: "Systems online. Habits loaded. Just waiting on you."),
        .init(title: "Missed you, {name}", body: "The forge has been silent. Bring back the sound of progress."),
        .init(title: "Second chances", body: "The app doesn't judge. It just asks: are you ready?"),
        .init(title: "Your blueprint is intact", body: "Habits, goals, progress — all saved. Just show up."),
        .init(title: "Remember the feeling?", body: "Completing a habit after a break hits different. Try it."),
        .init(title: "Rust comes off fast", body: "One day back and you'll wonder why you waited."),
        .init(title: "The fire never fully dies", body: "There's an ember waiting. Breathe on it today.")
    ]
}
