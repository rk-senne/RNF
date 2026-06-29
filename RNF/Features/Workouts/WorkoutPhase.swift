import SwiftUI

enum WorkoutPhase: String {
    case warmUp = "Warm Up"
    case build = "Build"
    case push = "Push"
    case finishStrong = "Finish Strong"
    case complete = "Complete"

    static func from(progress: Double) -> WorkoutPhase {
        switch progress {
        case 0..<0.3: return .warmUp
        case 0.3..<0.6: return .build
        case 0.6..<0.8: return .push
        case 0.8..<1.0: return .finishStrong
        default: return .complete
        }
    }

    var encouragement: String {
        switch self {
        case .warmUp: return "Settle in. Find the rhythm."
        case .build: return "Building momentum."
        case .push: return "The hard part is where growth happens."
        case .finishStrong: return "Almost there. Finish strong."
        case .complete: return "Done. Respect earned."
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .warmUp: return [Color(hex: "#1A1A2E"), Color(hex: "#16213E")]
        case .build: return [Color(hex: "#16213E"), Color(hex: "#2D1B69")]
        case .push: return [Color(hex: "#2D1B69"), Color(hex: "#6B2D10")]
        case .finishStrong: return [Color(hex: "#6B2D10"), Color(hex: "#1B4332")]
        case .complete: return [Color(hex: "#1B4332"), Color(hex: "#14532D")]
        }
    }
}
