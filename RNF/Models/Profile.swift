import Foundation

struct Profile: Codable, Identifiable {

    let id: UUID

    var email: String?
    var xp_total: Int
    var level: Int
    var streak: Int
    var forgiveness_tokens: Int
    var morning_notification_time: String?
    var evening_notification_time: String?

    var strength: Int
    var discipline: Int
    var focus: Int
    var energy: Int
    var wisdom: Int
    var mind: Int
    var spirit: Int
    var created_at: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case xp_total
        case level
        case streak = "current_streak"
        case forgiveness_tokens
        case morning_notification_time
        case evening_notification_time
        case strength
        case discipline
        case focus
        case energy
        case wisdom
        case mind
        case spirit
        case created_at
    }

}

extension Profile {

    static let placeholder = Profile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        email: nil,
        xp_total: 0,
        level: 1,
        streak: 0,
        forgiveness_tokens: 0,
        morning_notification_time: nil,
        evening_notification_time: nil,
        strength: Stats.baseline.strength,
        discipline: Stats.baseline.discipline,
        focus: Stats.baseline.focus,
        energy: Stats.baseline.energy,
        wisdom: Stats.baseline.wisdom,
        mind: Stats.baseline.mind,
        spirit: Stats.baseline.spirit,
        created_at: nil
    )

    var isPlaceholder: Bool {
        id == Self.placeholder.id
    }

    var stats: Stats {
        get {
            Stats(
                strength: strength,
                discipline: discipline,
                focus: focus,
                energy: energy,
                wisdom: wisdom,
                mind: mind,
                spirit: spirit
            )
        }
        set {
            strength = newValue.strength
            discipline = newValue.discipline
            focus = newValue.focus
            energy = newValue.energy
            wisdom = newValue.wisdom
            mind = newValue.mind
            spirit = newValue.spirit
        }
    }

}
