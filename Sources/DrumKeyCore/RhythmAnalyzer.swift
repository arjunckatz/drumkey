import Foundation

/// Estimates the tapped pulse and recurring three- or four-beat patterns.
/// Space supplies accent evidence. The instrument-like visual mapping has no
/// role in inference. A provisional meter remains visible while evidence grows.
public struct RhythmAnalyzer: Sendable {
    private var hits: [DrumHit] = []
    private var currentMeter: MeterEstimate = .initial
    private var lastBeatInterval: TimeInterval?
    private let historyDuration: TimeInterval = 180
    private let tempoWindow: TimeInterval = 12
    private let tempoWarmup: TimeInterval = 10

    private static let beatMultiples: [(value: Double, weight: Double)] = [
        (1, 1), (0.5, 0.98), (2, 0.96), (0.25, 0.96), (0.125, 0.93),
        (1.0 / 3, 0.75), (2.0 / 3, 0.75), (1.5, 0.75), (3, 0.73), (4, 0.92)
    ]

    public let idleResetInterval: TimeInterval
    public let maximumHistory: Int
    public private(set) var snapshot: RhythmSnapshot = .empty

    public init(
        idleResetInterval: TimeInterval = 30,
        maximumHistory: Int = 2_048
    ) {
        self.idleResetInterval = max(0.1, idleResetInterval)
        self.maximumHistory = max(4, maximumHistory)
    }

    @discardableResult
    public mutating func register(_ hit: DrumHit) -> RhythmSnapshot {
        guard hit.key != .l else { return snapshot }
        guard hit.timestamp.isFinite, hit.timestamp >= 0 else { return snapshot }
        if let lastHit = hits.last {
            guard hit.timestamp >= lastHit.timestamp else { return snapshot }
            expire(at: hit.timestamp)
        }

        hits.append(hit)
        if hits.count > maximumHistory {
            hits.removeFirst(hits.count - maximumHistory)
        }
        if let start = hits.firstIndex(where: { $0.timestamp >= hit.timestamp - historyDuration }), start > 0 {
            hits.removeFirst(start)
        }

        let tempo = estimatedTempo()
        if let tempo { lastBeatInterval = tempo.interval }
        let beatInterval = tempo?.interval ?? lastBeatInterval ?? 0.5
        currentMeter = estimatedMeter(beatInterval: beatInterval)
        snapshot = RhythmSnapshot(
            bpm: lastBeatInterval.map { 60 / $0 },
            meter: currentMeter,
            hitCount: hits.count,
            tempoConfidence: tempo?.confidence ?? 0,
            beatInBar: beatInBar(meter: currentMeter, beatInterval: beatInterval)
        )
        return snapshot
    }

    /// Clear stale estimates even when there is no new input.
    @discardableResult
    public mutating func expire(at timestamp: TimeInterval) -> Bool {
        guard let lastHit = hits.last,
              timestamp - lastHit.timestamp > idleResetInterval else { return false }
        reset()
        return true
    }

    public mutating func reset() {
        hits.removeAll(keepingCapacity: true)
        currentMeter = .initial
        lastBeatInterval = nil
        snapshot = .empty
    }

