import AppKit
import DrumKeyCore

@MainActor
final class OverlayController {
    private static let overlaySize = OverlayView.preferredSize
    private static let screenMargin: CGFloat = 16

    private let panel: OverlayPanel
    private let overlayView: OverlayView
    private let settings: AppSettings
    private var currentDisplayID: String?
    var onDisplayChangedByDrag: ((String) -> Void)?

    init(settings: AppSettings) {
        self.settings = settings
        let contentRect = NSRect(origin: .zero, size: Self.overlaySize)
        overlayView = OverlayView(frame: contentRect)
        panel = OverlayPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = Self.makeGlassContainer(contentView: overlayView)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isExcludedFromWindowsMenu = true
        panel.isMovable = true
        panel.animationBehavior = .none
        panel.level = .statusBar
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        overlayView.onDragEnd = { [weak self] in self?.saveDraggedPosition() }
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        overlayView.clearPulses()
        panel.orderOut(nil)
    }

    func register(hit: DrumHit, snapshot: RhythmSnapshot) {
        overlayView.register(hit: hit, snapshot: snapshot)
    }

    func update(snapshot: RhythmSnapshot) {
        overlayView.update(snapshot: snapshot)
    }

    func setStatus(_ status: CaptureStatus) {
        overlayView.setStatus(status)
    }

    func setVisibility(_ value: Double) {
        panel.alphaValue = min(1, max(0.40, value))
    }

    func setEQTransparency(_ value: Double) {
        overlayView.setEQTransparency(value)
    }

    func position(on screen: NSScreen) {
        let displayID = DisplayManager.identifier(screen)
        currentDisplayID = displayID
        let visibleFrame = screen.visibleFrame
        if let position = settings.overlayPosition(for: displayID) {
            panel.setFrameOrigin(position.origin(windowSize: panel.frame.size, visibleFrame: visibleFrame))
            return
        }
        let origin = NSPoint(
            x: visibleFrame.minX + Self.screenMargin,
            y: visibleFrame.maxY - panel.frame.height - Self.screenMargin
        )
        panel.setFrameOrigin(origin)
    }

    private func saveDraggedPosition() {
        guard let screen = panel.screen else { return }
        let displayID = DisplayManager.identifier(screen)
        let position = OverlayPosition(
            origin: panel.frame.origin, windowSize: panel.frame.size, visibleFrame: screen.visibleFrame
        )
        settings.saveOverlayPosition(position, for: displayID)
        panel.setFrameOrigin(position.origin(windowSize: panel.frame.size, visibleFrame: screen.visibleFrame))
        if displayID != currentDisplayID {
            currentDisplayID = displayID
            onDisplayChangedByDrag?(displayID)
        }
    }

    private static func makeGlassContainer(contentView: NSView) -> NSView {
        if #available(macOS 26.0, *) {
            let glassView = NSGlassEffectView(frame: contentView.bounds)
            glassView.contentView = contentView
            glassView.cornerRadius = 24
            glassView.style = .regular
            return glassView
        }

        let effectView = NSVisualEffectView(frame: contentView.bounds)
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 24
        effectView.layer?.masksToBounds = true
        contentView.autoresizingMask = [.width, .height]
        effectView.addSubview(contentView)
        return effectView
    }
}

private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
