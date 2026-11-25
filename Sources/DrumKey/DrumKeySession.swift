import AppKit
import Carbon
import Combine
import DrumKeyCore

enum CaptureStatus: String {
    case listening = "Listening"
    case paused = "Paused"
    case permissionRequired = "Permission needed"
    case unavailable = "Input unavailable"
    case secureInput = "Secure input"
    case preview = "Preview"

    var symbol: String {
        switch self {
        case .listening: "waveform"
        case .paused: "pause.circle"
        case .permissionRequired: "hand.raised"
        case .unavailable: "exclamationmark.circle"
        case .secureInput: "lock"
        case .preview: "play.circle"
        }
    }

    var detail: String {
        switch self {
        case .listening: "Tap D, F, J, K and Space alongside your music. L adds a manual visual accent."
        case .paused: "Enable DrumKey to show the overlay and follow your taps."
        case .permissionRequired: "Allow DrumKey in System Settings → Privacy & Security → Input Monitoring. If it is already switched on, remove that entry and add the current DrumKey app, then quit and reopen it."
        case .unavailable: "The keyboard listener could not start. Retry access or restart DrumKey."
        case .secureInput: "A secure text field or app is protecting keyboard input. Feedback resumes when it releases secure input."
        case .preview: "A short example rhythm is playing visually. A real tap takes over immediately."
        }
    }
}

@MainActor
final class DrumKeySession: NSObject, ObservableObject {
    let settings: AppSettings
    let displays: DisplayManager
    let overlay: OverlayController
    private let keyboard = KeyboardMonitor()
    private var analyzer = RhythmAnalyzer()
    private var subscriptions = Set<AnyCancellable>()
    private var maintenanceTimer: Timer?
    private var previewTask: Task<Void, Never>?
    private var isSuspended = false

    @Published private(set) var status: CaptureStatus = .permissionRequired
    @Published private(set) var isPreviewing = false
    var onStatusChange: (() -> Void)?

    init(settings: AppSettings, displays: DisplayManager) {
        self.settings = settings
        self.displays = displays
        overlay = OverlayController(settings: settings)
        super.init()

        keyboard.onHit = { [weak self] hit in self?.receive(hit) }
        displays.onChange = { [weak self] in self?.repositionOverlay() }
        overlay.onDisplayChangedByDrag = { [weak self] displayID in
            guard let self, let display = self.displays.displays.first(where: { $0.id == displayID }) else { return }
            self.settings.selectDisplay(display)
        }
        settings.$isEnabled.dropFirst().sink { [weak self] enabled in
            Task { @MainActor [weak self] in self?.setEnabled(enabled) }
        }.store(in: &subscriptions)
        settings.$visibility.sink { [weak self] value in
            self?.overlay.setVisibility(value)
        }.store(in: &subscriptions)
        settings.$eqTransparency.sink { [weak self] value in
            self?.overlay.setEQTransparency(value)
        }.store(in: &subscriptions)
        settings.$overlayScale.sink { [weak self] value in
            self?.overlay.setScale(value)
        }.store(in: &subscriptions)
        settings.$visualizerTheme.sink { [weak self] value in
            self?.overlay.setTheme(value)
        }.store(in: &subscriptions)
        settings.$colorScheme.sink { [weak self] value in
            self?.overlay.setColorScheme(value)
        }.store(in: &subscriptions)
        settings.$preferredDisplayID.dropFirst().sink { [weak self] id in
            self?.repositionOverlay(preferredID: id)
        }.store(in: &subscriptions)
    }

