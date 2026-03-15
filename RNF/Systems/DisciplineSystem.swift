import Foundation

struct DisciplineSystem {

    static func applyStatGain(
        current: Int,
        base: Int
    ) -> Int {

        // diminishing returns
        let modifier = 1.0 - (Double(current) / 150.0)

        let gain = Int(Double(base) * modifier)

        return max(gain, 1)
    }

}
