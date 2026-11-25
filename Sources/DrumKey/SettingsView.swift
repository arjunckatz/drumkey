import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var session: DrumKeySession
    @ObservedObject var displays: DisplayManager
    let shortcutAvailable: Bool

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $settings.isEnabled) {
                    HStack {
                        Text("Enable DrumKey")
                        Spacer()
                        if shortcutAvailable {
                            Text("⌃⌥⌘D").foregroundStyle(.secondary).font(.caption)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 7) {
                    Label(session.status.rawValue, systemImage: session.status.symbol)
                        .font(.headline)
                        .foregroundStyle(statusColor)
                    Text(session.status.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if settings.isEnabled {
                        Button("Retry keyboard listener", action: session.retryCapture)
                    }
                    if session.status == .permissionRequired || session.status == .unavailable {
                        HStack {
                            Button("Allow Input Monitoring", action: session.requestPermission)
                            Button("Open System Settings", action: session.openPrivacySettings)
                        }
                        .padding(.top, 3)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Picker("Visual theme", selection: $settings.visualizerTheme) {
                    ForEach(VisualizerTheme.allCases, id: \.self) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
                Picker("Color scheme", selection: $settings.colorScheme) {
                    ForEach(VisualizerColorScheme.allCases, id: \.self) { scheme in
                        Text(scheme.label).tag(scheme)
                    }
                }
                Picker("Display", selection: displaySelection) {
                    Text("Automatic · prefer secondary").tag("")
                    ForEach(displays.displays) { display in
                        Text(display.title).tag(display.id)
                    }
                    if let id = settings.preferredDisplayID, isPreferredDisplayMissing {
                        Text("\(settings.preferredDisplayName ?? "Saved display") · Disconnected").tag(id)
                    }
                }
                if let active = displays.activeDisplay(preferredID: settings.preferredDisplayID) {
                    Text(displayDetail(active))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Picker("Overlay size", selection: $settings.overlayScale) {
                    ForEach(OverlayScale.allCases, id: \.self) { scale in
                        Text(scale.label).tag(scale)
                    }
                }
                LabeledContent("Visibility") {
                    Slider(value: $settings.visibility, in: 0.40...1, step: 0.05)
                        .frame(width: 165)
                        .accessibilityLabel("Overlay visibility")
                    Text(settings.visibility, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .trailing)
                }
                LabeledContent("EQ transparency") {
                    Slider(value: $settings.eqTransparency, in: 0...1, step: 0.01)
                        .frame(width: 165)
                        .accessibilityLabel("Background EQ transparency")
                        .accessibilityIdentifier("eqTransparency")
                    Text(settings.eqTransparency, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .trailing)
                }
                Button(session.isPreviewing ? "Stop preview" : "Preview a rhythm", action: session.togglePreview)
                    .accessibilityIdentifier("previewRhythm")
            } header: {
                Text("Overlay")
            } footer: {
                Text("Themes and colors change live and are remembered. Size enlarges the visualizer while BPM and meter text stay the same size. Drag the panel to move it. Higher EQ transparency makes the background fainter.")
            }

            Section {
                LabeledContent("Bass", value: "D · F")
                LabeledContent("Border flash", value: "D + F together")
                LabeledContent("Percussion", value: "J · K")
                LabeledContent("Border meters", value: "J left · K right")
                LabeledContent("Downbeat / accent", value: "Space")
                LabeledContent("Manual accent", value: "L")
            } header: {
                Text("Keys")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if settings.visualizerTheme.usesRadialKeyMap {
                        Text("Radial keys respond on both sides: D/F lift the upper bass ears, J the sidewalls, K the lower shoulders and L the fine lower peaks.")
                    }
                    Text("J/K border meters build toward 60% height through 30 seconds of frequent tapping. L is a manual visual accent. Keys keep their ordinary actions; hold Command, Control or Option to use shortcuts without adding a hit.")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 610)
    }

    private var statusColor: Color {
        switch session.status {
        case .listening, .preview: .primary
        case .paused: .secondary
        case .permissionRequired, .unavailable, .secureInput: .orange
        }
    }

    private var displaySelection: Binding<String> {
        Binding(
            get: { settings.preferredDisplayID ?? "" },
            set: { id in settings.selectDisplay(displays.displays.first { $0.id == id }) }
        )
    }

    private var isPreferredDisplayMissing: Bool {
        guard let id = settings.preferredDisplayID else { return false }
        return !displays.displays.contains { $0.id == id }
    }

    private func displayDetail(_ active: DisplayInfo) -> String {
        if isPreferredDisplayMissing {
            return "Using \(active.name) until \(settings.preferredDisplayName ?? "your display") reconnects."
        }
        return "Showing on \(active.name)."
    }
}
