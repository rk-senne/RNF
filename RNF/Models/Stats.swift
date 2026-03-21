import Foundation

struct Stats: Codable, Equatable {

    var strength: Int
    var discipline: Int
    var focus: Int
    var energy: Int
    var wisdom: Int
    var mind: Int
    var spirit: Int

    static let baseline = Stats(
        strength: 2,
        discipline: 2,
        focus: 2,
        energy: 2,
        wisdom: 2,
        mind: 2,
        spirit: 2
    )

}
