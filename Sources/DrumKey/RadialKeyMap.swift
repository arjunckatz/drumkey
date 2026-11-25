import Foundation
import DrumKeyCore

/// A mirrored low-to-high sweep from the upper bass crown to the lower accents.
/// Smooth, overlapping fields let a chord form one silhouette instead of
/// lighting unrelated columns inherited from the glass stage.
struct RadialKeyMap {
    struct Band {
        let key: DrumKey
        let center: Double
        let width: Double
    }

    struct Influence {
        let key: DrumKey
        let weight: Double
    }

    struct Sample {
        let x: Double
        let y: Double
        let influences: [Influence]
        let primaryKey: DrumKey

        func level(in levels: [DrumKey: Double]) -> Double {
            let sum = influences.reduce(0) { $0 + ($1.weight * (levels[$1.key] ?? 0)) }
            return min(1, max(0, sum + (levels[.space] ?? 0) * 0.55))
        }
    }

    // Angles run clockwise from twelve o'clock and are reflected on the left.
    static let bands: [Band] = [
        Band(key: .d, center: 25, width: 24),
        Band(key: .f, center: 55, width: 22),
        Band(key: .j, center: 90, width: 18),
        Band(key: .k, center: 125, width: 16),
        Band(key: .l, center: 160, width: 12)
    ]

    static let halo = samples(count: 96, offset: 0)
    static let spectrum = samples(count: 64, offset: 0.5)
    static let orbits = samples(count: 20, offset: 0.5)

    static func sample(at angle: Double) -> Sample {
        let foldedDegrees = acos(max(-1, min(1, cos(angle)))) * 180 / .pi
        let influences = bands.map { band in
            let distance = (foldedDegrees - band.center) / band.width
            return Influence(key: band.key, weight: exp(-0.5 * distance * distance))
        }
        return Sample(x: sin(angle), y: -cos(angle), influences: influences,
                      primaryKey: influences.max { $0.weight < $1.weight }!.key)
    }

    private static func samples(count: Int, offset: Double) -> [Sample] {
        (0..<count).map { sample(at: (Double($0) + offset) * 2 * .pi / Double(count)) }
    }
}
