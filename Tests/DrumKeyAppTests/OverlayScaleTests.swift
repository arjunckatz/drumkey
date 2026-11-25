import Foundation
import Testing
@testable import DrumKey

@MainActor
struct OverlayScaleTests {
    @Test func requestedSizesStayInsideTheAvailableDisplay() {
        for scale in OverlayScale.allCases {
            let roomy = CGSize(width: 1920, height: 1080)
            let normal = scale.size(fitting: roomy)
            #expect(abs(Double(normal.width) - 192 * scale.rawValue) < 0.0001)
            #expect(abs(Double(normal.height) - 252 * scale.rawValue) < 0.0001)
            let compact = CGSize(width: 500, height: 600)
            let fitted = scale.size(fitting: compact)
            #expect(fitted.width <= compact.width && fitted.height <= compact.height)
            #expect(abs(fitted.width / fitted.height - 192.0 / 252) < 0.0001)
        }
    }

    @Test func sizePreferencePersistsAndRejectsUnknownMultipliers() {
        let suite = "DrumKey.OverlayScaleTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.overlayScale == .one)
        settings.overlayScale = .two
        #expect(AppSettings(defaults: defaults).overlayScale == .two)
        defaults.set(7.0, forKey: "overlayScale")
        #expect(AppSettings(defaults: defaults).overlayScale == .one)
    }
}
