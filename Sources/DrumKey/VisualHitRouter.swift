import DrumKeyCore

/// Expand visual feedback only. The rhythm analyzer receives the original hit,
/// and the passive keyboard listener never synthesizes operating-system keys.
enum VisualHitRouter {
    static func hits(for hit: DrumHit) -> [DrumHit] {
        guard hit.key == .space else { return [hit] }
        return [.d, .f, .space].map { DrumHit(key: $0, timestamp: hit.timestamp) }
    }
}
