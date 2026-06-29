import Foundation

struct MasteryPath: Codable, Identifiable {

    enum PathType: String, Codable, CaseIterable {
        case warrior    // strength focus
        case scholar    // mind/wisdom focus
        case monk       // discipline/spirit focus
        case athlete    // energy/strength focus
        case strategist // focus/mind
    }

    let id: UUID
    var user_id: UUID?
    let pathType: PathType
    var tier: Int
    var xpInPath: Int
    var started_at: Date?

    enum CodingKeys: String, CodingKey {
        case id, user_id, tier, started_at
        case pathType = "path_type"
        case xpInPath = "xp_in_path"
    }

    var title: String {
        switch (pathType, tier) {
        case (.warrior, 1): return "Initiate"
        case (.warrior, 2): return "Fighter"
        case (.warrior, 3): return "Titan"
        case (.scholar, 1): return "Student"
        case (.scholar, 2): return "Sage"
        case (.scholar, 3): return "Mastermind"
        case (.monk, 1): return "Novice"
        case (.monk, 2): return "Ascetic"
        case (.monk, 3): return "Enlightened"
        case (.athlete, 1): return "Runner"
        case (.athlete, 2): return "Competitor"
        case (.athlete, 3): return "Olympian"
        case (.strategist, 1): return "Thinker"
        case (.strategist, 2): return "Planner"
        case (.strategist, 3): return "Architect"
        default: return "Unknown"
        }
    }

    static let tierThresholds = [0, 500, 2000, 5000]
}
