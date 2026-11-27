import DrumKeyCore
import Testing
@testable import DrumKey

struct VisualHitRouterTests {
    @Test func spaceTriggersBothBassEnvelopesAndOneChordFlashAtTheOriginalTime() {
        let original = DrumHit(key: .space, timestamp: 12)
        let visualHits = VisualHitRouter.hits(for: original)
        #expect(visualHits.map(\.key) == [.d, .f, .space])
        #expect(visualHits.allSatisfy { $0.timestamp == original.timestamp })
        var dynamics = KeyVisualDynamics()
        var flash = BassChordFlash()
        var eq = BackgroundEQ()
        var flashCount = 0
        for hit in visualHits {
            dynamics.register(key: hit.key, at: 12)
            if flash.register(hit, deliveredAt: 12) { flashCount += 1 }
            eq.register(key: hit.key, at: 12)
        }
        #expect(dynamics.level(for: .d, at: 12) > 0)
        #expect(dynamics.level(for: .d, at: 12) == dynamics.level(for: .f, at: 12))
        #expect([DrumKey.j, .k, .l].allSatisfy { dynamics.level(for: $0, at: 12) == 0 })
        #expect(flashCount == 1 && flash.intensity(at: 12) == 1)
        var manualEQ = BackgroundEQ()
        manualEQ.register(key: .d, at: 12)
        manualEQ.register(key: .f, at: 12)
        #expect(eq.levels(at: 12) == manualEQ.levels(at: 12))
        #expect(original.key.isAccent)
    }

    @Test func otherHitsKeepTheirIdentityAndAreNeverDuplicated() {
        for key in DrumKey.allCases where key != .space {
            let hit = DrumHit(key: key, timestamp: 8)
            #expect(VisualHitRouter.hits(for: hit) == [hit])
        }
    }
}
