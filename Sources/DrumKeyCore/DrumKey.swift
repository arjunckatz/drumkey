import Foundation

public enum DrumKey: String, CaseIterable, Sendable {
    case d
    case f
    case j
    case k
    case l
    case space

    public var label: String {
        switch self {
        case .space: "SPACE"
        default: rawValue.uppercased()
        }
    }

    public var isAccent: Bool {
        self == .space
    }
}

public struct DrumHit: Equatable, Sendable {
    public let key: DrumKey
    public let timestamp: TimeInterval

    public init(key: DrumKey, timestamp: TimeInterval) {
        self.key = key
        self.timestamp = timestamp
    }
}

public struct MeterEstimate: Equatable, Sendable {
    public static let initial = MeterEstimate(signature: "4/4", confidence: 0)
    public let signature: String
    public let confidence: Double

    public init(signature: String, confidence: Double) {
        self.signature = signature
        self.confidence = confidence
    }

    public var beatsPerBar: Int? {
        signature.split(separator: "/").first.flatMap { Int($0) }
    }
}

public struct RhythmSnapshot: Equatable, Sendable {
    public let bpm: Double?
    public let meter: MeterEstimate?
    public let hitCount: Int
    public let tempoConfidence: Double
    public let beatInBar: Int?

    public init(
        bpm: Double?,
        meter: MeterEstimate?,
        hitCount: Int,
        tempoConfidence: Double = 0,
        beatInBar: Int? = nil
    ) {
        self.bpm = bpm
        self.meter = meter
        self.hitCount = hitCount
        self.tempoConfidence = tempoConfidence
        self.beatInBar = beatInBar
    }

    public static let empty = RhythmSnapshot(bpm: nil, meter: .initial, hitCount: 0)
}
