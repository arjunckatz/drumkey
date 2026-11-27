import AppKit
import DrumKeyCore

@MainActor
final class OverlayView: NSView {
    static let preferredSize = OverlayScale.baseSize
    var onDragEnd: (() -> Void)?

    private var snapshot: RhythmSnapshot = .empty
    private var status: CaptureStatus = .permissionRequired
    private var dynamics = KeyVisualDynamics()
    private var visualizerTheme: VisualizerTheme = .glassCircle
    private var palette = VisualizerColorScheme.classic.palette
    private var bassChordFlash = BassChordFlash()
    private var percussionBorderEQ = PercussionBorderEQ()
    private var backgroundEQ = BackgroundEQ()
    private var eqOpacity = 0.08
    private var eqGradient: NSGradient? { palette.spectrum }
    private var animationTimer: Timer?
    private var borderTint: NSColor { palette.border }
    private let meterLabel = NSTextField(labelWithString: "≈4/4")
    private let tempoLabel = NSTextField(labelWithString: "Allow input")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        meterLabel.font = .monospacedSystemFont(ofSize: 22, weight: .medium)
        meterLabel.textColor = .labelColor
        meterLabel.alignment = .center
        meterLabel.frame = NSRect(x: 12, y: 13, width: 168, height: 29)
        tempoLabel.font = .systemFont(ofSize: 11, weight: .medium)
        tempoLabel.textColor = .secondaryLabelColor
        tempoLabel.alignment = .center
        tempoLabel.frame = NSRect(x: 12, y: 45, width: 168, height: 17)
        addSubview(meterLabel)
        addSubview(tempoLabel)
        meterLabel.setAccessibilityElement(false)
        tempoLabel.setAccessibilityElement(false)
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        updateAccessibility()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override var isFlipped: Bool { true }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        meterLabel.frame = NSRect(x: 12, y: 13, width: max(0, newSize.width - 24), height: 29)
        tempoLabel.frame = NSRect(x: 12, y: 45, width: max(0, newSize.width - 24), height: 17)
        needsDisplay = true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard super.hitTest(point) != nil else { return nil }
        return self
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        NSCursor.closedHand.push()
        defer { NSCursor.pop() }
        window.performDrag(with: event)
        onDragEnd?()
    }

    private var stage: SoundstageLayout { SoundstageLayout(bounds: bounds) }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawBackgroundEQ()
        drawSoundstage()
        drawPercussionBorderEQ()
        drawBassChordBorder()
    }

    func register(hit: DrumHit, snapshot: RhythmSnapshot) {
        self.snapshot = snapshot
        let now = ProcessInfo.processInfo.systemUptime
        for visualHit in VisualHitRouter.hits(for: hit) {
            dynamics.register(key: visualHit.key, at: now)
            bassChordFlash.register(visualHit, deliveredAt: now)
            percussionBorderEQ.register(visualHit, deliveredAt: now)
            backgroundEQ.register(key: visualHit.key, at: now)
        }
        updateStatusLabels()
        updateAccessibility()
        needsDisplay = true
        startAnimationTimer()
    }

    func setEQTransparency(_ value: Double) {
        let transparency = value.isFinite ? min(1, max(0, value)) : 0.92
        eqOpacity = 1 - transparency
        needsDisplay = true
        if eqOpacity > 0, backgroundEQ.isAnimating(at: ProcessInfo.processInfo.systemUptime) {
            startAnimationTimer()
        }
    }

    func setTheme(_ value: VisualizerTheme) {
        visualizerTheme = value
        needsDisplay = true
    }

    func setColorScheme(_ value: VisualizerColorScheme) {
        palette = value.palette
        needsDisplay = true
    }

    func update(snapshot: RhythmSnapshot) {
        self.snapshot = snapshot
        if snapshot.hitCount == 0 { clearPulses() }
        updateStatusLabels()
        updateAccessibility()
        needsDisplay = true
    }

    func setStatus(_ status: CaptureStatus) {
        self.status = status
        if status != .listening, status != .preview { clearPulses() }
        updateStatusLabels()
        updateAccessibility()
        needsDisplay = true
    }

    func clearPulses() {
        animationTimer?.invalidate()
        animationTimer = nil
        dynamics.reset()
        bassChordFlash.reset()
        percussionBorderEQ.reset()
        backgroundEQ.reset()
        needsDisplay = true
    }

    private func startAnimationTimer() {
        guard animationTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.advancePulses() }
        }
        animationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func advancePulses() {
        let now = ProcessInfo.processInfo.systemUptime
        needsDisplay = true
        let eqIsAnimating = eqOpacity > 0 && backgroundEQ.isAnimating(at: now)
        if !dynamics.isAnimating(at: now), bassChordFlash.intensity(at: now) == 0,
           !percussionBorderEQ.isAnimating(at: now), !eqIsAnimating {
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }

    private func drawBackgroundEQ() {
        guard eqOpacity > 0 else { return }
        let levels = backgroundEQ.levels(at: ProcessInfo.processInfo.systemUptime)
        let area = bounds.insetBy(dx: 4, dy: 4)
        let spacing = area.width / CGFloat(levels.count)
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let stems = NSBezierPath()

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 23, yRadius: 23).addClip()
        for (index, level) in levels.enumerated() {
            let visibleLevel = reduceMotion ? 0.32 + Double(index % 7) * 0.035 : level
            let height = area.height * visibleLevel
            let stem = NSBezierPath(roundedRect: NSRect(
                x: area.minX + (CGFloat(index) + 0.5) * spacing - 0.55,
                y: area.maxY - height, width: 1.1, height: height
            ), xRadius: 0.55, yRadius: 0.55)
            if reduceMotion {
                drawEQGradient(in: stem, area: area, opacity: eqOpacity * (0.15 + level * 0.85))
            } else {
                stems.append(stem)
            }
        }
        if !reduceMotion { drawEQGradient(in: stems, area: area, opacity: eqOpacity) }
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawEQGradient(in path: NSBezierPath, area: NSRect, opacity: Double) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.cgContext.setAlpha(opacity)
        path.addClip()
        // Anchor the colors to the entire HUD, so red appears only when a band
        // actually reaches the top rather than at the tip of every short stem.
        eqGradient?.draw(
            from: NSPoint(x: area.midX, y: area.maxY),
            to: NSPoint(x: area.midX, y: area.minY),
            options: [.drawsBeforeStartingLocation, .drawsAfterEndingLocation]
        )
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawBassChordBorder() {
        var intensity = bassChordFlash.intensity(at: ProcessInfo.processInfo.systemUptime)
        guard intensity > 0 else { return }
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { intensity *= 0.45 }

        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), xRadius: 20, yRadius: 20)
        borderTint.withAlphaComponent(0.16 * intensity).setStroke()
        border.lineWidth = 7
        border.stroke()
        borderTint.withAlphaComponent(0.95 * intensity).setStroke()
        border.lineWidth = 2.2
        border.stroke()

        let highlight = NSBezierPath(roundedRect: bounds.insetBy(dx: 5.5, dy: 5.5), xRadius: 18.5, yRadius: 18.5)
        NSColor.white.withAlphaComponent(0.22 * intensity).setStroke()
        highlight.lineWidth = 0.8
        highlight.stroke()
    }

    private func drawPercussionBorderEQ() {
        let now = ProcessInfo.processInfo.systemUptime
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 23, yRadius: 23).addClip()
        for (key, x): (DrumKey, CGFloat) in [(.j, bounds.minX + 4), (.k, bounds.maxX - 4)] {
            let level = percussionBorderEQ.level(for: key, at: now)
            guard level > 0 else { continue }
            let height = bounds.height * (reduceMotion ? 0.08 : level)
            let opacity = reduceMotion ? level / 0.60 * 0.65 : 1
            let bottom = bounds.maxY - 24
            let top = bottom - height
            let glow = NSBezierPath()
            glow.move(to: NSPoint(x: x, y: bottom))
            glow.line(to: NSPoint(x: x, y: top))
            borderTint.withAlphaComponent(0.12 * opacity).setStroke()
            glow.lineWidth = 7
            glow.stroke()
            borderTint.withAlphaComponent(0.95 * opacity).setFill()
            var y = bottom
            while y > top {
                let segmentHeight = min(3, y - top)
                NSBezierPath(roundedRect: NSRect(
                    x: x - 1.6, y: y - segmentHeight, width: 3.2, height: segmentHeight
                ), xRadius: 0.8, yRadius: 0.8).fill()
                y -= 5
            }
        }
        NSGraphicsContext.restoreGraphicsState()
    }

    private func updateStatusLabels() {
        let meter = snapshot.meter ?? .initial
        meterLabel.stringValue = meter.confidence < 0.8 ? "≈\(meter.signature)" : meter.signature
        switch status {
        case .permissionRequired: tempoLabel.stringValue = "Allow input"
        case .unavailable: tempoLabel.stringValue = "Retry input"
        case .secureInput: tempoLabel.stringValue = "Secure input"
        case .paused: tempoLabel.stringValue = "Paused"
        case .listening, .preview:
            tempoLabel.stringValue = snapshot.bpm.map {
                let prefix = snapshot.tempoConfidence < 0.70 ? "≈" : ""
                return "\(prefix)\(Int($0.rounded())) BPM"
            }
                ?? (snapshot.hitCount == 0 ? status.rawValue : "Finding pulse")
        }
    }

    private func drawSoundstage() {
        let center = stage.center
        if visualizerTheme != .glassCircle {
            ThemeRenderer(layout: stage, levels: dynamics.levels(at: ProcessInfo.processInfo.systemUptime),
                          palette: palette, reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
                .draw(visualizerTheme)
            if visualizerTheme.isCircular {
                let markerCenter = visualizerTheme == .circleTowers
                    ? NSPoint(x: center.x, y: center.y + 17 * stage.scale) : center
                drawBeatMarkers(around: markerCenter, radius: visualizerTheme == .razorBloom ? 20 : 31)
            }
            return
        }

        // Thin nested rims leave the middle open and give the glass columns a
        // shared circular stage. A Space accent lights the complete outer rim.
        for radius: CGFloat in [37, 54, 64] {
            let ringRect = stage.ringRect(radius: radius)
            let ring = NSBezierPath(ovalIn: ringRect)
            NSColor.labelColor.withAlphaComponent(0.07).setStroke()
            ring.lineWidth = 0.7 * stage.scale
            ring.stroke()
            NSColor.white.withAlphaComponent(0.30).setStroke()
            let highlight = NSBezierPath(ovalIn: ringRect)
            highlight.lineWidth = 0.5 * stage.scale
            highlight.stroke()
        }

        let accent = visualEnergy(for: .space)
        if accent > 0 {
            color(for: .space).withAlphaComponent(0.65 * accent).setStroke()
            let rim = NSBezierPath(ovalIn: stage.ringRect(radius: 64))
            rim.lineWidth = 1.8 * stage.scale
            rim.stroke()
        }

        drawBeatMarkers(around: center)

        for artifact in stage.artifacts.sorted(by: { $0.baseRect.maxY < $1.baseRect.maxY }) {
            drawGlassArtifact(artifact)
        }
    }

    private func drawBeatMarkers(around center: NSPoint, radius: CGFloat = 37) {
        let beats = snapshot.meter?.beatsPerBar ?? 4
        for index in 0..<beats {
            let angle = -Double.pi / 2 + Double(index) * 2 * Double.pi / Double(beats)
            let point = NSPoint(x: center.x + cos(angle) * radius * stage.scale, y: center.y + sin(angle) * radius * stage.scale)
            let isCurrent = snapshot.beatInBar == index + 1
            let diameter: CGFloat = (isCurrent ? 4 : 2.5) * stage.scale
            NSColor.labelColor.withAlphaComponent(isCurrent ? 0.65 : 0.18).setFill()
            NSBezierPath(ovalIn: NSRect(
                x: point.x - diameter / 2, y: point.y - diameter / 2,
                width: diameter, height: diameter
            )).fill()
        }
    }

    private func drawGlassArtifact(_ artifact: GlassArtifact) {
        let key = artifact.key
        let scale = artifact.scale
        let isBass = artifact.isBass
        let intensity = visualEnergy(for: key)
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let rect = artifact.frontRect(intensity: intensity, reduceMotion: reduceMotion)
        let depth = artifact.depth
        let tint = color(for: key)
        let front = NSBezierPath(roundedRect: rect, xRadius: 2.5 * scale, yRadius: 2.5 * scale)
        let top = polygon([
            NSPoint(x: rect.minX, y: rect.minY),
            NSPoint(x: rect.minX + depth.x, y: rect.minY + depth.y),
            NSPoint(x: rect.maxX + depth.x, y: rect.minY + depth.y),
            NSPoint(x: rect.maxX, y: rect.minY)
        ])
        let side = polygon([
            NSPoint(x: rect.minX, y: rect.minY),
            NSPoint(x: rect.minX + depth.x, y: rect.minY + depth.y),
            NSPoint(x: rect.minX + depth.x, y: rect.maxY + depth.y),
            NSPoint(x: rect.minX, y: rect.maxY)
        ])

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.13 + intensity * 0.06)
        shadow.shadowBlurRadius = 2 * scale
        shadow.shadowOffset = NSSize(width: -scale, height: -2 * scale)
        shadow.set()
        tint.withAlphaComponent(0.12 + intensity * 0.10).setFill()
        front.fill()
        NSGraphicsContext.restoreGraphicsState()

        let paleTint = tint.blended(withFraction: 0.55, of: .white) ?? tint
        let bassEmphasis = isBass ? 0.04 + intensity * 0.08 : 0
        NSGradient(
            starting: paleTint.withAlphaComponent(0.45 + intensity * 0.30 + bassEmphasis),
            ending: tint.withAlphaComponent(0.22 + intensity * 0.32 + bassEmphasis)
        )?.draw(in: front, angle: 90)
        NSGradient(
            starting: tint.withAlphaComponent(0.24 + intensity * 0.25),
            ending: tint.withAlphaComponent(0.10 + intensity * 0.18)
        )?.draw(in: side, angle: 180)
        NSGradient(
            starting: NSColor.white.withAlphaComponent(0.65),
            ending: paleTint.withAlphaComponent(0.45 + intensity * 0.30)
        )?.draw(in: top, angle: 70)

        for face in [front, side, top] {
            NSColor.white.withAlphaComponent(0.45 + intensity * 0.20).setStroke()
            face.lineWidth = (isBass ? 1.05 : (key == .l ? 0.8 : 0.55)) * scale
            face.stroke()
        }

        let reflection = NSBezierPath()
        reflection.move(to: NSPoint(x: rect.maxX - 2 * scale, y: rect.minY + 3 * scale))
        reflection.line(to: NSPoint(x: rect.maxX - 2 * scale, y: rect.maxY - 3 * scale))
        NSColor.white.withAlphaComponent(0.34 + intensity * 0.25).setStroke()
        reflection.lineWidth = (isBass ? 1.3 : 0.8) * scale
        reflection.stroke()
    }

    private func polygon(_ points: [NSPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.line(to: point) }
        path.close()
        path.lineJoinStyle = .round
        return path
    }

    private func visualEnergy(for key: DrumKey) -> Double {
        dynamics.level(for: key, at: ProcessInfo.processInfo.systemUptime)
    }

    private func updateAccessibility() {
        let tempo = snapshot.bpm.map {
            let prefix = snapshot.tempoConfidence < 0.70 ? "Approximately " : ""
            return "\(prefix)\(Int($0.rounded())) beats per minute"
        } ?? "Finding tempo"
        let meter = snapshot.meter ?? .initial
        let qualification = meter.confidence < 0.8 ? "Tentative" : "Estimated"
        setAccessibilityLabel("DrumKey. \(status.rawValue). \(tempo). \(qualification) meter \(meter.signature).")
    }

    private func color(for key: DrumKey) -> NSColor {
        palette.color(for: key)
    }
}
