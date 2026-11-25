import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settings = AppSettings()
    private let displays = DisplayManager()
    private let shortcut = GlobalShortcut()
    private lazy var session = DrumKeySession(settings: settings, displays: displays)
    private var settingsController: SettingsWindowController?
    private var toggleMenuItem: NSMenuItem?
    private var statusMenuItem: NSMenuItem?
    private var previewMenuItem: NSMenuItem?
    private var shortcutAvailable = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let existing = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "local.drumkey.app")
            .first { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        if let existing {
            existing.activate(options: [.activateAllWindows])
            NSApp.terminate(nil)
            return
        }

        shortcut.onToggle = { [weak self] in self?.settings.isEnabled.toggle() }
        shortcutAvailable = shortcut.register()
        configureStatusItem()
        configureApplicationMenu()
        session.onStatusChange = { [weak self] in self?.updateMenu() }
        session.start()
        updateMenu()
        if !UserDefaults.standard.bool(forKey: "hasLaunched") || session.status == .permissionRequired {
            showSettings()
        }
        UserDefaults.standard.set(true, forKey: "hasLaunched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        session.stop()
        shortcut.unregister()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    private func configureApplicationMenu() {
        let menu = NSMenu()
        let appMenu = NSMenu()
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let toggleItem = NSMenuItem(title: "Toggle DrumKey", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        if shortcutAvailable {
            toggleItem.keyEquivalent = "d"
            toggleItem.keyEquivalentModifierMask = [.control, .option, .command]
        }
        appMenu.addItem(toggleItem)
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(withTitle: "Close Settings", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit DrumKey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = menu
    }

    private func configureStatusItem() {
        statusItem.button?.image = NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "DrumKey")
        statusItem.button?.image?.isTemplate = true
        statusItem.button?.toolTip = "DrumKey"

        let menu = NSMenu()
        let status = NSMenuItem(title: "DrumKey", action: nil, keyEquivalent: "")
        status.isEnabled = false
        statusMenuItem = status
        menu.addItem(status)
        menu.addItem(.separator())
        let toggleItem = NSMenuItem(
            title: "Enable DrumKey",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleMenuItem = toggleItem
        menu.addItem(toggleItem)

        if shortcutAvailable {
            toggleItem.keyEquivalent = "d"
            toggleItem.keyEquivalentModifierMask = [.control, .option, .command]
        }

        let resetItem = NSMenuItem(
            title: "Reset rhythm",
            action: #selector(resetRhythm),
            keyEquivalent: ""
        )
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(.separator())

        let preview = NSMenuItem(title: "Preview a rhythm", action: #selector(togglePreview), keyEquivalent: "")
        preview.target = self
        previewMenuItem = preview
        menu.addItem(preview)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let permissionItem = NSMenuItem(
            title: "Input Monitoring…",
            action: #selector(showInputMonitoring),
            keyEquivalent: ""
        )
        permissionItem.target = self
        menu.addItem(permissionItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit DrumKey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        settings.isEnabled.toggle()
    }

    @objc private func resetRhythm() {
        session.resetRhythm()
    }

    @objc private func togglePreview() {
        session.togglePreview()
        updateMenu()
    }

    @objc private func showSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(
                settings: settings, session: session, displays: displays,
                shortcutAvailable: shortcutAvailable
            )
        }
        settingsController?.present()
    }

    @objc private func showInputMonitoring() {
        showSettings()
        session.requestPermission()
    }

    private func updateMenu() {
        toggleMenuItem?.state = settings.isEnabled ? .on : .off
        statusMenuItem?.title = "DrumKey · \(session.status.rawValue)"
        previewMenuItem?.title = session.isPreviewing ? "Stop preview" : "Preview a rhythm"
        statusItem.button?.appearsDisabled = !settings.isEnabled && !session.isPreviewing
        statusItem.button?.toolTip = "DrumKey · \(session.status.rawValue)"
    }
}
