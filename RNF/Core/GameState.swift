import Foundation
import Combine

class GameState: ObservableObject {

    @Published var level: Int = 1
    @Published var xp: Int = 0
    @Published var xpToNext: Int = 200
    @Published var streak: Int = 0

    @Published var stats = Stats(
        strength: 2,
        discipline: 2,
        focus: 2,
        energy: 2,
        wisdom: 2,
        mind: 2,
        spirit: 2
    )

    @Published var titles: [String] = []

}