    func start() {
        repositionOverlay()
        setEnabled(settings.isEnabled)
        maintenanceTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.maintain() }
        }
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(suspend), name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(resume), name: NSWorkspace.didWakeNotification, object: nil)
        center.addObserver(self, selector: #selector(suspend), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(resume), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
    }

    func stop() {
        stopPreview()
        maintenanceTimer?.invalidate()
        maintenanceTimer = nil
        keyboard.stop()
        overlay.hide()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func resetRhythm() {
        analyzer.reset()
        overlay.update(snapshot: .empty)
    }

    func requestPermission() {
        keyboard.requestPermission()
        retryCapture()
    }

    func retryCapture() {
        guard settings.isEnabled, !isSuspended else { return }
        stopPreview()
        keyboard.stop()
        resetRhythm()
        refreshCapture(forceRetry: true)
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else { return }
        NSWorkspace.shared.open(url)
    }

    func togglePreview() {
        if isPreviewing {
            stopPreview()
            return
        }
        resetRhythm()
        isPreviewing = true
        setStatus(.preview)
        overlay.show()
        previewTask = Task { @MainActor [weak self] in
            let pattern: [DrumKey] = [.space, .d, .j, .f, .space, .d, .k, .f]
            let startTime = ProcessInfo.processInfo.systemUptime
            for index in 0..<24 {
                guard !Task.isCancelled, let self else { return }
                // A deterministic 150 BPM example remains steady while UI
                // inspection or window drawing delays a preview animation.
                let hit = DrumHit(key: pattern[index % pattern.count], timestamp: startTime + Double(index) * 0.4)
                self.processHit(hit)
                if hit.key == .d {
                    self.processHit(DrumHit(key: .f, timestamp: hit.timestamp + 0.008))
                }
                if index % 8 == 6 {
                    self.processHit(DrumHit(key: .l, timestamp: hit.timestamp + 0.012))
                }
                try? await Task.sleep(for: .milliseconds(400))
            }
            guard !Task.isCancelled else { return }
            self?.stopPreview()
        }
    }

    func stopPreview() {
        guard isPreviewing else { return }
        cancelPreview()
        setEnabled(settings.isEnabled)
    }

    private func cancelPreview() {
        previewTask?.cancel()
        previewTask = nil
        isPreviewing = false
        resetRhythm()
    }

    private func receive(_ hit: DrumHit) {
        guard settings.isEnabled, !isSuspended else { return }
        stopPreview()
        processHit(hit)
    }

    private func processHit(_ hit: DrumHit) {
        let snapshot = analyzer.register(hit)
        overlay.register(hit: hit, snapshot: snapshot)
    }

    private func setEnabled(_ enabled: Bool) {
        guard !isSuspended else {
            overlay.hide()
            return
        }
        if !enabled {
            cancelPreview()
            keyboard.stop()
            resetRhythm()
            overlay.hide()
            setStatus(.paused)
            onStatusChange?()
            return
        }
        overlay.show()
        refreshCapture()
        onStatusChange?()
    }

    private func refreshCapture(forceRetry: Bool = false) {
        guard !isSuspended else { return }
        guard keyboard.start(forceRetry: forceRetry) else {
            setStatus(keyboard.hasPermission ? .unavailable : .permissionRequired)
            return
        }
        setStatus(IsSecureEventInputEnabled() ? .secureInput : .listening)
    }

    private func maintain() {
        guard !isSuspended, !isPreviewing else { return }
        if settings.isEnabled { refreshCapture() }
        if analyzer.expire(at: ProcessInfo.processInfo.systemUptime) {
            overlay.update(snapshot: .empty)
        }
    }

    private func setStatus(_ newStatus: CaptureStatus) {
        guard !isPreviewing || newStatus == .preview else { return }
        guard status != newStatus else { return }
        status = newStatus
        overlay.setStatus(newStatus)
        onStatusChange?()
    }

    private func repositionOverlay() {
        repositionOverlay(preferredID: settings.preferredDisplayID)
    }

    private func repositionOverlay(preferredID: String?) {
        if let screen = displays.screen(preferredID: preferredID) { overlay.position(on: screen) }
    }

    @objc private func suspend() {
        isSuspended = true
        stopPreview()
        keyboard.stop()
        resetRhythm()
        overlay.hide()
    }

    @objc private func resume() {
        isSuspended = false
        repositionOverlay()
        setEnabled(settings.isEnabled)
    }
}
