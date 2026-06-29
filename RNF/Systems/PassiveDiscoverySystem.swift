import Foundation

struct PassiveDiscoverySystem {

    // P20-EXP-14d: All possible discoveries for the log view
    static let allDiscoveries: [Discovery] = [
        Discovery(id: "before_dawn", name: "Before Dawn", message: "Before dawn. You chose this. The Forge remembers those who don't wait.", xp: 15, rarity: .common),
        Discovery(id: "late_forge", name: "Late Forge", message: "The world sleeps. You do not. The Forge was watching.", xp: 10, rarity: .common),
        Discovery(id: "perfect_week", name: "Perfect Week", message: "Seven days. Zero compromise. The system takes note.", xp: 50, rarity: .uncommon),
        Discovery(id: "centurion", name: "Centurion", message: "100 actions forged. Each one a link in a chain most never build.", xp: 40, rarity: .uncommon),
        Discovery(id: "the_machine", name: "The Machine", message: "500. The Forge no longer questions you. It serves.", xp: 100, rarity: .rare),
        Discovery(id: "thousandfold", name: "Thousandfold", message: "A thousand. The Forge has nothing left to teach. Only to witness.", xp: 200, rarity: .legendary),
        Discovery(id: "balanced", name: "Balanced", message: "No weak link. The chain holds everywhere. The Forge approves.", xp: 50, rarity: .rare),
        Discovery(id: "specialist", name: "Specialist", message: "One domain. Total command. The Forge respects depth.", xp: 40, rarity: .uncommon),
        Discovery(id: "polymath", name: "Polymath", message: "All domains answer to you. The Forge has never seen this.", xp: 100, rarity: .legendary),
        Discovery(id: "awakening", name: "Awakening", message: "Something shifted. The Forge felt it before you did.", xp: 20, rarity: .common),
        Discovery(id: "veteran", name: "Veteran", message: "Battle-tested. The Forge does not flinch. Neither do you.", xp: 50, rarity: .rare),
        Discovery(id: "the_return", name: "The Return", message: "You came back. The Forge does not judge how you fell. Only that you rose.", xp: 20, rarity: .uncommon),
        Discovery(id: "eternal", name: "Eternal", message: "90 days without breaking. The flame is no longer fuel. It is you.", xp: 100, rarity: .legendary),
        Discovery(id: "the_walker", name: "The Walker", message: "The Forge sees beyond the screen. 5,000 steps. The body moved.", xp: 10, rarity: .common),
        Discovery(id: "the_wanderer", name: "The Wanderer", message: "The Forge sees beyond the screen. 10,000 steps. The body moved without being told.", xp: 25, rarity: .uncommon),
        Discovery(id: "the_pilgrim", name: "The Pilgrim", message: "15,000 steps. The Forge walks beside those who refuse to stop.", xp: 40, rarity: .rare),
        Discovery(id: "no_rest_days", name: "No Rest Days", message: "Rest is earned. You chose otherwise. The Forge noticed.", xp: 15, rarity: .common),
        Discovery(id: "seeker", name: "Seeker", message: "Ten discoveries. You look where others don't. The Forge rewards curiosity.", xp: 30, rarity: .uncommon),
        Discovery(id: "archaeologist", name: "Archaeologist", message: "Twenty-five secrets pulled from silence. The Forge opens further.", xp: 60, rarity: .rare),
    ]

