import Foundation
import DrumKeyCore

enum EQKeyMap {
    /// Two solid bass banks on the left, then percussion and accents on the right.
    static let linear: [DrumKey] = [
        .d, .d, .d, .d, .d, .d, .f, .f, .f, .f, .f, .f,
        .j, .j, .j, .j, .k, .k, .k, .k, .l, .l, .l, .l
    ]

    /// Paired bass clusters stay entirely left of two percussion/accent banks.
    static let led: [DrumKey] = [
        .d, .d, .f, .f, .d, .d, .f, .f, .d, .d, .f, .f,
        .j, .j, .k, .k, .l, .l, .j, .j, .k, .k, .l, .l
    ]

    static func isBass(_ key: DrumKey) -> Bool { key == .d || key == .f }
    static func peakHeight(for key: DrumKey) -> Double { isBass(key) ? 107 : 67 }
    static func ledRows(for key: DrumKey) -> Int { isBass(key) ? 16 : 10 }

    static func backgroundResponse(for key: DrumKey, at position: Double) -> Double {
        let centers: [Double]
        let spread: Double
        let gain: Double
        switch key {
        case .d: (centers, spread, gain) = ([0.14], 0.12, 0.78)
        case .f: (centers, spread, gain) = ([0.36], 0.12, 0.80)
        case .j: (centers, spread, gain) = ([0.61], 0.075, 0.43)
        case .k: (centers, spread, gain) = ([0.79], 0.065, 0.45)
        case .l: (centers, spread, gain) = ([0.95], 0.045, 0.46)
        case .space: return 0 // The router supplies both real bass responses.
        }
        guard isBass(key) == (position < 0.5) else { return 0 }
        let focus = centers.map { exp(-0.5 * pow((position - $0) / spread, 2)) }.max() ?? 0
        return gain * (0.08 + 0.92 * focus)
    }
}
