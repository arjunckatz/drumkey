import DrumKeyCore
import Testing
@testable import DrumKey

struct PercussionBorderEQTests {
    @Test func isolatedHitIsSmallAndReleasesQuicklyOnItsOwnLane() {
        var eq = PercussionBorderEQ()
        eq.register(DrumHit(key: .j, timestamp: 1), deliveredAt: 5)
        #expect(eq.level(for: .j, at: 5) == 0.08)
        #expect(eq.level(for: .k, at: 5) == 0)
        #expect(eq.level(for: .j, at: 5.1) > 0)
        #expect(!eq.isAnimating(at: 5.25))
    }

    @Test func rapidBurstsCannotSkipTheThirtySecondBuildup() {
        var eq = PercussionBorderEQ()
        for index in 0..<120 {
            let time = Double(index) * 0.01
            eq.register(DrumHit(key: .k, timestamp: time), deliveredAt: time)
            #expect(eq.level(for: .k, at: time) < 0.12)
        }
        #expect(eq.level(for: .j, at: 1.19) == 0)
    }

    @Test func sustainedFrequentTappingEarnsTheCapAfterThirtySeconds() {
        var eq = PercussionBorderEQ()
        for index in 0...60 {
            let time = Double(index) * 0.5
            eq.register(DrumHit(key: .j, timestamp: time), deliveredAt: time)
            let level = eq.level(for: .j, at: time)
            #expect(level <= 0.60)
            if time < 30 { #expect(level < 0.60) }
        }
        #expect(abs(eq.level(for: .j, at: 30) - 0.60) < 0.0001)
        eq.register(DrumHit(key: .j, timestamp: 34), deliveredAt: 34)
        #expect(eq.level(for: .j, at: 34) == 0.08)
        eq.reset()
        #expect(eq.level(for: .j, at: 34) == 0)
    }

    @Test func sparseTapsAndNonPercussionKeysDoNotReachTheCap() {
        var eq = PercussionBorderEQ()
        for time in 0...35 {
            eq.register(DrumHit(key: .k, timestamp: Double(time)), deliveredAt: Double(time))
        }
        #expect(eq.level(for: .k, at: 35) < 0.40)
        for key: DrumKey in [.d, .f, .space, .l] {
            eq.register(DrumHit(key: key, timestamp: 35.01), deliveredAt: 35.01)
        }
        #expect(eq.level(for: .j, at: 35.01) == 0)
    }
}
