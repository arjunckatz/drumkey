import AppKit
import ColorSync
import Combine
import DrumKeyCore

struct DisplayInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let isPrimary: Bool

    var title: String { isPrimary ? "\(name) · Main" : name }
}

@MainActor
final class DisplayManager: NSObject, ObservableObject {
    @Published private(set) var displays: [DisplayInfo] = []
    var onChange: (() -> Void)?

    override init() {
        super.init()
        refresh()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func screen(preferredID: String?) -> NSScreen? {
        let screens = NSScreen.screens
        let availableIDs = screens.map(Self.identifier)
        guard let selectedID = DisplaySelection.resolve(
            availableIDs: availableIDs, preferredID: preferredID
        ) else { return nil }
        return screens.first { Self.identifier($0) == selectedID }
    }

    func activeDisplay(preferredID: String?) -> DisplayInfo? {
        let id = DisplaySelection.resolve(availableIDs: displays.map(\.id), preferredID: preferredID)
        return displays.first { $0.id == id }
    }

    @objc private func refresh() {
        displays = NSScreen.screens.enumerated().map { index, screen in
            DisplayInfo(id: Self.identifier(screen), name: screen.localizedName, isPrimary: index == 0)
        }
        onChange?()
    }

    static func identifier(_ screen: NSScreen) -> String {
        let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        let displayID = number?.uint32Value ?? 0
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return "display-\(displayID)"
        }
        return CFUUIDCreateString(nil, uuid) as String
    }
}
