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
        settings.visualizerTheme = .circleTowers
        settings.colorScheme = .roseQuartz
        let restored = AppSettings(defaults: defaults)
        #expect(restored.visualizerTheme == .circleTowers)
        #expect(restored.colorScheme == .roseQuartz)
        defaults.set("retiredTheme", forKey: "visualizerTheme")
        defaults.set("retiredPalette", forKey: "colorScheme")
        let fallback = AppSettings(defaults: defaults)
        #expect(fallback.visualizerTheme == .glassCircle)
        #expect(fallback.colorScheme == .classic)
    }
}
