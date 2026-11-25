import Foundation
import DrumKeyCore

/// Each hit adds to the remaining height. Exponential release makes retriggers
/// continuous, while the cap keeps every theme inside the overlay.
struct KeyVisualDynamics {
    private struct Envelope {
        let value: Double
        let time: TimeInterval
    }

    private var envelopes: [DrumKey: Envelope] = [:]
    private let increment = 0.42
    private let release: TimeInterval = 0.70

    mutating func register(key: DrumKey, at now: TimeInterval) {
        guard now.isFinite, now >= 0 else { return }
        if let previous = envelopes[key], now < previous.time { return }
        envelopes[key] = Envelope(value: min(1, level(for: key, at: now) + increment), time: now)
    }

    func level(for key: DrumKey, at now: TimeInterval) -> Double {
        guard now.isFinite, let envelope = envelopes[key], now >= envelope.time else { return 0 }
        let value = envelope.value * exp(-(now - envelope.time) / release)
        return value > 0.002 ? min(1, value) : 0
    }

    func levels(at now: TimeInterval) -> [DrumKey: Double] {
        Dictionary(uniqueKeysWithValues: DrumKey.allCases.map { ($0, level(for: $0, at: now)) })
    }

    func isAnimating(at now: TimeInterval) -> Bool {
        DrumKey.allCases.contains { level(for: $0, at: now) > 0 }
    }

    mutating func reset() {
        envelopes.removeAll(keepingCapacity: true)
    }
}
