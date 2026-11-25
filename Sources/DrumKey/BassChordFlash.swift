import Foundation
import DrumKeyCore

/// Match physical onset timestamps, then animate from delivery time so a busy
/// main queue neither invents chords nor consumes the visible flash early.
struct BassChordFlash {
    private let chordWindow: TimeInterval = 0.08
    private let duration: TimeInterval = 0.36
    private var pending: DrumHit?
    private var startedAt: TimeInterval?

    @discardableResult
    mutating func register(_ hit: DrumHit, deliveredAt now: TimeInterval) -> Bool {
        guard hit.key == .d || hit.key == .f,
              hit.timestamp.isFinite, hit.timestamp >= 0,
              now.isFinite, now >= 0 else { return false }
        if let pending, hit.timestamp < pending.timestamp { return false }

        if let pending, pending.key != hit.key,
           hit.timestamp - pending.timestamp <= chordWindow {
            self.pending = nil
            startedAt = now
            return true
        }
        pending = hit
        return false
    }

    func intensity(at now: TimeInterval) -> Double {
        guard now.isFinite, let startedAt, now >= startedAt else { return 0 }
        return pow(max(0, 1 - (now - startedAt) / duration), 1.5)
    }

    mutating func reset() {
        pending = nil
        startedAt = nil
    }
}
