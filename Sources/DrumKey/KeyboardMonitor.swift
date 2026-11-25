import AppKit
import CoreGraphics
import DrumKeyCore
import OSLog

@MainActor
final class KeyboardMonitor {
    var onHit: ((DrumHit) -> Void)?
    private let preflight: () -> Bool
    private let makeTap: @MainActor (CGEventTapCallBack, UnsafeMutableRawPointer) -> (any KeyboardEventTap)?
    private let clock: () -> TimeInterval
    private let logger = Logger(subsystem: "local.drumkey.app", category: "KeyboardCapture")
    private var eventTap: (any KeyboardEventTap)?
    private var nextRetryTime: TimeInterval = 0
    private var generation: UInt64 = 0

    var isRunning: Bool { eventTap?.isValid == true && eventTap?.isEnabled == true }
    var hasPermission: Bool { preflight() }

    init(
        preflight: @escaping () -> Bool = { CGPreflightListenEventAccess() },
        makeTap: @escaping @MainActor (CGEventTapCallBack, UnsafeMutableRawPointer) -> (any KeyboardEventTap)? = SystemKeyboardEventTap.create,
        clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.preflight = preflight
        self.makeTap = makeTap
        self.clock = clock
    }

    @discardableResult
    func start(forceRetry: Bool = false) -> Bool {
        if let eventTap {
            if eventTap.isValid {
                if !eventTap.isEnabled { eventTap.enable() }
                if eventTap.isEnabled { return true }
            }
            logger.notice("Recreating an invalid or disabled keyboard listener.")
            stop()
        }
        guard forceRetry || clock() >= nextRetryTime else { return false }

        // Creating a passive tap is the authoritative access check. Preflight
        // can disagree with a permission changed while the process is running.
        let callback: CGEventTapCallBack = { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(context).takeUnretainedValue()
            // The source is installed exclusively on the main run loop.
            MainActor.assumeIsolated {
                monitor.receive(type: type, event: event)
            }
            return Unmanaged.passUnretained(event)
        }
        guard let tap = makeTap(callback, Unmanaged.passUnretained(self).toOpaque()) else {
            nextRetryTime = clock() + 5
            let permissionGranted = hasPermission
            logger.error("Could not create a passive keyboard listener. Permission preflight reports \(permissionGranted).")
            return false
        }

        eventTap = tap
        tap.enable()
        guard isRunning else {
            stop()
            nextRetryTime = clock() + 5
            return false
        }
        nextRetryTime = 0
        logger.notice("Passive keyboard listener is active.")
        return isRunning
    }

    func stop() {
        generation &+= 1
        eventTap?.invalidate()
        eventTap = nil
        nextRetryTime = 0
    }

    func requestPermission() {
        CGRequestListenEventAccess()
    }

    private func receive(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            logger.notice("macOS disabled the keyboard listener. Attempting recovery.")
            eventTap?.enable()
            return
        }
        guard type == .keyDown, isRunning,
              event.getIntegerValueField(.keyboardEventAutorepeat) == 0,
              event.flags.intersection([.maskCommand, .maskControl, .maskAlternate]).isEmpty,
              let key = DrumKey(macKeyCode: event.getIntegerValueField(.keyboardEventKeycode)) else { return }

        let hit = DrumHit(key: key, timestamp: Double(event.timestamp) / 1_000_000_000)
        let currentGeneration = generation
        // Keep analysis and drawing outside the event-tap callback. FIFO main
        // queue delivery preserves timestamps and rejects hits queued at pause.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.generation == currentGeneration, self.isRunning else { return }
            self.onHit?(hit)
        }
    }
}

@MainActor
protocol KeyboardEventTap: AnyObject {
    var isValid: Bool { get }
    var isEnabled: Bool { get }
    func enable()
    func invalidate()
}

@MainActor
private final class SystemKeyboardEventTap: KeyboardEventTap {
    private let port: CFMachPort
    private let source: CFRunLoopSource

    var isValid: Bool { CFMachPortIsValid(port) }
    var isEnabled: Bool { CGEvent.tapIsEnabled(tap: port) }

    private init(port: CFMachPort, source: CFRunLoopSource) {
        self.port = port
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    static func create(callback: CGEventTapCallBack, context: UnsafeMutableRawPointer) -> (any KeyboardEventTap)? {
        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .listenOnly, eventsOfInterest: mask,
            callback: callback, userInfo: context
        ) else { return nil }
        guard let source = CFMachPortCreateRunLoopSource(nil, port, 0) else {
            CFMachPortInvalidate(port)
            return nil
        }
        return SystemKeyboardEventTap(port: port, source: source)
    }

    func enable() {
        guard isValid else { return }
        CGEvent.tapEnable(tap: port, enable: true)
    }

    func invalidate() {
        CGEvent.tapEnable(tap: port, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        CFMachPortInvalidate(port)
    }
}

extension DrumKey {
    init?(macKeyCode: Int64) {
        switch macKeyCode {
        case 2: self = .d
        case 3: self = .f
        case 38: self = .j
        case 40: self = .k
        case 37: self = .l
        case 49: self = .space
        default: return nil
        }
    }
}
