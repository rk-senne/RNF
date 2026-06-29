import Foundation

// P20-EXP-09a: Progress snapshot for milestone memories
struct ProgressSnapshot: Codable, Identifiable {
    var id: String { "\(milestone)-\(dateString)" }
    let milestone: String  // e.g. "day7", "day30", "tier_ascendant"
    let dateString: String // "2026-06-29"
    let level: Int
    let streak: Int
    let xpTotal: Int
    let stats: [Double]   // 7 values: strength, discipline, focus, energy, wisdom, mind, spirit
    let tierName: String
}
