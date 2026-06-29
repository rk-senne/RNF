import Foundation

struct NarrativeEngine {

    static func narrative(
        level: Int,
        streak: Int,
        tier: String,
        weakestStat: String,
        strongestStat: String,
        daysSinceStart: Int,
        yesterdayMissed: Bool
    ) -> String {
        let bucket = selectBucket(daysSinceStart: daysSinceStart, streak: streak, yesterdayMissed: yesterdayMissed)
        let templates = lines(for: bucket, weakestStat: weakestStat, strongestStat: strongestStat, tier: tier, streak: streak, level: level)
        return pick(from: templates, daysSinceStart: daysSinceStart)
    }

    // MARK: - Bucket Selection

    private enum Bucket {
        case missed, newUser, building, firstWeek, streakBuilding
        case twoWeeks, monthly, deep, veteran, complete, highStreak
    }

    private static func selectBucket(daysSinceStart: Int, streak: Int, yesterdayMissed: Bool) -> Bucket {
        if yesterdayMissed { return .missed }
        if streak >= 30 { return .highStreak }
        if daysSinceStart >= 90 { return .complete }
        if daysSinceStart >= 61 { return .veteran }
        if daysSinceStart >= 31 { return .deep }
        if daysSinceStart == 30 { return .monthly }
        if daysSinceStart == 14 { return .twoWeeks }
        if daysSinceStart >= 8 { return .streakBuilding }
        if daysSinceStart == 7 { return .firstWeek }
        if daysSinceStart >= 4 { return .building }
        return .newUser
    }

    // MARK: - Templates (Forge Voice)
    // Rules: No encouragement. No "you can do it." Observational. Cold truth. Short.

    private static func lines(for bucket: Bucket, weakestStat: String, strongestStat: String, tier: String, streak: Int, level: Int) -> [String] {
        switch bucket {
        case .missed:
            return [
                "The flame dimmed. But embers remain. Reignite.",
                "You came back. The Forge does not judge how you fell. Only that you rose.",
                "A missed day does not unmake you. The system knows the difference between a stumble and a surrender.",
                "The chain broke. Forge a new one.",
                "Yesterday is ash. Today is unwritten.",
                "You returned. That separates you from the ones who didn't.",
                "The Forge is patient. It was always going to be here when you came back."
            ]
        case .newUser:
            return [
                "The Forge is lit. Whether it stays lit depends entirely on tomorrow.",
                "Day one. The system is watching. It makes no predictions yet.",
                "Most extinguish within three days. Prove the pattern wrong.",
                "The flame is barely lit. One gust could end it.",
                "You made a choice. Now make it again tomorrow.",
                "The Forge does not care about intentions. Only actions.",
                "First spark. Fragile. Handle it."
            ]
        case .building:
            return [
                "Still here. The Forge takes note.",
                "Consecutive days. The system is beginning to believe you.",
                "Not yet proven. But no longer ignored.",
                "The fire hasn't died. That alone puts you ahead of most.",
                "Four days. The Forge has seen longer. Show it more.",
                "Actions accumulating. The compound has begun.",
                "Still early. Still fragile. Still showing up."
            ]
        case .firstWeek:
            return [
                "Seven days. The Forge no longer wonders if you'll return. It expects it.",
                "One week. Most quit before this point. You didn't.",
                "Seven consecutive actions. The system has upgraded its expectations.",
                "A full week. You are no longer a stranger here.",
                "The first filter passed. The real work starts now.",
                "Week one. The flame is steadier now."
            ]
        case .streakBuilding:
            return [
                "The streak grows. Guard it. It will guard you back.",
                "Past the first week. This is where curiosity becomes commitment.",
                "\(strongestStat) leads. \(weakestStat) waits. The Forge tests what you neglect.",
                "Double digits ahead. The system rewards those who reach them.",
                "Consistency is compounding. You can't see it yet. You will.",
                "Each day the chain grows heavier. And harder to break."
            ]
        case .twoWeeks:
            return [
                "Fourteen days. What started as effort is becoming identity.",
                "Two weeks of proof. The Forge no longer monitors you — it serves you.",
                "Day 14. Custom disciplines unlocked. You earned the right to design your path.",
                "Half a month forged. The system registers you as Committed.",
                "Two weeks. The pattern is no longer a decision. It's a reflex.",
                "14 days. Your \(strongestStat) has grown beyond where most people plateau."
            ]
        case .monthly:
            return [
                "Thirty days. The \(tier) within you is no longer theory.",
                "One month. You have outlasted 80% of everyone who has ever tried this.",
                "30 days of fire. Your \(strongestStat) burns steady.",
                "A full month. The Forge has stopped testing your commitment. Now it tests your depth.",
                "Day 30. From spark to sustained flame.",
                "Monthly threshold crossed. The system compounds harder from here."
            ]
        case .deep:
            return [
                "Past thirty days. This is no longer what you do. It's who you are.",
                "The Forge knows your name now. It built you a seat.",
                "\(weakestStat) still has room. The system will keep pushing it.",
                "Level \(level). Every point was forged, not given.",
                "Deep territory. Few reach this. Fewer stay.",
                "The streak is long. The cost of breaking it is real now.",
                "You don't need motivation anymore. The structure carries you."
            ]
        case .veteran:
            return [
                "Veteran. The Forge has nothing left to teach you about showing up.",
                "Past sixty days. The shadows are restless. They know you're close.",
                "The \(tier) rank was not inherited. It was hammered into existence.",
                "Two months forged. The final third awaits.",
                "Your \(strongestStat) is among the highest the system has recorded.",
                "The end of the challenge approaches. But the Forge never closes.",
                "Day after day after day. This is what mastery looks like from the inside."
            ]
        case .complete:
            return [
                "Ninety days. The flame is no longer something you carry. It carries you.",
                "The challenge is complete. You kept every promise you made on day one.",
                "Beyond 90 days. You forge now because you cannot imagine stopping.",
                "The system has nothing left to unlock for you. You are the unlock.",
                "Level \(level). \(tier). Built through ninety days of proof.",
                "Post-challenge. Others wonder what changed about you. You know.",
                "The Forge was always yours. You just needed 90 days to prove it."
            ]
        case .highStreak:
            return [
                "\(streak) days. The chain is no longer iron. It's part of your skeleton.",
                "Streak: \(streak). The Forge has stopped counting. It trusts you now.",
                "\(streak) consecutive days. There is no version of you that quits this.",
                "The flame is eternal now. It doesn't flicker. It doesn't need fuel. It IS you.",
                "\(streak) days. Your \(strongestStat) has become your reputation.",
                "The streak compounds. Each day adds weight the next version of you will thank you for.",
                "\(streak). The system has seen enough. It bows."
            ]
        }
    }

    // MARK: - Deterministic Selection

    private static func pick(from templates: [String], daysSinceStart: Int) -> String {
        guard templates.count > 1 else { return templates.first ?? "" }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        let index = (dayOfYear &+ daysSinceStart) % templates.count
        let yesterdayIndex = ((dayOfYear - 1) &+ daysSinceStart) % templates.count
        if index == yesterdayIndex {
            return templates[(index + 1) % templates.count]
        }
        return templates[index]
    }
}
