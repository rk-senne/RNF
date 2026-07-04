import Foundation

// P22-ONB-05: ArchetypeQuiz model with 3 questions and 27 archetype combinations.

// MARK: - Archetype

struct Archetype: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let title: String
    let description: String
    let primaryStat: StatAxis
    let secondaryStat: StatAxis
    let tertiaryStat: StatAxis
    let emoji: String
}

// MARK: - Stat Axes

enum StatAxis: String, Codable, CaseIterable, Hashable {
    case body
    case mind
    case spirit

    var displayName: String {
        switch self {
        case .body: return "Body"
        case .mind: return "Mind"
        case .spirit: return "Spirit"
        }
    }

    var emoji: String {
        switch self {
        case .body: return "💪"
        case .mind: return "🧠"
        case .spirit: return "🔥"
        }
    }
}

// MARK: - Quiz Question

struct ArchetypeQuestion: Identifiable {
    let id: Int
    let prompt: String
    let options: [ArchetypeOption]
}

struct ArchetypeOption: Identifiable, Hashable {
    let id: String
    let text: String
    let axis: StatAxis
}

// MARK: - Quiz Engine

struct ArchetypeQuiz {

    static let questions: [ArchetypeQuestion] = [
        ArchetypeQuestion(
            id: 1,
            prompt: "When you face a challenge, what's your first instinct?",
            options: [
                ArchetypeOption(id: "q1_body", text: "Push through with action", axis: .body),
                ArchetypeOption(id: "q1_mind", text: "Analyze and strategize", axis: .mind),
                ArchetypeOption(id: "q1_spirit", text: "Trust my intuition", axis: .spirit),
            ]
        ),
        ArchetypeQuestion(
            id: 2,
            prompt: "What gives you the most energy?",
            options: [
                ArchetypeOption(id: "q2_body", text: "Physical movement and discipline", axis: .body),
                ArchetypeOption(id: "q2_mind", text: "Learning something new", axis: .mind),
                ArchetypeOption(id: "q2_spirit", text: "Deep connection and purpose", axis: .spirit),
            ]
        ),
        ArchetypeQuestion(
            id: 3,
            prompt: "Your ideal version of yourself excels at:",
            options: [
                ArchetypeOption(id: "q3_body", text: "Strength and resilience", axis: .body),
                ArchetypeOption(id: "q3_mind", text: "Wisdom and clarity", axis: .mind),
                ArchetypeOption(id: "q3_spirit", text: "Inner peace and presence", axis: .spirit),
            ]
        ),
    ]

    /// Resolves a 3-answer combination into an archetype.
    static func resolve(answers: [StatAxis]) -> Archetype {
        guard answers.count == 3 else { return archetypes["mind_mind_mind"]! }
        let key = answers.map(\.rawValue).joined(separator: "_")
        return archetypes[key] ?? archetypes["mind_mind_mind"]!
    }

    /// Stat distribution based on quiz answers.
    static func statDistribution(answers: [StatAxis]) -> [StatAxis: Int] {
        var distribution: [StatAxis: Int] = [.body: 0, .mind: 0, .spirit: 0]
        let weights = [3, 2, 1]

        for (index, axis) in answers.enumerated() {
            let weight = index < weights.count ? weights[index] : 1
            distribution[axis, default: 0] += weight
        }

        return distribution
    }

    // MARK: - All 27 Archetypes

    static let archetypes: [String: Archetype] = {
        var map: [String: Archetype] = [:]
        let axes = StatAxis.allCases

        for a in axes {
            for b in axes {
                for c in axes {
                    let key = "\(a.rawValue)_\(b.rawValue)_\(c.rawValue)"
                    let info = archetypeInfo(primary: a, secondary: b)
                    map[key] = Archetype(
                        id: key,
                        name: info.name,
                        title: info.title,
                        description: info.description,
                        primaryStat: a,
                        secondaryStat: b,
                        tertiaryStat: c,
                        emoji: info.emoji
                    )
                }
            }
        }

        return map
    }()

    private static func archetypeInfo(primary: StatAxis, secondary: StatAxis) -> (name: String, title: String, description: String, emoji: String) {
        switch (primary, secondary) {
        case (.body, .body):
            return ("Titan", "The Unstoppable Force", "Pure physical mastery through relentless action.", "⚔️")
        case (.body, .mind):
            return ("Strategist", "The Tactical Warrior", "Disciplined action guided by sharp thinking.", "🎯")
        case (.body, .spirit):
            return ("Guardian", "The Resilient Protector", "Strength powered by deep purpose.", "🛡️")
        case (.mind, .body):
            return ("Architect", "The Builder of Worlds", "Brilliant plans made real through execution.", "🏗️")
        case (.mind, .mind):
            return ("Sage", "The Eternal Scholar", "Wisdom is your greatest weapon.", "📚")
        case (.mind, .spirit):
            return ("Oracle", "The Visionary Thinker", "Insight meets intuition.", "🔮")
        case (.spirit, .body):
            return ("Monk", "The Awakened Warrior", "Inner peace expressed through discipline.", "🧘")
        case (.spirit, .mind):
            return ("Mystic", "The Mindful Seeker", "Spiritual depth guided by curiosity.", "✨")
        case (.spirit, .spirit):
            return ("Phoenix", "The Ever-Rising Flame", "You transform through presence and purpose.", "🔥")
        }
    }
}
