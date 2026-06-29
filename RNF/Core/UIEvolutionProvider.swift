import SwiftUI

// P20-EXP-06a: UI Evolution Provider — drives visual evolution based on user level
@MainActor
final class UIEvolutionProvider: ObservableObject {
    @Published var state: UIEvolutionState = .disciple

    func update(level: Int) {
        state = UIEvolutionState.from(level: level)
    }
}

enum UIEvolutionState {
    case disciple    // 1-4: clean, minimal
    case awakened    // 5-9: subtle purple glow on borders
    case ascendant   // 10-14: gradient shimmer on surfaces
    case warlord     // 15-19: deeper tones, radar ghost ring
    case apex        // 20+: gold accents, ambient particles

    static func from(level: Int) -> UIEvolutionState {
        switch level {
        case 1...4: return .disciple
        case 5...9: return .awakened
        case 10...14: return .ascendant
        case 15...19: return .warlord
        default: return .apex
        }
    }

    var accentColor: Color {
        switch self {
        case .disciple: return RNFColors.primary
        case .awakened: return Color(hex: "#9B6BF7")
        case .ascendant: return Color(hex: "#E53E3E")
        case .warlord: return Color(hex: "#1A56DB")
        case .apex: return Color(hex: "#D4AF37")
        }
    }

    var borderGlow: Bool {
        switch self {
        case .disciple: return false
        default: return true
        }
    }

    var showAmbientParticles: Bool {
        self == .apex
    }

    var completedAccent: Color {
        self == .apex ? Color(hex: "#D4AF37") : RNFColors.success
    }
}
