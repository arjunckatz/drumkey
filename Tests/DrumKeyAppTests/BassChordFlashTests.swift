import DrumKeyCore
import Testing
@testable import DrumKey

struct BassChordFlashTests {
    @Test func matchesEitherBassOrderAndConsumesEachPair() {
        for keys: [DrumKey] in [[.d, .f], [.f, .d]] {
            var flash = BassChordFlash()
            let first = flash.register(DrumHit(key: keys[0], timestamp: 1), deliveredAt: 5)
            let second = flash.register(DrumHit(key: keys[1], timestamp: 1.06), deliveredAt: 5.06)
            let third = flash.register(DrumHit(key: keys[1], timestamp: 1.07), deliveredAt: 5.07)
            #expect(!first && second && !third)
        }
    }

    @Test func sequentialBassAndOtherKeysDoNotInventAChord() {
        var flash = BassChordFlash()
        for hit in [
            DrumHit(key: .d, timestamp: 1),
            DrumHit(key: .d, timestamp: 1.01),
            DrumHit(key: .j, timestamp: 1.02),
            DrumHit(key: .k, timestamp: 1.03),
            DrumHit(key: .l, timestamp: 1.04),
            DrumHit(key: .f, timestamp: 1.2)
        ] {
            let triggered = flash.register(hit, deliveredAt: 10)
            #expect(!triggered)
        }
        #expect(flash.intensity(at: 10) == 0)
    }

    @Test func delayedDeliveryUsesOriginalTimingAndStillShowsTheWholeFlash() {
        var flash = BassChordFlash()
        flash.register(DrumHit(key: .d, timestamp: 1), deliveredAt: 10)
        flash.register(DrumHit(key: .j, timestamp: 1.02), deliveredAt: 11)
        let triggered = flash.register(DrumHit(key: .f, timestamp: 1.04), deliveredAt: 12)
        #expect(triggered)
        #expect(flash.intensity(at: 12) == 1)
        #expect(flash.intensity(at: 12.18) > 0 && flash.intensity(at: 12.18) < 1)
        #expect(flash.intensity(at: 12.4) == 0)
        flash.reset()
        let afterReset = flash.register(DrumHit(key: .d, timestamp: 1.05), deliveredAt: 12.5)
        #expect(!afterReset)
        #expect(flash.intensity(at: 12.5) == 0)
        flash.reset()
        let afterPendingReset = flash.register(DrumHit(key: .f, timestamp: 1.06), deliveredAt: 12.6)
        #expect(!afterPendingReset)
    }
}
