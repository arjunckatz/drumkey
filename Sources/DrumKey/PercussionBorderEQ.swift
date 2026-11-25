import Foundation
import DrumKeyCore

/// Each border lane earns a higher peak through sustained real input. A burst
/// cannot skip the thirty-second buildup, and each hit still releases quickly.
struct PercussionBorderEQ {
    private struct Lane {
        var hits: [TimeInterval] = []
        var startedAt: TimeInterval?
        var lastInput: TimeInterval?
        var deliveredAt: TimeInterval?
        var peak = 0.08
    }

    private var lanes: [DrumKey: Lane] = [:]
    private let release: TimeInterval = 0.22

    mutating func register(_ hit: DrumHit, deliveredAt now: TimeInterval) {
        guard hit.key == .j || hit.key == .k,
              hit.timestamp.isFinite, hit.timestamp >= 0,
              now.isFinite, now >= 0 else { return }
        var lane = lanes[hit.key] ?? Lane()
        if let last = lane.lastInput, hit.timestamp < last { return }
        if let last = lane.deliveredAt, now < last { return }
        if let last = lane.lastInput, hit.timestamp - last > 3 { lane = Lane() }
        if lane.startedAt == nil { lane.startedAt = hit.timestamp }
        lane.hits.removeAll { $0 < hit.timestamp - 30 }
        lane.hits.append(hit.timestamp)
        if lane.hits.count > 512 { lane.hits.removeFirst(lane.hits.count - 512) }
        let maturity = min(1, (hit.timestamp - (lane.startedAt ?? hit.timestamp)) / 30)
        let density = min(1, Double(lane.hits.count) / 60)
        lane.peak = 0.08 + 0.52 * min(maturity, density)
        lane.lastInput = hit.timestamp
        lane.deliveredAt = now
        lanes[hit.key] = lane
    }

    func level(for key: DrumKey, at now: TimeInterval) -> Double {
        guard now.isFinite, let lane = lanes[key], let start = lane.deliveredAt, now >= start else { return 0 }
        let envelope = pow(max(0, 1 - (now - start) / release), 1.4)
        return min(0.60, lane.peak * envelope)
    }

    func isAnimating(at now: TimeInterval) -> Bool {
        level(for: .j, at: now) > 0 || level(for: .k, at: now) > 0
    }

    mutating func reset() {
        lanes.removeAll(keepingCapacity: true)
    }
}
