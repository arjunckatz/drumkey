import Foundation
import DrumKeyCore

/// Broad lateral bass jaws, diagonal horns and separate top/bottom crowns.
/// Compact angular fields have sharp crests for a distorted, pointed outline.
struct RadialKeyMap {
    struct Band {
        let key: DrumKey
        let centers: [Double]
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
            return min(1, max(0, sum))
        }
    }

    // Angles run clockwise from twelve o'clock. L is a fine serrated rim.
    static let bands: [Band] = [
        Band(key: .d, centers: [90, 270], width: 58),
        Band(key: .f, centers: [45, 135, 225, 315], width: 34),
        Band(key: .j, centers: [0], width: 40),
        Band(key: .k, centers: [180], width: 44),
        Band(key: .l, centers: (0..<12).map { 15 + Double($0) * 30 }, width: 6)
    ]

    static let halo = samples(count: 120, offset: 0)
    static let spectrum = samples(count: 72, offset: 0)
    static let orbits = samples(count: 24, offset: 0)
    static let blades = samples(count: 24, offset: 0.5)

    static func sample(at angle: Double) -> Sample {
        let degrees = angle * 180 / .pi
        let influences = bands.map { band in
            let distance = band.centers.map { center in
                abs(atan2(sin((degrees - center) * .pi / 180), cos((degrees - center) * .pi / 180))) * 180 / .pi
            }.min() ?? 180
            let crest = max(0, 1 - distance / band.width)
            let profile = pow(crest, band.key == .d ? 1.15 : 1.5)
            return Influence(key: band.key, weight: profile * (band.key == .l ? 0.72 : 1))
        }
        return Sample(x: sin(angle), y: -cos(angle), influences: influences,
                      primaryKey: influences.max { $0.weight < $1.weight }?.key ?? .d)
    }

    private static func samples(count: Int, offset: Double) -> [Sample] {
        (0..<count).map { sample(at: (Double($0) + offset) * 2 * .pi / Double(count)) }
    }
}
