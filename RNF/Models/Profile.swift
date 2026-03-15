import Foundation

struct Profile: Codable, Identifiable {

    let id: UUID

    var xp: Int
    var level: Int
    var streak_days: Int
    var streak_shields: Int


    // RPG stats
    var strength: Int
    var discipline: Int
    var focus: Int
    var energy: Int
    var wisdom: Int
    var mind: Int
    var spirit: Int
    

}

// MARK: - Placeholder Profile (used before database loads)

extension Profile {

    static let placeholder = Profile(
        id: UUID(),
        xp: 0,
        level: 1,
        streak_days: 0,
        streak_shields: 0, 
        strength: 2,
        discipline: 2,
        focus: 2,
        energy: 2,
        wisdom: 2,
        mind: 2,
        spirit: 2
    )

}
