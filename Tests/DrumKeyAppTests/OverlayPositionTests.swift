import Foundation
import Testing
@testable import DrumKey

@MainActor
struct OverlayPositionTests {
    private let windowSize = CGSize(width: 192, height: 252)

    @Test func roundTripsPlacementOnADisplayWithNegativeCoordinates() {
        let screen = CGRect(x: -1920, y: 40, width: 1920, height: 1040)
        let original = CGPoint(x: -1550, y: 520)
        let position = OverlayPosition(origin: original, windowSize: windowSize, visibleFrame: screen)
        let restored = position.origin(windowSize: windowSize, visibleFrame: screen)
        #expect(abs(restored.x - original.x) < 0.0001)
        #expect(abs(restored.y - original.y) < 0.0001)
    }

    @Test func outOfBoundsDropsStayVisible() {
        let screen = CGRect(x: 100, y: -400, width: 800, height: 600)
        let position = OverlayPosition(origin: CGPoint(x: 10000, y: -10000), windowSize: windowSize, visibleFrame: screen)
        let restored = position.origin(windowSize: windowSize, visibleFrame: screen)
        #expect(screen.contains(CGRect(origin: restored, size: windowSize)))
    }

    @Test func resolutionChangesPreserveRelativePlacement() {
        let originalScreen = CGRect(x: 0, y: 0, width: 1200, height: 800)
        let position = OverlayPosition(origin: CGPoint(x: 504, y: 274), windowSize: windowSize, visibleFrame: originalScreen)
        let largerScreen = CGRect(x: 1920, y: -80, width: 2400, height: 1400)
        let restored = position.origin(windowSize: windowSize, visibleFrame: largerScreen)
        #expect(restored.x == 3024)
        #expect(restored.y == 494)
    }

    @Test func positionsPersistIndependentlyForEachDisplay() {
        let suite = "DrumKey.OverlayPositionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let first = OverlayPosition(origin: CGPoint(x: 150, y: 700), windowSize: windowSize, visibleFrame: screen)
        let second = OverlayPosition(origin: CGPoint(x: 900, y: 200), windowSize: windowSize, visibleFrame: screen)
        let settings = AppSettings(defaults: defaults)
        settings.saveOverlayPosition(first, for: "main")
        settings.saveOverlayPosition(second, for: "secondary")
        let restored = AppSettings(defaults: defaults)
        #expect(restored.overlayPosition(for: "main") == first)
        #expect(restored.overlayPosition(for: "secondary") == second)
        #expect(restored.overlayPosition(for: "new-display") == nil)
    }
}