    private func estimatedTempo() -> (interval: TimeInterval, confidence: Double)? {
        guard let latest = hits.last?.timestamp else { return nil }
        // Merge near-simultaneous presses for tempo only. Individual keys still
        // reach the soundstage and the meter analyzer. Use elapsed time rather
        // than a fixed hit count so subdivisions do not shorten the average.
        var onsets: [TimeInterval] = []
        for hit in hits where hit.timestamp >= latest - tempoWindow {
            if let previous = onsets.last, hit.timestamp - previous < 0.04 { continue }
            onsets.append(hit.timestamp)
        }
        guard onsets.count >= 4 else { return nil }

        let intervals = zip(onsets, onsets.dropFirst())
            .map { $1 - $0 }
            .filter { $0 >= 0.04 && $0 <= 2 }
        guard intervals.count >= 3 else { return nil }

        // Fit plausible beats before averaging. Normalizing subdivisions first
        // prevents a mixture of eighth notes and quarter notes from dragging
        // the estimate between two unrelated tempos. A small continuity bias
        // resolves close half/double-time candidates without fixing the tempo.
        let reference = lastBeatInterval ?? Self.foldIntoBeatRange(Self.trimmedMean(intervals))
        var beatInterval = reference
        var bestScore = -Double.infinity
        for bpm in 60...200 {
            let candidate = 60 / Double(bpm)
            // Rank using a broad squared timing loss. Otherwise uneven beats
            // can score better as a different subdivision on every tap.
            let fit = intervals.reduce(0) { total, interval in
                let match = Self.tempoMatch(interval, beatInterval: candidate)
                return total + max(0, 1 - pow(match.error / 0.40, 2)) * match.weight
            } / Double(intervals.count)
            let continuity = min(1, abs(log2(candidate / reference))) * 0.025
            let score = fit - continuity
            if score > bestScore {
                beatInterval = candidate
                bestScore = score
            }
        }

        // Average the normalized timings, trimming isolated slips. The wider
        // 20% tolerance allows ordinary human timing variation; after ten
        // seconds a lower-confidence average is still useful to display.
        for _ in 0..<2 {
            let normalized = intervals.compactMap { interval -> Double? in
                let match = Self.tempoMatch(interval, beatInterval: beatInterval)
                return match.error <= 0.25 ? match.interval : nil
            }
            guard !normalized.isEmpty else { break }
            beatInterval = min(1, max(0.30, Self.trimmedMean(normalized)))
        }
        let agreement = tempoAgreement(intervals, beatInterval: beatInterval)
        let elapsed = (onsets.last ?? latest) - (onsets.first ?? latest)
        guard agreement >= 0.60 || elapsed >= tempoWarmup else { return nil }

        let maturity = min(1, Double(intervals.count) / 7)
        return (beatInterval, agreement * maturity)
    }

    private func tempoAgreement(_ intervals: [TimeInterval], beatInterval: TimeInterval) -> Double {
        intervals.reduce(0) { total, interval in
            let match = Self.tempoMatch(interval, beatInterval: beatInterval)
            return total + max(0, 1 - match.error / 0.20) * match.weight
        } / Double(intervals.count)
    }

    private static func tempoMatch(
        _ interval: TimeInterval, beatInterval: TimeInterval
    ) -> (interval: TimeInterval, error: Double, weight: Double) {
        let directError = abs(interval - beatInterval) / beatInterval
        if directError <= 0.30 { return (interval, directError, 1) }
        var best = (interval: interval, error: Double.infinity, weight: 1.0)
        var bestCost = Double.infinity
        for multiple in beatMultiples {
            let normalized = interval / multiple.value
            let error = abs(normalized - beatInterval) / beatInterval
            // Prefer a slightly uneven ordinary beat over explaining the same
            // tap as a different subdivision, including during averaging.
            let cost = error + (1 - multiple.weight) * 0.40
            if cost < bestCost {
                best = (normalized, error, multiple.weight)
                bestCost = cost
            }
        }
        return best
    }

    private static func trimmedMean(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let trim = sorted.count / 10
        let middle = sorted[trim..<(sorted.count - trim)]
        return middle.reduce(0, +) / Double(middle.count)
    }

    private static func foldIntoBeatRange(_ rawInterval: TimeInterval) -> TimeInterval {
        var interval = rawInterval
        // Leave room for jitter around the supported tempo boundaries before
        // choosing a half/double-time interpretation.
        while interval < 0.27 { interval *= 2 }
        while interval > 1.10 { interval /= 2 }
        return min(1, max(0.30, interval))
    }

