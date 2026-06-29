import Foundation

enum FocusSessionType: CaseIterable, Identifiable {
    case quick, standard, deep, flow

    var id: String { name }
    var name: String {
        switch self {
        case .quick: return "Quick Focus"
        case .standard: return "Standard"
        case .deep: return "Deep Session"
        case .flow: return "Flow State"
        }
    }
    var durationSeconds: Int {
        switch self {
        case .quick: return 900
        case .standard: return 1500
        case .deep: return 2700
        case .flow: return 3600
        }
    }
    var xp: Int {
        switch self {
        case .quick: return 10
        case .standard: return 15
        case .deep: return 25
        case .flow: return 35
        }
    }
    var subtitle: String {
        switch self {
        case .quick: return "15 min"
        case .standard: return "25 min"
        case .deep: return "45 min"
        case .flow: return "60 min"
        }
    }
}
