import Foundation

enum MasteryXPRouter {

    static func masteryXP(for habitName: String, pathType: MasteryPath.PathType) -> Int {
        let score = relevanceScore(habitName: habitName, pathType: pathType)
        return score > 0 ? score * 5 : 2
    }

    private static func relevanceScore(habitName: String, pathType: MasteryPath.PathType) -> Int {
        let name = habitName.lowercased()
        switch pathType {
        case .warrior:
            if name.contains("workout") || name.contains("push") || name.contains("squat") { return 3 }
            if name.contains("walk") || name.contains("run") { return 2 }
        case .scholar:
            if name.contains("read") || name.contains("study") { return 3 }
            if name.contains("journal") || name.contains("write") { return 2 }
        case .monk:
            if name.contains("meditat") || name.contains("cold") || name.contains("shower") { return 3 }
            if name.contains("journal") || name.contains("gratitude") { return 2 }
        case .athlete:
            if name.contains("workout") || name.contains("run") || name.contains("walk") { return 3 }
            if name.contains("water") || name.contains("sleep") { return 2 }
        case .strategist:
            if name.contains("plan") || name.contains("read") || name.contains("focus") { return 3 }
            if name.contains("journal") || name.contains("review") { return 2 }
        }
        return 0
    }
}
