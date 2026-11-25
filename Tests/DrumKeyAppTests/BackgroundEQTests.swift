import Foundation
import DrumKeyCore
import Testing
@testable import DrumKey

@MainActor
struct BackgroundEQTests {
    @Test func jointBassCanReachRedWhileAnIsolatedTapStaysLower() {
        var eq = BackgroundEQ()
        eq.register(key: .d, at: 1)
        #expect((eq.levels(at: 1).max() ?? 1) < 0.9)
        eq.register(key: .f, at: 1.008)
        #expect((eq.levels(at: 1.008).max() ?? 0) > 0.94)
        for index in 0..<100 {
            eq.register(key: DrumKey.allCases[index % DrumKey.allCases.count], at: 2 + Double(index) * 0.01)
        }
        #expect(eq.levels(at: 3).allSatisfy { $0.isFinite && (0...1).contains($0) })
    }

    @Test func spectrumSettlesAndResetRemovesStoredEnergy() {
        var eq = BackgroundEQ()
        let idle = eq.levels(at: 0)
        eq.register(key: .space, at: 1)
        #expect(eq.isAnimating(at: 1.2))
        #expect((eq.levels(at: 1.1).max() ?? 0) > (eq.levels(at: 1.7).max() ?? 1))
        #expect(!eq.isAnimating(at: 2))
        #expect(eq.levels(at: 2) == idle)
        eq.register(key: .k, at: 3)
        eq.reset()
        #expect(!eq.isAnimating(at: 3))
        #expect(eq.levels(at: 3) == idle)
    }

    @Test func transparencyIsFaintByDefaultAndPersistsIndependently() {
        let suite = "DrumKey.BackgroundEQTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.eqTransparency == 0.92)
        let visibility = settings.visibility
        settings.eqTransparency = 0.74
        let restored = AppSettings(defaults: defaults)
        #expect(restored.eqTransparency == 0.74)
        #expect(restored.visibility == visibility)
        defaults.set(2.0, forKey: "eqTransparency")
        #expect(AppSettings(defaults: defaults).eqTransparency == 1)
    }
}
