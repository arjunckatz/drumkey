import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(settings: AppSettings, session: DrumKeySession, displays: DisplayManager, shortcutAvailable: Bool) {
        let rootView = SettingsView(
            settings: settings, session: session, displays: displays,
            shortcutAvailable: shortcutAvailable
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 610),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false
        )
        window.title = "DrumKey Settings"
        window.contentViewController = NSHostingController(rootView: rootView)
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func present() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