    private func estimatedMeter(beatInterval: TimeInterval) -> MeterEstimate {
        guard let first = hits.first, let last = hits.last else { return .initial }
        let accents = hits.filter { $0.key.isAccent }
        let groupedHits = Dictionary(grouping: hits, by: \.key)
        let candidates = [3, 4].map { beats in
            let accent = accentEvidence(accents, beatsPerBar: beats, beatInterval: beatInterval)
            let pattern = patternEvidence(groupedHits, beatsPerBar: beats, beatInterval: beatInterval)
            let accentMaturity = min(1, accent.weight / 6)
            let patternMaturity = min(1, pattern.weight / 48)
            let value = accent.score * accentMaturity * 0.75 + pattern.score * patternMaturity * 0.25
            return (beats: beats, value: value, maturity: max(accentMaturity, patternMaturity))
        }

        // Keep the current hypothesis when the alternatives have similar
        // support. New evidence can replace it without restarting the session.
        let incumbent = candidates.first { $0.beats == currentMeter.beatsPerBar } ?? candidates[1]
        let challenger = candidates.first { $0.beats != incumbent.beats } ?? candidates[0]
        let switchMargin = 0.025 + currentMeter.confidence * 0.08
        let selected = challenger.value > incumbent.value + switchMargin ? challenger : incumbent
        let other = candidates.first { $0.beats != selected.beats } ?? challenger
        let separation = max(0, selected.value - other.value) / max(0.001, selected.value + other.value)
        let elapsedBeats = (last.timestamp - first.timestamp) / beatInterval
        let durationMaturity = min(1, elapsedBeats / 16)
        let confidence = min(0.98, selected.maturity * durationMaturity * (0.35 + separation * 0.65))
        return MeterEstimate(signature: "\(selected.beats)/4", confidence: confidence)
    }

    private func accentEvidence(
        _ accents: [DrumHit], beatsPerBar: Int, beatInterval: TimeInterval
    ) -> (score: Double, weight: Double) {
        guard let last = hits.last else { return (0, 0) }
        var totalWeight = 0.0
        var matchedWeight = 0.0
        for (earlier, later) in zip(accents, accents.dropFirst()) {
            let distance = (later.timestamp - earlier.timestamp) / beatInterval
            let match = max(0, 1 - abs(distance - Double(beatsPerBar)) / 0.35)
            let weight = exp(-(last.timestamp - later.timestamp) / 60)
            totalWeight += weight
            matchedWeight += match * weight
        }
        return (matchedWeight / max(totalWeight, 0.001), totalWeight)
    }

    private func patternEvidence(
        _ groupedHits: [DrumKey: [DrumHit]], beatsPerBar: Int, beatInterval: TimeInterval
    ) -> (score: Double, weight: Double) {
        guard let first = hits.first, let last = hits.last else { return (0, 0) }
        let barInterval = Double(beatsPerBar) * beatInterval
        let tolerance = beatInterval * 0.12
        var possibleWeight = 0.0
        var matchedWeight = 0.0
        var searchIndices: [DrumKey: Int] = [:]

        // Both candidates use the same comparison start so the shorter bar
        // does not gain an artificial advantage from extra early comparisons.
        for hit in hits where hit.timestamp - first.timestamp >= beatInterval * 4 - tolerance {
            let weight = (hit.key.isAccent ? 2.0 : 1.0) * exp(-(last.timestamp - hit.timestamp) / 60)
            possibleWeight += weight
            let expected = hit.timestamp - barInterval
            let keyHits = groupedHits[hit.key] ?? []
            var index = searchIndices[hit.key] ?? 0
            while index < keyHits.count, keyHits[index].timestamp < expected - tolerance {
                index += 1
            }
            searchIndices[hit.key] = index
            if index < keyHits.count, abs(keyHits[index].timestamp - expected) <= tolerance {
                matchedWeight += weight
            }
        }
        return (matchedWeight / max(possibleWeight, 0.001), possibleWeight)
    }

    private func beatInBar(meter: MeterEstimate?, beatInterval: TimeInterval) -> Int? {
        guard let count = meter?.beatsPerBar, count > 0,
              let accent = hits.last(where: { $0.key.isAccent }),
              let last = hits.last else { return nil }
        let beatsSinceAccent = Int(((last.timestamp - accent.timestamp) / beatInterval + 0.12).rounded(.down))
        return beatsSinceAccent % count + 1
    }
}
