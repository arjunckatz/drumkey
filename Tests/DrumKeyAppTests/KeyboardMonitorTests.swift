import CoreGraphics
import Testing
@testable import DrumKey

@MainActor
struct KeyboardMonitorTests {
    @Test func actualListenerAccessCanSucceedWhenPreflightDisagrees() {
        let tap = TestEventTap()
        let monitor = KeyboardMonitor(preflight: { false }, makeTap: { _, _ in tap })
        let started = monitor.start()
        #expect(started)
        #expect(monitor.isRunning)
        monitor.stop()
    }

    @Test func disabledTapIsReenabledInsteadOfBeingMistakenForHealthy() {
        let tap = TestEventTap()
        var created = 0
        let monitor = KeyboardMonitor(makeTap: { _, _ in
            created += 1
            return tap
        })
        monitor.start()
        tap.isEnabled = false
        #expect(!monitor.isRunning)
        let recovered = monitor.start()
        #expect(recovered)
        #expect(tap.enableCount == 2)
        #expect(created == 1)
        monitor.stop()
    }

    @Test func invalidTapIsReplaced() {
        let oldTap = TestEventTap()
        let newTap = TestEventTap()
        var created = 0
        let monitor = KeyboardMonitor(makeTap: { _, _ in
            created += 1
            return created == 1 ? oldTap : newTap
        })
        monitor.start()
        oldTap.isValid = false
        let recovered = monitor.start()
        #expect(recovered)
        #expect(oldTap.wasInvalidated)
        #expect(newTap.isEnabled)
        #expect(created == 2)
        monitor.stop()
    }

    @Test func tapThatCannotBeReenabledIsReplaced() {
        let oldTap = TestEventTap()
        let newTap = TestEventTap()
        var created = 0
        let monitor = KeyboardMonitor(makeTap: { _, _ in
            created += 1
            return created == 1 ? oldTap : newTap
        })
        monitor.start()
        oldTap.isEnabled = false
        oldTap.canEnable = false
        let recovered = monitor.start()
        #expect(recovered)
        #expect(oldTap.wasInvalidated)
        #expect(created == 2)
        monitor.stop()
    }

    @Test func failedCreationIsThrottledAndManualRetryIsImmediate() {
        var attempts = 0
        let monitor = KeyboardMonitor(preflight: { false }, makeTap: { _, _ in
            attempts += 1
            return nil
        }, clock: { 10 })
        let first = monitor.start()
        let second = monitor.start()
        #expect(!first && !second)
        #expect(attempts == 1)
        let forced = monitor.start(forceRetry: true)
        #expect(!forced)
        #expect(attempts == 2)
        #expect(!monitor.isRunning)
    }
}

@MainActor
private final class TestEventTap: KeyboardEventTap {
    var isValid = true
    var isEnabled = false
    var canEnable = true
    var enableCount = 0
    var wasInvalidated = false

    func enable() {
        enableCount += 1
        isEnabled = isValid && canEnable
    }

    func invalidate() {
        wasInvalidated = true
        isValid = false
        isEnabled = false
    }
}
