import Foundation

// P20-EXP-12a: Seasonal Arc model — one arc per calendar month
struct SeasonalArc {
    let month: Int  // 1-12
    let name: String
    let theme: String
    let bonusStat: String
    let xpMultiplier: Double  // bonus for matching actions
    let completionXP: Int
    let title: String  // exclusive title on completion

    var isActive: Bool {
        Calendar.current.component(.month, from: Date()) == month
    }

    var displayTitle: String {
        let year = Calendar.current.component(.year, from: Date())
        return "\(name) • \(monthName) \(year)"
    }

    private var monthName: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        let date = Calendar.current.date(from: components) ?? Date()
        return f.string(from: date)
    }

    static let all: [SeasonalArc] = [
        SeasonalArc(month: 1, name: "Foundation", theme: "Balanced growth", bonusStat: "", xpMultiplier: 1.10, completionXP: 500, title: "Foundation Forged"),
        SeasonalArc(month: 2, name: "Endurance", theme: "Streak focus", bonusStat: "discipline", xpMultiplier: 1.0, completionXP: 500, title: "Endurance Proven"),
        SeasonalArc(month: 3, name: "Strength", theme: "Movement heavy", bonusStat: "strength", xpMultiplier: 1.20, completionXP: 500, title: "Strength Earned"),
        SeasonalArc(month: 4, name: "Mind", theme: "Reading and focus", bonusStat: "focus", xpMultiplier: 1.20, completionXP: 500, title: "Mind Sharpened"),
        SeasonalArc(month: 5, name: "Discipline", theme: "Perfect days", bonusStat: "discipline", xpMultiplier: 1.15, completionXP: 500, title: "Pure Discipline"),
        SeasonalArc(month: 6, name: "Energy", theme: "Body and vitality", bonusStat: "energy", xpMultiplier: 1.20, completionXP: 500, title: "Energy Unleashed"),
        SeasonalArc(month: 7, name: "Wisdom", theme: "Learning depth", bonusStat: "wisdom", xpMultiplier: 1.20, completionXP: 500, title: "Wisdom Gathered"),
        SeasonalArc(month: 8, name: "Spirit", theme: "Inner strength", bonusStat: "spirit", xpMultiplier: 1.20, completionXP: 500, title: "Spirit Forged"),
        SeasonalArc(month: 9, name: "Focus", theme: "Deep work", bonusStat: "focus", xpMultiplier: 1.20, completionXP: 500, title: "Focus Mastered"),
        SeasonalArc(month: 10, name: "Resilience", theme: "Recovery and grit", bonusStat: "discipline", xpMultiplier: 1.15, completionXP: 500, title: "Resilience Built"),
        SeasonalArc(month: 11, name: "Power", theme: "All-out effort", bonusStat: "strength", xpMultiplier: 1.20, completionXP: 500, title: "Power Claimed"),
        SeasonalArc(month: 12, name: "Reflection", theme: "Year in review", bonusStat: "mind", xpMultiplier: 1.10, completionXP: 500, title: "Year Forged"),
    ]

    static var current: SeasonalArc? {
        all.first { $0.isActive }
    }
}
