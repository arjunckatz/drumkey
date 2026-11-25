import Foundation
import DrumKeyCore
import Testing
@testable import DrumKey

struct KeyVisualDynamicsTests {
    @Test func retriggerAddsHeightFromTheCurrentDecay() {
        var dynamics = KeyVisualDynamics()
        dynamics.register(key: .d, at: 1)
        let firstHit = dynamics.level(for: .d, at: 1)
        let remaining = dynamics.level(for: .d, at: 1.35)
        #expect(remaining > 0 && remaining < firstHit)
        dynamics.register(key: .d, at: 1.35)
        let retriggered = dynamics.level(for: .d, at: 1.35)
        #expect(retriggered > firstHit)
        #expect(abs(retriggered - remaining - firstHit) < 0.0001)
    }

    @Test func slowReleaseSettlesAndResetClearsIt() {
        var dynamics = KeyVisualDynamics()
        dynamics.register(key: .j, at: 1)
        #expect(dynamics.level(for: .j, at: 1.5) > 0.1)
        #expect(dynamics.level(for: .j, at: 3) < 0.05)
        #expect(!dynamics.isAnimating(at: 5))
        dynamics.register(key: .k, at: 6)
        dynamics.reset()
        #expect(dynamics.levels(at: 6).values.allSatisfy { $0 == 0 })
    }

    @Test func rapidHitsStayBoundedAndLeaveOtherKeysIndependent() {
        var dynamics = KeyVisualDynamics()
        for index in 0..<500 {
            let time = 1 + Double(index) * 0.005
            dynamics.register(key: .f, at: time)
            #expect((0...1).contains(dynamics.level(for: .f, at: time)))
        }
        #expect(dynamics.level(for: .d, at: 3.5) == 0)
        let before = dynamics.levels(at: 3.5)
        dynamics.register(key: .f, at: 2)
        dynamics.register(key: .f, at: .nan)
        #expect(dynamics.levels(at: 3.5) == before)
    }
}
