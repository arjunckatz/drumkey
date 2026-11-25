import Foundation
import Testing
@testable import DrumKey

@MainActor
struct VisualizerPreferencesTests {
    @Test func themeAndColorsPersistSeparatelyAndUnknownValuesFallBack() {
        let suite = "DrumKey.VisualizerPreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.visualizerTheme == .glassCircle)
        #expect(settings.colorScheme == .classic)
        settings.visualizerTheme = .ledMatrix
        settings.colorScheme = .neon
        let restored = AppSettings(defaults: defaults)
        #expect(restored.visualizerTheme == .ledMatrix)
        #expect(restored.colorScheme == .neon)
        defaults.set("retiredTheme", forKey: "visualizerTheme")
        defaults.set("retiredPalette", forKey: "colorScheme")
        let fallback = AppSettings(defaults: defaults)
        #expect(fallback.visualizerTheme == .glassCircle)
        #expect(fallback.colorScheme == .classic)
    }
}
