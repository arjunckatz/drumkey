import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults
    private var overlayPositions: [String: OverlayPosition]

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: "isEnabled") }
    }

    @Published var visibility: Double {
        didSet { defaults.set(visibility, forKey: "visibility") }
    }

    @Published var eqTransparency: Double {
        didSet { defaults.set(eqTransparency, forKey: "eqTransparency") }
    }

    @Published var overlayScale: OverlayScale {
        didSet { defaults.set(overlayScale.rawValue, forKey: "overlayScale") }
    }

    @Published var visualizerTheme: VisualizerTheme {
        didSet { defaults.set(visualizerTheme.rawValue, forKey: "visualizerTheme") }
    }

    @Published var colorScheme: VisualizerColorScheme {
        didSet { defaults.set(colorScheme.rawValue, forKey: "colorScheme") }
    }

    @Published private(set) var preferredDisplayID: String?
    @Published private(set) var preferredDisplayName: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        overlayPositions = defaults.data(forKey: "overlayPositions")
            .flatMap { try? JSONDecoder().decode([String: OverlayPosition].self, from: $0) } ?? [:]
        isEnabled = defaults.object(forKey: "isEnabled") as? Bool ?? true
        let savedVisibility = defaults.object(forKey: "visibility") as? Double ?? 0.78
        visibility = min(1, max(0.40, savedVisibility.isFinite ? savedVisibility : 0.78))
        let savedEQTransparency = defaults.object(forKey: "eqTransparency") as? Double ?? 0.92
        eqTransparency = min(1, max(0, savedEQTransparency.isFinite ? savedEQTransparency : 0.92))
        overlayScale = OverlayScale(rawValue: defaults.double(forKey: "overlayScale")) ?? .one
        visualizerTheme = VisualizerTheme(rawValue: defaults.string(forKey: "visualizerTheme") ?? "") ?? .glassCircle
        colorScheme = VisualizerColorScheme(rawValue: defaults.string(forKey: "colorScheme") ?? "") ?? .classic
        preferredDisplayID = defaults.string(forKey: "preferredDisplayID")
        preferredDisplayName = defaults.string(forKey: "preferredDisplayName")
    }

    func selectDisplay(_ display: DisplayInfo?) {
        preferredDisplayName = display?.name
        preferredDisplayID = display?.id
        defaults.set(display?.id, forKey: "preferredDisplayID")
        defaults.set(display?.name, forKey: "preferredDisplayName")
    }

    func overlayPosition(for displayID: String) -> OverlayPosition? {
        overlayPositions[displayID]
    }

    func saveOverlayPosition(_ position: OverlayPosition, for displayID: String) {
        overlayPositions[displayID] = position
        if let data = try? JSONEncoder().encode(overlayPositions) {
            defaults.set(data, forKey: "overlayPositions")
        }
    }
}
