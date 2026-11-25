import Foundation
import DrumKeyCore

/// A decorative, key-driven spectrum. Values describe visual energy rather
/// than measured audio frequencies, and settle without a permanent timer.
struct BackgroundEQ {
    static let bandCount = 40
    private let decayDuration: TimeInterval = 0.95
    private var energies = Array(repeating: 0.0, count: bandCount)
    private var lastHitTime: TimeInterval?

    mutating func register(key: DrumKey, at now: TimeInterval) {
        guard now.isFinite, now >= 0 else { return }
        if let lastHitTime, now < lastHitTime { return }
        let decay = decay(at: now)
        for index in energies.indices {
            let position = Double(index) / Double(Self.bandCount - 1)
            energies[index] = min(0.98, energies[index] * decay + Self.response(for: key, at: position))
        }
        lastHitTime = now
    }

    func levels(at now: TimeInterval) -> [Double] {
        let decay = decay(at: now)
        return energies.indices.map { index in
            let idle = 0.035 + 0.035 * (0.5 + 0.5 * sin(Double(index) * 0.71))
            return min(1, idle + energies[index] * decay)
        }
    }

    func isAnimating(at now: TimeInterval) -> Bool {
        guard now.isFinite, let lastHitTime, now >= lastHitTime else { return false }
        return now - lastHitTime < decayDuration
    }

    mutating func reset() {
        energies = Array(repeating: 0, count: Self.bandCount)
        lastHitTime = nil
    }

    private func decay(at now: TimeInterval) -> Double {
        guard now.isFinite, let lastHitTime, now >= lastHitTime else { return 0 }
        return pow(max(0, 1 - (now - lastHitTime) / decayDuration), 2)
    }

    private static func response(for key: DrumKey, at position: Double) -> Double {
        let center: Double
        let spread: Double
        let gain: Double
        switch key {
        case .d: (center, spread, gain) = (0.12, 0.17, 0.62)
        case .f: (center, spread, gain) = (0.29, 0.18, 0.64)
        case .j: (center, spread, gain) = (0.62, 0.16, 0.65)
        case .k: (center, spread, gain) = (0.82, 0.15, 0.69)
        case .l: (center, spread, gain) = (0.95, 0.12, 0.76)
        case .space:
            return 0.68 + 0.20 * abs(sin(position * 2 * .pi + 0.4))
        }
        let focus = exp(-0.5 * pow((position - center) / spread, 2))
        return gain * (0.08 + 0.92 * focus)
    }
}