    static func evaluate(
        steps: Int,
        streak: Int,
        totalHabits: Int,
        level: Int,
        stats: [Double],
        hour: Int,
        daysSinceStart: Int,
        isWeekend: Bool,
        history: [DiscoveryRecord]
    ) -> [Discovery] {
        let earned = Set(history.map(\.discoveryID))
        var results: [Discovery] = []

        func award(_ d: Discovery) {
            guard !earned.contains(d.id) else { return }
            results.append(d)
        }

        // Time-based
        if hour < 6 {
            award(Discovery(id: "before_dawn", name: "Before Dawn", message: "Before dawn. You chose this. The Forge remembers those who don't wait.", xp: 15, rarity: .common))
        }
        if hour >= 23 {
            award(Discovery(id: "late_forge", name: "Late Forge", message: "The world sleeps. You do not. The Forge was watching.", xp: 10, rarity: .common))
        }

        // Consistency
        if streak >= 7, streak % 7 == 0 {
            award(Discovery(id: "perfect_week", name: "Perfect Week", message: "Seven days. Zero compromise. The system takes note.", xp: 50, rarity: .uncommon))
        }
        if totalHabits >= 100 {
            award(Discovery(id: "centurion", name: "Centurion", message: "100 actions forged. Each one a link in a chain most never build.", xp: 40, rarity: .uncommon))
        }
        if totalHabits >= 500 {
            award(Discovery(id: "the_machine", name: "The Machine", message: "500. The Forge no longer questions you. It serves.", xp: 100, rarity: .rare))
        }
        if totalHabits >= 1000 {
            award(Discovery(id: "thousandfold", name: "Thousandfold", message: "A thousand. The Forge has nothing left to teach. Only to witness.", xp: 200, rarity: .legendary))
        }

        // Stats
        if !stats.isEmpty, stats.min()! > 10 {
            award(Discovery(id: "balanced", name: "Balanced", message: "No weak link. The chain holds everywhere. The Forge approves.", xp: 50, rarity: .rare))
        }
        if stats.contains(where: { $0 >= 25 }) {
            award(Discovery(id: "specialist", name: "Specialist", message: "One domain. Total command. The Forge respects depth.", xp: 40, rarity: .uncommon))
        }
        if !stats.isEmpty, stats.min()! > 20 {
            award(Discovery(id: "polymath", name: "Polymath", message: "All domains answer to you. The Forge has never seen this.", xp: 100, rarity: .legendary))
        }

        // Level
        if level >= 5 {
            award(Discovery(id: "awakening", name: "Awakening", message: "Something shifted. The Forge felt it before you did.", xp: 20, rarity: .common))
        }
        if level >= 20 {
            award(Discovery(id: "veteran", name: "Veteran", message: "Battle-tested. The Forge does not flinch. Neither do you.", xp: 50, rarity: .rare))
        }

        // Behavioral
        if streak == 1, daysSinceStart > 7 {
            award(Discovery(id: "the_return", name: "The Return", message: "You came back. The Forge does not judge how you fell. Only that you rose.", xp: 20, rarity: .uncommon))
        }
        if streak >= 90 {
            award(Discovery(id: "eternal", name: "Eternal", message: "90 days without breaking. The flame is no longer fuel. It is you.", xp: 100, rarity: .legendary))
        }

        // HealthKit
        if steps >= 5000 {
            award(Discovery(id: "the_walker", name: "The Walker", message: "The Forge sees beyond the screen. 5,000 steps. The body moved.", xp: 10, rarity: .common))
        }
        if steps >= 10000 {
            award(Discovery(id: "the_wanderer", name: "The Wanderer", message: "The Forge sees beyond the screen. 10,000 steps. The body moved without being told.", xp: 25, rarity: .uncommon))
        }
        if steps >= 15000 {
            award(Discovery(id: "the_pilgrim", name: "The Pilgrim", message: "15,000 steps. The Forge walks beside those who refuse to stop.", xp: 40, rarity: .rare))
        }
        if steps >= 3000, isWeekend {
            award(Discovery(id: "no_rest_days", name: "No Rest Days", message: "Rest is earned. You chose otherwise. The Forge noticed.", xp: 15, rarity: .common))
        }

        // Meta
        if history.count >= 10 {
            award(Discovery(id: "seeker", name: "Seeker", message: "Ten discoveries. You look where others don't. The Forge rewards curiosity.", xp: 30, rarity: .uncommon))
        }
        if history.count >= 25 {
            award(Discovery(id: "archaeologist", name: "Archaeologist", message: "Twenty-five secrets pulled from silence. The Forge opens further.", xp: 60, rarity: .rare))
        }

        return results
    }
}
